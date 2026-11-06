import Foundation

/// Writes Camera Upload telemetry to a JSON Lines file in the app sandbox, one record per line, so the events can be
/// checked before they go to Firebase. Each record notes where it breaks a Firebase limit.
final class CameraUploadTelemetryFileSink: CameraUploadTelemetrySink, @unchecked Sendable {
    static let shared = CameraUploadTelemetryFileSink()

    private struct Record: Encodable {
        let seq: Int
        let time: String
        let kind: String
        let name: String
        let params: CameraUploadTelemetryParameters?
        let value: String?
        let issues: [String]?
    }

    private static let maxFileSize = 5 * 1024 * 1024

    // Accessed only on `queue`. Continues from the last record in the file, so it keeps counting across launches.
    private var sequence: Int?
    private let queue = DispatchQueue(label: "nz.mega.cameraUpload.telemetry.fileSink", qos: .utility)
    private let fileURL: URL
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return encoder
    }()
    private let timeFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = .current
        return formatter
    }()

    init(directoryURL: URL = CameraUploadTelemetryFileSink.defaultDirectoryURL) {
        fileURL = directoryURL.appendingPathComponent("cu-telemetry.jsonl", isDirectory: false)
    }

    static var defaultDirectoryURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CameraUploadTelemetry", isDirectory: true)
    }

    // MARK: - CameraUploadTelemetrySink

    func logEvent(_ name: String, parameters: CameraUploadTelemetryParameters) {
        let issues = CameraUploadTelemetryLimits.issues(forEvent: name, parameters: parameters)
        append(kind: "event", name: name, params: parameters, value: nil, issues: issues)
    }

    func setUserProperty(_ value: String?, forName name: String) {
        let issues = CameraUploadTelemetryLimits.issues(forUserProperty: name, value: value)
        append(kind: "user_property", name: name, params: nil, value: value ?? "<cleared>", issues: issues)
    }

    func waitUntilWritten() {
        queue.sync { }
    }

    // MARK: - Export

    /// Copies the file to a temporary file with a timestamped name, so exports do not overwrite each other on the
    /// receiving side. Returns nil when nothing has been recorded.
    func makeExportFile() -> URL? {
        queue.sync { () -> URL? in
            guard let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize, size > 0 else {
                return nil
            }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd-HHmmss"
            let exportURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("cu-telemetry-\(formatter.string(from: Date())).jsonl", isDirectory: false)
            try? FileManager.default.removeItem(at: exportURL)
            do {
                try FileManager.default.copyItem(at: fileURL, to: exportURL)
                return exportURL
            } catch {
                MEGALogError("[Camera Upload Telemetry] failed to copy file for export: \(error)")
                return nil
            }
        }
    }

    func clear() {
        queue.async { [self] in
            try? FileManager.default.removeItem(at: fileURL)
            sequence = 0
        }
    }

    // MARK: - Private

    private func append(
        kind: String,
        name: String,
        params: CameraUploadTelemetryParameters?,
        value: String?,
        issues: [String]
    ) {
        let date = Date()
        queue.async { [self] in
            let seq = (sequence ?? lastSequenceInFile()) + 1
            sequence = seq
            let record = Record(
                seq: seq,
                time: timeFormatter.string(from: date),
                kind: kind,
                name: name,
                params: params,
                value: value,
                issues: issues.isEmpty ? nil : issues
            )
            guard var line = try? encoder.encode(record) else { return }
            line.append(0x0A)
            write(line)
        }
    }

    private func write(_ line: Data) {
        let fileManager = FileManager.default
        do {
            if !fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.createDirectory(
                    at: fileURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                fileManager.createFile(atPath: fileURL.path, contents: nil)
                var url = fileURL
                var values = URLResourceValues()
                values.isExcludedFromBackup = true
                try? url.setResourceValues(values)
            }
            let handle = try FileHandle(forWritingTo: fileURL)
            defer { try? handle.close() }
            let size = try handle.seekToEnd()
            try handle.write(contentsOf: line)
            if Int(size) + line.count > Self.maxFileSize {
                try handle.close()
                dropOlderHalf()
            }
        } catch {
            MEGALogError("[Camera Upload Telemetry] failed to write record: \(error)")
        }
    }

    private func lastSequenceInFile() -> Int {
        struct SequenceOnly: Decodable {
            let seq: Int
        }
        guard let data = try? Data(contentsOf: fileURL),
              let lastLine = data.split(separator: 0x0A).last,
              let record = try? JSONDecoder().decode(SequenceOnly.self, from: Data(lastLine)) else {
            return 0
        }
        return record.seq
    }

    /// Keeps the newer half of the file, starting at a line boundary.
    private func dropOlderHalf() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let middle = data.count / 2
        guard let newline = data[middle...].firstIndex(of: 0x0A) else { return }
        try? data[data.index(after: newline)...].write(to: fileURL, options: .atomic)
    }
}
