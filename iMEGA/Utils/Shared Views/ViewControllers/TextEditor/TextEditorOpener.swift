import Foundation
import MEGADomain
import MEGASwift
import MEGATextEditor

/// Opens text files for the Objective-C node flows.
/// It reads the Markdown gate and the cached file, so `TextEditorViewRouter` only builds screens.
@objc @MainActor
final class TextEditorOpener: NSObject {
    /// The Markdown screens are on when a Markdown editor feature flag is on.
    @objc static var isMarkdownEditorEnabled: Bool {
        TextEditorViewModel.isMarkdownEditorEnabled()
    }

    /// A file from a folder link or a file link opens read only on the Markdown screen.
    /// Other text files and Markdown files over the size limit keep the document preview.
    @objc static func opensLinkFileInTextEditor(fileName: String, sizeInBytes: UInt64) -> Bool {
        opensLinkFileInTextEditor(fileName: fileName, sizeInBytes: sizeInBytes, isMarkdownEditorEnabled: isMarkdownEditorEnabled)
    }

    static func opensLinkFileInTextEditor(fileName: String, sizeInBytes: UInt64, isMarkdownEditorEnabled: Bool) -> Bool {
        MarkdownTextEditorRoute(fileName: fileName, sizeInBytes: sizeInBytes, isEnabled: isMarkdownEditorEnabled) == .markdownFile
    }

    /// Offline, Chat, Transfers and Versions open only Markdown files on the Markdown screen.
    /// Other text files, large Markdown files and a disabled flag keep the document preview.
    @objc static func opensFileOnMarkdownScreen(fileName: String, sizeInBytes: UInt64) -> Bool {
        opensFileOnMarkdownScreen(fileName: fileName, sizeInBytes: sizeInBytes, isMarkdownEditorEnabled: isMarkdownEditorEnabled)
    }

    static func opensFileOnMarkdownScreen(fileName: String, sizeInBytes: UInt64, isMarkdownEditorEnabled: Bool) -> Bool {
        MarkdownTextEditorRoute(fileName: fileName, sizeInBytes: sizeInBytes, isEnabled: isMarkdownEditorEnabled) == .markdownFile
    }

    /// Opens a Markdown file from the Offline folder, read only. Returns nil when the document preview must open it.
    @objc static func makeOfflineMarkdownViewController(filePath: String) -> UIViewController? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: filePath)
        let sizeInBytes = (attributes?[.size] as? NSNumber)?.uint64Value ?? 0
        return makeOfflineMarkdownViewController(filePath: filePath, sizeInBytes: sizeInBytes, isMarkdownEditorEnabled: isMarkdownEditorEnabled)
    }

    /// The size check runs before `readFile`, so a large file is never loaded.
    static func makeOfflineMarkdownViewController(
        filePath: String,
        sizeInBytes: UInt64,
        isMarkdownEditorEnabled: Bool,
        readFile: (String) -> Data? = { FileManager.default.contents(atPath: $0) }
    ) -> UIViewController? {
        let fileName = filePath.lastPathComponent
        guard opensFileOnMarkdownScreen(fileName: fileName, sizeInBytes: sizeInBytes, isMarkdownEditorEnabled: isMarkdownEditorEnabled),
              let data = readFile(filePath),
              let text = MarkdownTextEditorText.decode(data) else { return nil }
        let textFile = TextFile(fileName: fileName, content: text, size: sizeInBytes, encode: String.Encoding.utf8.rawValue)
        return TextEditorViewRouter(
            textFile: textFile,
            textEditorMode: .view,
            isMarkdownEditorEnabled: isMarkdownEditorEnabled,
            source: .offline
        ).buildMarkdownScreen()
    }

    /// Opens a cached text file. Returns nil when the text cannot be decoded, so the caller can try other viewers.
    @objc static func makeCachedTextViewController(
        node: MEGANode,
        filePath: String,
        isFromSharedItem: Bool,
        isLink: Bool,
        fileLink: String?,
        presenter: UIViewController?,
        source: TextEditorFileSource,
        chatId: NSNumber?,
        messageId: NSNumber?
    ) -> UIViewController? {
        makeCachedTextViewController(
            node: node,
            filePath: filePath,
            isFromSharedItem: isFromSharedItem,
            isLink: isLink,
            fileLink: fileLink,
            presenter: presenter,
            source: source,
            chatId: chatId,
            messageId: messageId,
            isMarkdownEditorEnabled: isMarkdownEditorEnabled
        )
    }

    static func makeCachedTextViewController(
        node: MEGANode,
        filePath: String,
        isFromSharedItem: Bool,
        isLink: Bool,
        fileLink: String?,
        presenter: UIViewController?,
        source: TextEditorFileSource,
        chatId: NSNumber?,
        messageId: NSNumber?,
        isMarkdownEditorEnabled: Bool
    ) -> UIViewController? {
        let fileName = node.name ?? ""
        return makeCachedTextViewController(
            filePath: filePath,
            fileName: fileName,
            sizeInBytes: node.size?.uint64Value ?? 0,
            isMarkdownEditorEnabled: isMarkdownEditorEnabled,
            node: node.toNodeEntity(),
            presenter: presenter
        ) { content, encoding in
            let textFile = TextFile(
                fileName: fileName,
                content: content,
                size: UInt64(node.size?.uint32Value ?? 0),
                encode: encoding.rawValue
            )
            return TextEditorViewRouter(
                textFile: textFile,
                textEditorMode: .view,
                isFromSharedItem: isFromSharedItem,
                node: node,
                presenter: presenter,
                isMarkdownEditorEnabled: isMarkdownEditorEnabled,
                isLink: isLink,
                fileLink: fileLink,
                source: source,
                chatId: chatId,
                messageId: messageId
            )
        }
    }

    /// Checks the size of a Markdown file before it reads, so a large file is never loaded.
    /// - Parameters:
    ///   - node: The file the too-large alert can export. Without it the alert shows only Cancel.
    ///   - makeRouter: Builds the router for the decoded text and the encoding that decoded it.
    static func makeCachedTextViewController(
        filePath: String,
        fileName: String,
        sizeInBytes: UInt64,
        isMarkdownEditorEnabled: Bool,
        node: NodeEntity? = nil,
        presenter: UIViewController? = nil,
        makeRouter: (_ content: String, _ encoding: String.Encoding) -> TextEditorViewRouter
    ) -> UIViewController? {
        switch MarkdownTextEditorRoute(fileName: fileName, sizeInBytes: sizeInBytes, isEnabled: isMarkdownEditorEnabled) {
        case .tooLarge:
            return TextEditorViewRouter.makeMarkdownTooLargeAlert(node: node, presenter: presenter)
        case .markdownFile:
            // Markdown that is not valid UTF-8 opens in the document preview, like a downloaded file.
            guard let data = FileManager.default.contents(atPath: filePath),
                  let text = MarkdownTextEditorText.decode(data) else { return nil }
            return makeRouter(text, .utf8).buildMarkdownScreen()
        case .otherFile:
            break
        }
        var encoding = String.Encoding.utf8
        guard let text = try? String(contentsOfFile: filePath, usedEncoding: &encoding) else { return nil }
        return makeRouter(text, encoding).build()
    }
}
