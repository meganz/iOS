import Foundation

/// A local diagnostics file the About screen can export or clear through a hidden gesture.
public struct AboutDiagnosticsFile: Sendable {
    public let title: String
    /// The file to share, or nil when nothing has been recorded.
    public let makeExportFile: @Sendable () -> URL?
    public let clear: @Sendable () -> Void

    public init(
        title: String,
        makeExportFile: @escaping @Sendable () -> URL?,
        clear: @escaping @Sendable () -> Void
    ) {
        self.title = title
        self.makeExportFile = makeExportFile
        self.clear = clear
    }
}
