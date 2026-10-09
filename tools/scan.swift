import Foundation
import RealityKit

// usage: scan <images_dir> <output.usdz> <detail: preview|reduced|medium|full>
let args = CommandLine.arguments
let input = URL(fileURLWithPath: args[1], isDirectory: true)
let output = URL(fileURLWithPath: args[2])
let detail: PhotogrammetrySession.Request.Detail = {
    switch args.count > 3 ? args[3] : "medium" {
    case "preview": return .preview
    case "reduced": return .reduced
    case "full": return .full
    default: return .medium
    }
}()

guard PhotogrammetrySession.isSupported else { print("ERROR: Object Capture not supported on this Mac"); exit(1) }

var config = PhotogrammetrySession.Configuration()
config.isObjectMaskingEnabled = true     // ignore the static background
config.sampleOrdering = .sequential      // frames come from a continuous video
config.featureSensitivity = .high

let session: PhotogrammetrySession
do { session = try PhotogrammetrySession(input: input, configuration: config) }
catch { print("ERROR creating session: \(error)"); exit(1) }

let done = DispatchSemaphore(value: 0)
Task {
    do {
        for try await out in session.outputs {
            switch out {
            case .requestProgress(_, let f): print(String(format: "progress %.0f%%", f*100)); fflush(stdout)
            case .requestComplete(_, let r): print("complete: \(r)")
            case .requestError(_, let e): print("ERROR request: \(e)")
            case .invalidSample(let id, let reason): print("invalid sample \(id): \(reason)")
            case .skippedSample(let id): print("skipped sample \(id)")
            case .processingComplete: print("processing complete"); done.signal()
            case .processingCancelled: print("cancelled"); done.signal()
            default: break
            }
            fflush(stdout)
        }
    } catch { print("ERROR outputs: \(error)"); done.signal() }
}
do { try session.process(requests: [.modelFile(url: output, detail: detail)]) }
catch { print("ERROR process: \(error)"); exit(1) }
done.wait()
