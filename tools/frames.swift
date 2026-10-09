import AVFoundation
import AppKit

// usage: frames <video> <outdir> <interval_seconds>
let args = CommandLine.arguments
let url = URL(fileURLWithPath: args[1])
let outDir = URL(fileURLWithPath: args[2])
let interval = Double(args[3]) ?? 0.5
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

let asset = AVURLAsset(url: url)
let sem = DispatchSemaphore(value: 0)
Task {
    let duration = try await asset.load(.duration).seconds
    let track = try await asset.loadTracks(withMediaType: .video).first!
    let size = try await track.load(.naturalSize)
    let fps = try await track.load(.nominalFrameRate)
    let xf = try await track.load(.preferredTransform)
    let oriented = size.applying(xf)
    print("duration=\(duration) size=\(Int(abs(oriented.width)))x\(Int(abs(oriented.height))) fps=\(fps)")

    let gen = AVAssetImageGenerator(asset: asset)
    gen.appliesPreferredTrackTransform = true
    gen.requestedTimeToleranceBefore = .zero
    gen.requestedTimeToleranceAfter = .zero
    var t = 0.0, i = 0
    while t < duration {
        let time = CMTime(seconds: t, preferredTimescale: 600)
        if let (cg, _) = try? await gen.image(at: time) {
            let rep = NSBitmapImageRep(cgImage: cg)
            if let data = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.92]) {
                let name = String(format: "frame_%04d_t%06.2f.jpg", i, t)
                try? data.write(to: outDir.appendingPathComponent(name))
            }
        }
        i += 1; t += interval
    }
    print("frames=\(i)")
    sem.signal()
}
sem.wait()
