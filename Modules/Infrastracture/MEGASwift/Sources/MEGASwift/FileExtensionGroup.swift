import Foundation

public typealias FileExtension = String

/// `FileExtensionGroupRepresentable` protocol defines a set of properties that help classify the type of a file based on its extension.
///
/// Types conforming to `FileExtensionGroupRepresentable` can be used to distinguish between various categories of files including images, videos, audio, text, web-related code, and more.
public protocol FileExtensionGroupRepresentable {
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
    
    /// A Boolean value indicating whether the file is a text file that contains markdown content. This can include MD, MARKDOWN files etc.
    var isMarkdownText: Bool { get }
    
    /// A Boolean value indicating whether the file extension falls within any of the defined file extension groups.
    var isKnown: Bool { get }
}

/// A protocol that provides a data source for grouping file extensions.
///
/// Types that conform to `FileExtensionGroupDataSource` provide a file extension path as a key path and a file extension group conforming to `FileExtensionGroupRepresentable`.
/// It allows for grouping and categorising file types by their extensions.
///
/// Conforming types should provide the key path to the file extension and categorise the file into a file extension group using the `fileExtensionGroup` property.
///
/// - Important:
/// The `fileExtensionPath` key path should correctly represent the path to the file extension in the conforming type.
public protocol FileExtensionGroupDataSource {
    /// The associated type that represents the file extension group.
    /// It must conform to `FileExtensionGroupRepresentable`.
    associatedtype ExtensionGroup: FileExtensionGroupRepresentable

    /// The key path to the file extension in the conforming type.
    ///
    /// This key path is used to access the file extension.
    static var fileExtensionPath: KeyPath<Self, FileExtension> { get }

    /// The file extension group for the file.
    ///
    /// The conforming type should provide a way to categorise the file into a `ExtensionGroup`, based on the file extension.
    var fileExtensionGroup: ExtensionGroup { get }
}

public extension FileExtensionGroupDataSource {
    var fileExtensionGroup: some FileExtensionGroupRepresentable {
        FileExtensionGroup.Factory.make(fileExtensionGroupFrom: self)
    }
}

private struct FileExtensionGroup: FileExtensionGroupRepresentable {
    var isImage: Bool { Option.image.contains(selected) }
    var isVideo: Bool { Option.video.contains(selected) }
    var isAudio: Bool { Option.audio.contains(selected) }
    var isVisualMedia: Bool { Option.visualMedia.contains(selected) }
    var isMultiMedia: Bool { Option.multiMedia.contains(selected) }
    var isText: Bool { Option.text.contains(selected) }
    var isWebCode: Bool { Option.webCode.contains(selected) }
    var isEditableText: Bool { Option.editableText.contains(selected) }
    var isMarkdownText: Bool { Option.markdownText.contains(selected) }
    var isKnown: Bool { Option.allKnown.contains(selected) }
    
    private let selected: FileExtensionGroup.Option
    
    private init(_ dataSource: String?) {
        if let dataSource {
            selected = Constant.groupMap[dataSource.lowercased(), default: .unknown]
        } else {
            selected = .unknown
        }
    }
   
    fileprivate enum Factory {
        static func make<DataSource>(fileExtensionGroupFrom dataSource: DataSource) -> some FileExtensionGroupRepresentable where DataSource: FileExtensionGroupDataSource {
            FileExtensionGroup(dataSource[keyPath: DataSource.fileExtensionPath])
        }
    }

    fileprivate struct Option: OptionSet {
        let rawValue: UInt
        
        public static let unknown = Self(rawValue: 1 << 0)
        public static let empty = Self(rawValue: 1 << 1)
        public static let image = Self(rawValue: 1 << 2)
        public static let video = Self(rawValue: 1 << 3)
        public static let audio = Self(rawValue: 1 << 4)
        public static let text = Self(rawValue: 1 << 5)
        public static let webCode = Self(rawValue: 1 << 6)
        public static let markdown = Self(rawValue: 1 << 7)
        
        public static let visualMedia: Self = [.image, .video]
        public static let multiMedia: Self = [.video, .audio]
        public static let editableText: Self = [.webCode, .text, .empty, .markdown]
        public static let markdownText: Self = [.markdown]
        
        public static let allKnown: Self = [empty, image, video, audio, text, webCode, markdown]
    }
    
    private enum Constant {
        static let groupMap: [String: FileExtensionGroup.Option] = [
            "": .empty,
            // MARK: - Text
            "txt": .text,
            "ans": .text,
            "ascii": .text,
            "log": .text,
            "wpd": .text,
            "json": .text,
            "org": .text,
            // MARK: - Markdown Text
            "markdown": .markdown,
            "md": .markdown,
            "mdown": .markdown,
            "mkd": .markdown,
            "mkdn": .markdown,
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
            "mkv": .video,
            "m4v": .video,
            "mov": .video,
            "mp4": .video,
            "mqv": .video,
            "qt": .video,
            // MARK: - Image
            "3fr": .image,
            "arw": .image,
            "avif": .image,
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
            "jxl": .image,
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
