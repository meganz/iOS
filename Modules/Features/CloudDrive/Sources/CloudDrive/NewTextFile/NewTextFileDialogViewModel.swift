import MEGAL10n
import MEGASwift
import Observation

/// Presentation logic of the New text file dialog.
/// The Rich text box and the file extension follow each other in both directions.
@Observable @MainActor
public final class NewTextFileDialogViewModel {
    public private(set) var fileName = ".txt"

    @ObservationIgnored private var lastPlainExtension = "txt"
    @ObservationIgnored private let onCreate: (String) -> Void
    @ObservationIgnored private let onCancel: () -> Void

    /// - Parameters:
    ///   - onCreate: Called with the file name, without the spaces at the ends.
    ///   - onCancel: Called when the user closes the dialog.
    public init(onCreate: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.onCreate = onCreate
        self.onCancel = onCancel
    }

    // MARK: - State

    /// True when the extension of the name is a Markdown extension.
    /// Setting it is a tap on the box. Only a tap saves the extension, so unchecking can bring it back.
    public var isRichTextChecked: Bool {
        get { fileName.contains(".") && fileName.fileExtensionGroup.isMarkdownText }
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

    public func didTapCreate() {
        onCreate(fileName.trimmingCharacters(in: .whitespaces))
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

    /// A name without a dot has no extension.
    private func splitExtension(of name: String) -> (baseName: String, extension: String?) {
        guard let dotIndex = name.lastIndex(of: ".") else { return (name, nil) }
        return (String(name[..<dotIndex]), String(name[name.index(after: dotIndex)...]))
    }
}
