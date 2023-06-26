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

    @objc(verifyIsEditableText:)
    public static func verify(isEditableText str: String?) -> Bool {
        str?.fileExtensionGroup.isEditableText == true
    }

    @objc(verifyIsKnown:)
    public static func verify(isKnown str: String?) -> Bool {
        str?.fileExtensionGroup.isKnown == true
    }
}
