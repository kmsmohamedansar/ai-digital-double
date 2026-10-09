import Foundation
import RealityKit
import ImageIO

// usage: poses <images_dir> <transforms.json>
// Writes a nerfstudio-style transforms.json (OpenGL camera convention, camera-to-world).
let args = CommandLine.arguments
let input = URL(fileURLWithPath: args[1], isDirectory: true)
let output = URL(fileURLWithPath: args[2])

func intrinsics(_ url: URL) -> (w: Int, h: Int, fpx: Double)? {
    guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
          let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any] else { return nil }
    var w = props[kCGImagePropertyPixelWidth] as? Int ?? 0
    var h = props[kCGImagePropertyPixelHeight] as? Int ?? 0
    let orient = props[kCGImagePropertyOrientation] as? Int ?? 1
    if orient >= 5 { swap(&w, &h) }
    let exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any] ?? [:]
    let f35 = exif[kCGImagePropertyExifFocalLenIn35mmFilm] as? Double ?? 26
    // 35mm-equivalent focal length is defined against the 43.27mm diagonal
    let diag = (Double(w*w + h*h)).squareRoot()
    return (w, h, f35 / 43.27 * diag)
}

var config = PhotogrammetrySession.Configuration()
config.isObjectMaskingEnabled = (ProcessInfo.processInfo.environment["MASK"] == "1")
config.featureSensitivity = .high
let session = try PhotogrammetrySession(input: input, configuration: config)
let done = DispatchSemaphore(value: 0)
Task {
    for try await out in session.outputs {
        switch out {
        case .requestComplete(_, .poses(let poses)):
            var frames: [[String: Any]] = []
            for (id, pose) in poses.posesBySample.sorted(by: { $0.key < $1.key }) {
                guard let url = poses.urlsBySample[id], let k = intrinsics(url) else { continue }
                let m = simd_float4x4(pose.rotation)
                var t = m; t.columns.3 = SIMD4<Float>(pose.translation, 1)
                let rows = (0..<4).map { r in (0..<4).map { c in Double(t[c][r]) } }
                frames.append(["file_path": url.path, "transform_matrix": rows,
                               "w": k.w, "h": k.h, "fl_x": k.fpx, "fl_y": k.fpx,
                               "cx": Double(k.w)/2, "cy": Double(k.h)/2])
            }
            let json: [String: Any] = ["camera_model": "OPENCV", "frames": frames]
            let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
            try data.write(to: output)
            print("poses written: \(frames.count)")
        case .requestError(_, let e): print("ERROR: \(e)")
        case .skippedSample(let id): print("skipped \(id)")
        case .invalidSample(let id, let r): print("invalid \(id): \(r)")
        case .processingComplete: done.signal()
        default: break
        }
    }
}
try session.process(requests: [.poses])
done.wait()
