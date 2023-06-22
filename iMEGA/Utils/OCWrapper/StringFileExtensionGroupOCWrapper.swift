import MEGASwift

/// `String.FileExtensionOCWrapper` is a class used for Objective-C compatibility, providing the functionality to verify whether a source file belongs to a certain group based on its file extension.
///
/// - Warning: This class is intended for use only from Objective-C, not Swift. It's marked as deprecated to deter use from Swift.
///
///     let isVideo = String.FileExtensionOCWrapper.fileExtensionGroup(verify: "mp4", membershipIn: "isVideo")
///
@objc public class StringFileExtensionGroupOCWrapper: NSObject {
    
    // @available(*, deprecated, message: "This method is intended for use only from Objective-C, not Swift.")
    public override init() {}
    
    /// Verifies whether the source file belongs to a certain group based on its file extension.
    ///
    /// - Parameters:
    ///   - source: The source file as a string.
    ///   - groupKey: The group key as a string, indicating the file group to be verified.
    ///     Possible keys include: "image", "video", "audio", "visualMedia", "multiMedia", "text", "webCode", "editableText", and "known".
    ///
    /// - Returns: A boolean value indicating whether the source file belongs to the group represented by the `groupKey`.
    ///
    /// - Warning: This method is intended for use only from Objective-C, not Swift. It's marked as deprecated to deter use from Swift.
    ///
    ///     let isVideo = String.FileExtensionOCWrapper.fileExtensionGroup(verify: "mp4", membershipIn: "video")
    ///
    @objc public static func verify(_ source: String?, isMemberOf groupKey: String?) -> Bool {
        guard let source, let groupKey else { return false }
        var groupMembershipPath: KeyPath<any FileExtensionGroup, Bool>?
        switch groupKey {
        case "image": groupMembershipPath = \.isImage
        case "video": groupMembershipPath = \.isVideo
        case "audio": groupMembershipPath = \.isAudio
        case "visualMedia": groupMembershipPath = \.isVisualMedia
        case "multiMedia": groupMembershipPath = \.isMultiMedia
        case "text": groupMembershipPath = \.isText
        case "webCode": groupMembershipPath = \.isWebCode
        case "editableText": groupMembershipPath = \.isEditableText
        case "known": groupMembershipPath = \.isKnown
        default: break
        }
        guard let groupMembershipPath else { return false }
        return String.fileExtensionGroup(verify: source, groupMembershipPath)
    }
}
