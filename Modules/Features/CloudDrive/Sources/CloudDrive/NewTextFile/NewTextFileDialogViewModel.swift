import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAL10n
import MEGASwift
import Observation

/// Presentation logic of the New text file dialog.
/// The Rich text box and the file extension follow each other in both directions.
@Observable @MainActor
public final class NewTextFileDialogViewModel {
    public private(set) var fileName = ".txt"

    @ObservationIgnored private var lastPlainExtension = "txt"
    @ObservationIgnored private let tracker: any AnalyticsTracking
    @ObservationIgnored private let onCreate: (String) -> Bool
    @ObservationIgnored private let onCancel: () -> Void

    /// - Parameters:
    ///   - tracker: Receives the created event.
    ///   - onCreate: Called with the file name, without the spaces at the ends.
    ///     Returns false when the dialog stays open, for example with no network.
    ///   - onCancel: Called when the user closes the dialog.
    public init(
        tracker: some AnalyticsTracking = DIContainer.tracker,
        onCreate: @escaping (String) -> Bool,
        onCancel: @escaping () -> Void
    ) {
        self.tracker = tracker
        self.onCreate = onCreate
        self.onCancel = onCancel
    }

    // MARK: - State

    /// True when the extension of the name is a Markdown extension.
    /// Setting it is a tap on the box. Only a tap saves the extension, so unchecking can bring it back.
    public var isRichTextChecked: Bool {
        get { Self.isMarkdownName(fileName) }
        set {
            guard newValue != isRichTextChecked else { return }
            let (baseName, currentExtension) = splitExtension(of: fileName)
            if newValue {
                if let currentExtension, !currentExtension.isEmpty {
                    lastPlainExtension = currentExtension
                }
                fileName = baseName + ".md"
            } else {
                fileName = baseName + "." + lastPlainExtension
            }
        }
    }

    public var hasInvalidCharacters: Bool {
        fileName.containsInvalidFileFolderNameCharacters
    }

    public var isCreateEnabled: Bool {
        !fileName.trimmingCharacters(in: .whitespaces).isEmpty && !hasInvalidCharacters
    }

    public var title: String {
        guard hasInvalidCharacters else { return Strings.Localizable.newTextFile }
        return Strings.Localizable.General.Error.charactersNotAllowed(String.Constants.invalidFileFolderNameCharactersToDisplay)
    }

    // MARK: - Input

    /// Typing never saves an extension. It passes through partial extensions such as `m`.
    public func setFileName(_ name: String) {
        fileName = name
    }

    /// Sends the created event only when the dialog closes to create the file.
    /// A tap that keeps the dialog open, such as with no network, sends nothing.
    public func didTapCreate() {
        guard isCreateEnabled else { return }
        let name = fileName.trimmingCharacters(in: .whitespaces)
        guard onCreate(name) else { return }
        tracker.trackAnalyticsEvent(with: Self.isMarkdownName(name) ? RichTextFileCreatedEvent() : PlainTextFileCreatedEvent())
    }

    /// The return key creates the file only when the name is valid.
    public func didSubmit() {
        guard isCreateEnabled else { return }
        didTapCreate()
    }

    public func didTapCancel() {
        onCancel()
    }

    // MARK: - Private

    private static func isMarkdownName(_ name: String) -> Bool {
        name.contains(".") && name.fileExtensionGroup.isMarkdownText
    }

    /// A name without a dot has no extension.
    private func splitExtension(of name: String) -> (baseName: String, extension: String?) {
        guard let dotIndex = name.lastIndex(of: ".") else { return (name, nil) }
        return (String(name[..<dotIndex]), String(name[name.index(after: dotIndex)...]))
    }
}
