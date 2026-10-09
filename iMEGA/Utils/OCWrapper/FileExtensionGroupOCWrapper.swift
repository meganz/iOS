import MEGASwift

/// `FileExtensionOCWrapper` is a class used for Objective-C compatibility, providing the functionality to verify whether a source file belongs to a certain group based on its file extension.
///
/// - Warning: This class is intended for use only from Objective-C, not Swift. It's marked as deprecated to deter use from Swift.
///
///     let isVideo = FileExtensionOCWrapper.fileExtensionGroup(verify: "mp4", membershipIn: "isVideo")
///
@objc public class FileExtensionGroupOCWrapper: NSObject {
    
    // @available(*, deprecated, message: "This method is intended for use only from Objective-C, not Swift.")
    public override init() {}
    
    @objc(verifyIsImage:)
    public static func verify(isImage str: String?) -> Bool {
        str?.fileExtensionGroup.isImage == true
    }

    @objc(verifyIsVideo:)
    public static func verify(isVideo str: String?) -> Bool {
        str?.fileExtensionGroup.isVideo == true
    }

    @objc(verifyIsAudio:)
    public static func verify(isAudio str: String?) -> Bool {
        str?.fileExtensionGroup.isAudio == true
    }

    @objc(verifyIsVisualMedia:)
    public static func verify(isVisualMedia str: String?) -> Bool {
        str?.fileExtensionGroup.isVisualMedia == true
    }

    @objc(verifyIsMultiMedia:)
    public static func verify(isMultiMedia str: String?) -> Bool {
        str?.fileExtensionGroup.isMultiMedia == true
    }

    @objc(verifyIsText:)
    public static func verify(isText str: String?) -> Bool {
        str?.fileExtensionGroup.isText == true
    }

    @objc(verifyIsWebCode:)
    public static func verify(isWebCode str: String?) -> Bool {
        str?.fileExtensionGroup.isWebCode == true
    }

    /// Files without an extension are only treated as editable text up to this size; larger ones are most likely binary.
    /// Matches Android's `MAX_SIZE_OPENABLE_TEXT_FILE` so both platforms open the same files in the text editor.
    static let maxExtensionlessTextFileSize: UInt64 = 20 * 1024 * 1024

    /// Uses the real path extension, so a name without one (e.g. "notes") maps to the empty extension group
    /// instead of being looked up as an extension itself.
    @objc(verifyIsEditableText:fileSize:)
    public static func verify(isEditableText str: String?, fileSize: UInt64) -> Bool {
        guard let pathExtension = str?.pathExtension,
              pathExtension.fileExtensionGroup.isEditableText else {
            return false
        }
        return pathExtension.isNotEmpty || fileSize <= maxExtensionlessTextFileSize
    }

    /// Like `verify(isEditableText:fileSize:)`, but a local file without an extension must also look like text,
    /// so binary content is left to the regular preview.
    @objc(verifyIsEditableTextFileAtPath:)
    public static func verify(isEditableTextFileAtPath path: String?) -> Bool {
        guard let path else { return false }
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: path))?[.size] as? UInt64
        guard verify(isEditableText: path, fileSize: fileSize ?? 0) else { return false }
        return path.pathExtension.isNotEmpty || looksLikeText(fileAtPath: path)
    }

    // MARK: - Content sniffing

    /// Same header length Android sniffs for files without an extension.
    private static let textSniffLength = 64 * 1024

    /// Same heuristic git uses: a NUL byte in the header marks the file as binary. Other control characters are
    /// allowed, so console output with ANSI escapes still opens; decoding afterwards rejects content that isn't text.
    private static func looksLikeText(fileAtPath path: String) -> Bool {
        guard let fileHandle = FileHandle(forReadingAtPath: path) else { return false }
        defer { try? fileHandle.close() }
        do {
            let header = try fileHandle.read(upToCount: textSniffLength) ?? Data()
            return !header.contains(0x00)
        } catch {
            return false
        }
    }

    @objc(verifyIsKnown:)
    public static func verify(isKnown str: String?) -> Bool {
        str?.fileExtensionGroup.isKnown == true
    }
}
