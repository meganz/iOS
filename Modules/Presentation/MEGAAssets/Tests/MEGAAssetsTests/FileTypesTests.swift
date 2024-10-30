@testable import MEGAAssets
import Testing

struct FileTypesTests {
    @Suite("calls fileTypeResource for file name")
    struct CallsFileTypeResourceForFileName {
        
        @Test("when given a supported file extension, it should return the correct asset", arguments: supportedExtensionArguments())
        func supportedFileNameShouldReturnAssets(fileExtension: String, expected: MEGAAssetsImageName) {
            let testFileName = "test.\(fileExtension)"
            #expect(FileTypes.fileTypeResource(forFileName: testFileName) == expected)
        }
        
        @Test("when given a unsupported file extension, it should default to filetypeGeneric asset", arguments: ["bkf", "ISO"])
        func unsupportedFileNameShouldReturnGenericAsset(unsupportedExtension: String) {
            let testFileName = "test.\(unsupportedExtension)"
            #expect(FileTypes.fileTypeResource(forFileName: testFileName) == .filetypeGeneric)
        }
    }
    
    @Suite("calls fileTypeResource for file extensions")
    struct CallsFileTypeResourceForFileExtensions {
        @Test("when given a supported file extension, it should return the correct asset", arguments: supportedExtensionArguments())
        func supportedFileExtensionShouldReturnAssets(fileExtension: String, expected: MEGAAssetsImageName) {
            #expect(FileTypes.fileTypeResource(forFileExtension: fileExtension) == expected)
        }
        
        @Test("when given a unsupported file extension, it should default to filetypeGeneric asset", arguments: ["bkf", "ISO"])
        func unsupportedFileExtensionShouldReturnGenericAsset(unsupportedExtension: String) {
            #expect(FileTypes.fileTypeResource(forFileExtension: unsupportedExtension) == .filetypeGeneric)
        }
    }
    
    static func supportedExtensionArguments() -> [(String, MEGAAssetsImageName)] {
        SupportedFileExtension.allCases.flatMap(\.expectedExtensionForAssetImageName)
    }
    
    enum SupportedFileExtension: CaseIterable {
        case threeDimension
        case raw
        case video
        case audio
        case compressed
        case photoshop
        case webLang
        case afterEffects
        case illustrator
        case text
        case executable
        case vector
        case images
        case webData
        case word
        case CAD
        case dmg
        case font
        case spreadsheet
        case indesign
        case powerpoint
        case keynote
        case numbers
        case generic
        case openOffice
        case excel
        case pages
        case pdf
        case premiere
        case sketch
        case torrent
        case url
        case experienceDesign
        
        var extensions: [String] {
            switch self {
            case .threeDimension:
                ["3ds", "3dm", "max", "obj"]
            case .raw:
                ["3fr", "arw", "bay", "cr2", "dcr", "dng", "fff", "mef", "mrw", "nef", "orf", "pef", "rwl", "rw2", "srf"]
            case .video:
                ["3g2", "3gp", "asf", "avi", "m4v", "mkv", "mov", "mp4", "mpeg", "mpg", "ogv", "vob", "webm", "wmv"]
            case .audio:
                ["3ga", "aac", "ac3", "aif", "aiff", "flac", "iff", "mid", "midi", "mp3", "m4a", "wav", "wma"]
            case .compressed:
                [ "7z", "zip", "tar", "tbz", "sitx", "tgz", "rar", "bz2", "gz"]
            case .photoshop:
                ["abr", "psb", "psd"]
            case .webLang:
                ["accdb", "asp", "aspx", "db", "dbf", "c", "cc", "cgi", "dll", "cxx", "cpp", "php", "php3", "php4", "php5", "phtml", "pl", "pdb", "py", "sh", "sql", "hpp", "h", "m", "mm", "inc", "mdb"]
            case .afterEffects:
                ["aep", "aet"]
            case .illustrator:
                ["ai", "ait"]
            case .text:
                ["ans", "rtf", "srt", "txt", "wpd", "ascii", "log"]
            case .executable:
                ["apk", "app", "com", "cmd", "bin", "exe", "gadget", "msi"]
            case .vector:
                ["cdr", "eps", "svg", "svgz"]
            case .images:
                ["avif", "bmp", "gif", "jpeg", "jpg", "jxl", "heic", "tga", "tif", "tiff", "png"]
            case .webData:
                ["class", "css", "dhtml", "jar", "java", "html", "js", "shtml", "xml"]
            case .word:
                ["doc", "docx", "dotx", "wps"]
            case .CAD:
                ["dwg", "dxf"]
            case .dmg:
                ["dmg"]
            case .font:
                ["fnt", "fon", "otf", "ttf"]
            case .spreadsheet:
                ["gsheet", "nb", "ods", "ots", "xlr"]
            case .indesign:
                ["indd"]
            case .powerpoint:
                ["pps", "ppt", "pptx"]
            case .keynote:
                ["key"]
            case .numbers:
                ["numbers"]
            case .generic:
                ["odp"]
            case .openOffice:
                ["odt"]
            case .excel:
                ["xls", "xlsx", "xlt", "xltm"]
            case .pages:
                ["pages"]
            case .pdf:
                ["pdf"]
            case .premiere:
                ["ppj", "prproj"]
            case .sketch:
                ["sketch"]
            case .torrent:
                ["torrent"]
            case .url:
                ["url"]
            case .experienceDesign:
                ["Xd"]
            }
        }
        
        var expectedExtensionForAssetImageName: [(String, MEGAAssetsImageName)] {
            let imageName = expectedMEGAAssetsImageName
            return extensions.map { ($0, imageName) }
        }
        
        var expectedMEGAAssetsImageName: MEGAAssetsImageName {
            switch self {
            case .threeDimension:
                .filetype3D
            case .raw:
                .filetypeRaw
            case .video:
                .filetypeVideo
            case .audio:
                .filetypeAudio
            case .compressed:
                .filetypeCompressed
            case .photoshop:
                .filetypePhotoshop
            case .webLang:
                .filetypeWebLang
            case .afterEffects:
                .filetypeAfterEffects
            case .illustrator:
                .filetypeIllustrator
            case .text:
                .filetypeText
            case .executable:
                .filetypeExecutable
            case .vector:
                .filetypeVector
            case .images:
                .filetypeImages
            case .webData:
                .filetypeWebData
            case .word:
                .filetypeWord
            case .CAD:
                .filetypeCAD
            case .dmg:
                .filetypeDmg
            case .font:
                .filetypeFont
            case .spreadsheet:
                .filetypeSpreadsheet
            case .indesign:
                .filetypeIndesign
            case .powerpoint:
                .filetypePowerpoint
            case .keynote:
                .filetypeKeynote
            case .numbers:
                .filetypeNumbers
            case .generic:
                .filetypeGeneric
            case .openOffice:
                .filetypeOpenoffice
            case .excel:
                .filetypeExcel
            case .pages:
                .filetypePages
            case .pdf:
                .filetypePdf
            case .premiere:
                .filetypePremiere
            case .sketch:
                .filetypeSketch
            case .torrent:
                .filetypeTorrent
            case .url:
                .filetypeUrl
            case .experienceDesign:
                .filetypeExperiencedesign
            }
        }
    }
}
