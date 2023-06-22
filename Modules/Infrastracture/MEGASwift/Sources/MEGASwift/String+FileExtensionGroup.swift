import Foundation

/// `FileExtensionGroup` protocol defines a set of properties that help classify the type of a file based on its extension.
///
/// Types conforming to `FileExtensionGroup` can be used to distinguish between various categories of files including images, videos, audio, text, web-related code, and more.
public protocol FileExtensionGroup {
    /// A Boolean value indicating whether the file is an image.
    var isImage: Bool { get }
    
    /// A Boolean value indicating whether the file is a video.
    var isVideo: Bool { get }
    
    /// A Boolean value indicating whether the file is an audio.
    var isAudio: Bool { get }
    
    /// A Boolean value indicating whether the file is a visual media, this usually includes both images and videos.
    var isVisualMedia: Bool { get }
    
    /// A Boolean value indicating whether the file is a multimedia, typically including images, videos, and audio.
    var isMultiMedia: Bool { get }
    
    /// A Boolean value indicating whether the file is a text file.
    var isText: Bool { get }
    
    /// A Boolean value indicating whether the file is a web-related code file. This can include HTML, CSS, JS files etc.
    var isWebCode: Bool { get }
    
    /// A Boolean value indicating whether the file is a text file that can be edited. This can include TXT, DOCX, RTF files etc.
    var isEditableText: Bool { get }
    
    /// A Boolean value indicating whether the file extension falls within any of the defined file extension groups.
    var isKnown: Bool { get }
}

public extension String {
    /// Verifies if the file extension of a source file matches a certain file extension group.
    ///
    /// This method is used to check if a file falls into a particular file extension group such as 'isImage', 'isAudio' etc.
    /// The function checks the file extension of the input source string and uses the key path to determine the file extension group.
    ///
    /// - Parameters:
    ///     - source: The source string which represents the file. Typically this would be the file name or file path.
    ///     - boolPath: The KeyPath representing the property of the `FileExtensionGroup` protocol the file is to be checked against.
    /// - Returns: A Boolean value indicating whether the file falls into the file extension group indicated by the `boolPath`.
    static func fileExtensionGroup(verify source: String?, _ boolPath: KeyPath<any FileExtensionGroup, Bool>) -> Bool {
        guard let source else { return false }
        return FileExtension(source)[keyPath: boolPath]
    }
    
    /// Creates an object conforming to the `FileExtensionGroup` protocol based on the file extension of a source file.
    ///
    /// This function creates an object of a type that conforms to the `FileExtensionGroup` protocol based on the file extension of the input source string.
    /// The created object can then be used to check whether the file falls into specific file extension groups.
    ///
    /// - Parameter source: The source string which represents the file. Typically this would be the file name or file path.
    /// - Returns: An object conforming to `FileExtensionGroup` that corresponds to the file extension of the source.
    static func makeFileExtensionGroup(from source: String?) -> some FileExtensionGroup {
        FileExtension(source)
    }
    
    private struct FileExtension: FileExtensionGroup, CustomDebugStringConvertible {
        var isImage: Bool { Group.image.contains(group) }
        var isVideo: Bool { Group.video.contains(group) }
        var isAudio: Bool { Group.audio.contains(group) }
        var isVisualMedia: Bool { Group.visualMedia.contains(group) }
        var isMultiMedia: Bool { Group.multiMedia.contains(group) }
        var isText: Bool { Group.text.contains(group) }
        var isWebCode: Bool { Group.webCode.contains(group) }
        var isEditableText: Bool { Group.editableText.contains(group) }
        var isKnown: Bool { Group.allKnown.contains(group) }
        
        private let group: FileExtension.Group
        
        fileprivate init(_ source: String?) {
            if let source {
                group = Constant.groupMap[source, default: .unknown]
            } else {
                group = .unknown
            }
        }
        
#if DEBUG
        public var debugDescription: String {
            var result = [String]()
            if Group.unknown.contains(group) { result.append("unknown") }
            if Group.empty.contains(group) { result.append("empty") }
            if Group.image.contains(group) { result.append("image") }
            if Group.video.contains(group) { result.append("video") }
            if Group.audio.contains(group) { result.append("audio") }
            if Group.visualMedia.contains(group) { result.append("visualMedia") }
            if Group.multiMedia.contains(group) { result.append("multiMedia") }
            if Group.text.contains(group) { result.append("text") }
            if Group.webCode.contains(group) { result.append("webCode") }
            if Group.editableText.contains(group) { result.append("editableText") }
            if #available(iOS 15.0, *) {
                return "FileExtension.Group[\(result.formatted(.list(type: .and, width: .narrow)))]"
            } else {
                return "FileExtension.Group[\(result.joined(separator: ", "))]"
            }
        }
#endif
        
        private struct Group: OptionSet {
            let rawValue: UInt
            
            public static let unknown = Self(rawValue: 1 << 0)
            public static let empty = Self(rawValue: 1 << 1)
            public static let image = Self(rawValue: 1 << 2)
            public static let video = Self(rawValue: 1 << 3)
            public static let audio = Self(rawValue: 1 << 4)
            public static let text = Self(rawValue: 1 << 5)
            public static let webCode = Self(rawValue: 1 << 6)
            
            public static let visualMedia: Self = [.image, .video]
            public static let multiMedia: Self = [.video, .audio]
            public static let editableText: Self = [.webCode, .text, .empty]
            
            public static let allKnown: Self = [empty, image, video, audio, text, webCode]
        }
        
        private enum Constant {
            static let groupMap: [String: FileExtension.Group] = [
                "": .empty,
                // MARK: - Text
                "txt": .text,
                "ans": .text,
                "ascii": .text,
                "log": .text,
                "wpd": .text,
                "json": .text,
                "md": .text,
                // MARK: - Audio
                "aac": .audio,
                "ac3": .audio,
                "aif": .audio,
                "aiff": .audio,
                "au": .audio,
                "caf": .audio,
                "eac3": .audio,
                "ec3": .audio,
                "flac": .audio,
                "m4a": .audio,
                "mp3": .audio,
                "wav": .audio,
                // MARK: - Video
                "3g2": .video,
                "3gp": .video,
                "avi": .video,
                "m4v": .video,
                "mov": .video,
                "mp4": .video,
                "mqv": .video,
                "qt": .video,
                "3fr": .image,
                "arw": .image,
                "bmp": .image,
                "cr2": .image,
                "crw": .image,
                "ciff": .image,
                "cur": .image,
                "cs1": .image,
                "dcr": .image,
                "dng": .image,
                "erf": .image,
                "gif": .image,
                "heic": .image,
                "ico": .image,
                "iiq": .image,
                "j2c": .image,
                "jp2": .image,
                "jpf": .image,
                "jpeg": .image,
                "jpg": .image,
                "k25": .image,
                "kdc": .image,
                "mef": .image,
                "mos": .image,
                "mrw": .image,
                "nef": .image,
                "nrw": .image,
                "orf": .image,
                "pbm": .image,
                "pef": .image,
                "pgm": .image,
                "png": .image,
                "pnm": .image,
                "ppm": .image,
                "psd": .image,
                "raf": .image,
                "raw": .image,
                "rw2": .image,
                "rwl": .image,
                "sr2": .image,
                "srf": .image,
                "srw": .image,
                "tga": .image,
                "tif": .image,
                "tiff": .image,
                "webp": .image,
                "x3f": .image,
                // MARK: - Web Code
                "action": .webCode,
                "adp": .webCode,
                "ashx": .webCode,
                "asmx": .webCode,
                "asp": .webCode,
                "aspx": .webCode,
                "atom": .webCode,
                "axd": .webCode,
                "bml": .webCode,
                "cer": .webCode,
                "cfm": .webCode,
                "cgi": .webCode,
                "css": .webCode,
                "dhtml": .webCode,
                "do": .webCode,
                "dtd": .webCode,
                "eml": .webCode,
                "htm": .webCode,
                "html": .webCode,
                "ihtml": .webCode,
                "jhtml": .webCode,
                "jsonld": .webCode,
                "jsp": .webCode,
                "jspx": .webCode,
                "las": .webCode,
                "lasso": .webCode,
                "lassoapp": .webCode,
                "markdown": .webCode,
                "met": .webCode,
                "metalink": .webCode,
                "mht": .webCode,
                "mhtml": .webCode,
                "rhtml": .webCode,
                "rna": .webCode,
                "rnx": .webCode,
                "se": .webCode,
                "shtml": .webCode,
                "stm": .webCode,
                "wss": .webCode,
                "yaws": .webCode,
                "zhtml": .webCode,
                "xml": .webCode,
                "js": .webCode,
                "jar": .webCode,
                "java": .webCode,
                "class": .webCode,
                "php": .webCode,
                "php3": .webCode,
                "php4": .webCode,
                "php5": .webCode,
                "phtml": .webCode,
                "inc": .webCode,
                "pl": .webCode,
                "py": .webCode,
                "sql": .webCode,
                "accdb": .webCode,
                "db": .webCode,
                "dbf": .webCode,
                "mdb": .webCode,
                "pdb": .webCode,
                "c": .webCode,
                "cpp": .webCode,
                "h": .webCode,
                "cs": .webCode,
                "sh": .webCode,
                "vb": .webCode,
                "swift": .webCode
            ]
        }
    }
}
