import Foundation

/// Launch arguments of the capture mode. `scripts/capture.sh` passes them.
/// `-capture` turns it on. `-capture-prefix images/` limits it to one folder.
/// `-capture-pages 4` sets the most screens saved per file.
struct CaptureConfig {
    let prefix: String
    let maxPages: Int

    static func fromLaunchArguments() -> CaptureConfig? {
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("-capture") else { return nil }
        func value(after flag: String) -> String? {
            guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else { return nil }
            return arguments[index + 1]
        }
        return CaptureConfig(
            prefix: value(after: "-capture-prefix") ?? "",
            maxPages: value(after: "-capture-pages").flatMap(Int.init) ?? 4
        )
    }
}
