import Foundation

/// A flat event parameter value, as Firebase Analytics accepts them: text or number, no nesting.
enum CameraUploadTelemetryValue: Sendable, Equatable, Codable {
    case int(Int)
    case double(Double)
    case string(String)

    static func bool(_ value: Bool) -> Self {
        .int(value ? 1 : 0)
    }

    /// Rounds to one decimal, enough for seconds and percentages.
    static func rounded(_ value: Double) -> Self {
        .double((value * 10).rounded() / 10)
    }

    var analyticsValue: any Sendable {
        switch self {
        case .int(let value): value
        case .double(let value): value
        case .string(let value): value
        }
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else {
            self = .string(try container.decode(String.self))
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .int(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .string(let value): try container.encode(value)
        }
    }
}

typealias CameraUploadTelemetryParameters = [String: CameraUploadTelemetryValue]

/// Where Camera Upload telemetry ends up. All events and user properties go through this, so the destination can be
/// swapped (local file while the events are being checked, Firebase Analytics afterwards).
protocol CameraUploadTelemetrySink: Sendable {
    func logEvent(_ name: String, parameters: CameraUploadTelemetryParameters)
    func setUserProperty(_ value: String?, forName name: String)
    /// Blocks until everything logged so far is stored, for the moment before the app is suspended or terminated.
    func waitUntilWritten()
    /// The app decided from the user's consent whether Firebase Analytics collects.
    func analyticsCollectionDidUpdate(isEnabled: Bool)
}

extension CameraUploadTelemetrySink {
    func waitUntilWritten() { }
    func analyticsCollectionDidUpdate(isEnabled: Bool) { }
}

/// Sends to several sinks, e.g. the local file and Firebase at the same time to compare them.
struct CameraUploadTelemetryCompositeSink: CameraUploadTelemetrySink {
    let sinks: [any CameraUploadTelemetrySink]

    func logEvent(_ name: String, parameters: CameraUploadTelemetryParameters) {
        sinks.forEach { $0.logEvent(name, parameters: parameters) }
    }

    func setUserProperty(_ value: String?, forName name: String) {
        sinks.forEach { $0.setUserProperty(value, forName: name) }
    }

    func waitUntilWritten() {
        sinks.forEach { $0.waitUntilWritten() }
    }

    func analyticsCollectionDidUpdate(isEnabled: Bool) {
        sinks.forEach { $0.analyticsCollectionDidUpdate(isEnabled: isEnabled) }
    }
}

/// Checks events and user properties against the Firebase Analytics limits, which Firebase enforces silently by
/// truncating or dropping. Returns one message per violation.
enum CameraUploadTelemetryLimits {
    static func issues(forEvent name: String, parameters: CameraUploadTelemetryParameters) -> [String] {
        var issues = nameIssues(name, kind: "event name", maxLength: 40)
        if parameters.count > 25 {
            issues.append("\(parameters.count) parameters, max 25")
        }
        for (key, value) in parameters.sorted(by: { $0.key < $1.key }) {
            issues += nameIssues(key, kind: "parameter name", maxLength: 40)
            if case .string(let text) = value, text.count > 100 {
                issues.append("\(key) value has \(text.count) characters, max 100")
            }
        }
        return issues
    }

    static func issues(forUserProperty name: String, value: String?) -> [String] {
        var issues = nameIssues(name, kind: "user property name", maxLength: 24)
        if let value, value.count > 36 {
            issues.append("\(name) value has \(value.count) characters, max 36")
        }
        return issues
    }

    private static func nameIssues(_ name: String, kind: String, maxLength: Int) -> [String] {
        var issues: [String] = []
        if name.count > maxLength {
            issues.append("\(kind) \(name) has \(name.count) characters, max \(maxLength)")
        }
        if name.range(of: "^[A-Za-z][A-Za-z0-9_]*$", options: .regularExpression) == nil {
            issues.append("\(kind) \(name) must start with a letter and use only letters, digits and _")
        }
        if ["firebase_", "google_", "ga_"].contains(where: name.hasPrefix) {
            issues.append("\(kind) \(name) uses a reserved prefix")
        }
        return issues
    }
}
