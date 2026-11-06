import Foundation

/// Keeps the telemetry state in a file, so what a run or wake-up counted can be sent after iOS ends the app.
struct CameraUploadTelemetryStateStore {
    private let fileURL = CameraUploadTelemetryFileSink.defaultDirectoryURL
        .appendingPathComponent("state.json", isDirectory: false)

    func load() -> CameraUploadTelemetryState? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        do {
            return try JSONDecoder().decode(CameraUploadTelemetryState.self, from: data)
        } catch {
            MEGALogError("[Camera Upload Telemetry] failed to read saved state: \(error)")
            return nil
        }
    }

    /// Removes the file when the state is empty.
    func save(_ state: CameraUploadTelemetryState) {
        do {
            if state.isEmpty {
                try? FileManager.default.removeItem(at: fileURL)
                return
            }
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try JSONEncoder().encode(state).write(to: fileURL, options: .atomic)
        } catch {
            MEGALogError("[Camera Upload Telemetry] failed to save state: \(error)")
        }
    }
}
