import FirebaseAnalytics
import Foundation

/// Sends Camera Upload telemetry to Firebase Analytics. The app turns collection off at every launch until it knows
/// the user's consent, so the events logged before then wait in a file: they are sent once collection is on, and
/// dropped if it stays off.
final class CameraUploadTelemetryFirebaseSink: CameraUploadTelemetrySink, @unchecked Sendable {
    private struct Event: Codable {
        let name: String
        let parameters: CameraUploadTelemetryParameters
    }

    private enum Collection {
        case unknown, enabled, disabled
    }

    /// Far more than a few runs and wake-ups log before the consent is known.
    private static let maxWaitingEvents = 200

    // Accessed only on `queue`.
    private var collection = Collection.unknown
    private lazy var waitingEvents = loadWaitingEvents()
    private let queue = DispatchQueue(label: "nz.mega.cameraUpload.telemetry.firebaseSink", qos: .utility)
    private let fileURL: URL

    init(directoryURL: URL = CameraUploadTelemetryFileSink.defaultDirectoryURL) {
        fileURL = directoryURL.appendingPathComponent("firebase-waiting-events.json", isDirectory: false)
    }

    // MARK: - CameraUploadTelemetrySink

    func logEvent(_ name: String, parameters: CameraUploadTelemetryParameters) {
        let event = Event(name: name, parameters: parameters)
        queue.async { [self] in
            switch collection {
            case .enabled: send(event)
            case .disabled: break
            case .unknown: keep(event)
            }
        }
    }

    /// Dropped until collection is on: they are all set again then.
    func setUserProperty(_ value: String?, forName name: String) {
        queue.async { [self] in
            guard collection == .enabled else { return }
            Analytics.setUserProperty(value, forName: name)
        }
    }

    func waitUntilWritten() {
        queue.sync { }
    }

    func analyticsCollectionDidUpdate(isEnabled: Bool) {
        queue.async { [self] in
            collection = isEnabled ? .enabled : .disabled
            guard !waitingEvents.isEmpty else { return }
            if isEnabled {
                waitingEvents.forEach(send)
            }
            waitingEvents = []
            saveWaitingEvents()
        }
    }

    // MARK: - Private

    private func send(_ event: Event) {
        Analytics.logEvent(event.name, parameters: event.parameters.mapValues { $0.analyticsValue as Any })
    }

    private func keep(_ event: Event) {
        guard waitingEvents.count < Self.maxWaitingEvents else {
            MEGALogError("[Camera Upload Telemetry] too many events waiting for the analytics consent, dropped \(event.name)")
            return
        }
        waitingEvents.append(event)
        saveWaitingEvents()
    }

    private func loadWaitingEvents() -> [Event] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        do {
            return try JSONDecoder().decode([Event].self, from: data)
        } catch {
            MEGALogError("[Camera Upload Telemetry] failed to read the events waiting for the analytics consent: \(error)")
            return []
        }
    }

    /// Removes the file when nothing is waiting.
    private func saveWaitingEvents() {
        do {
            if waitingEvents.isEmpty {
                try? FileManager.default.removeItem(at: fileURL)
                return
            }
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(waitingEvents).write(to: fileURL, options: .atomic)
        } catch {
            MEGALogError("[Camera Upload Telemetry] failed to save the events waiting for the analytics consent: \(error)")
        }
    }
}
