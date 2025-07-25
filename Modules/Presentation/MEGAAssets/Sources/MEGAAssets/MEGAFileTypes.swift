import MEGASwift

private let fileTypeImageResources: [String: MEGAAssetsFileType] = [
    "3ds": .filetype3D,
    "3dm": .filetype3D,
    "max": .filetype3D,
    "obj": .filetype3D,
    
    "3fr": .filetypeRaw,
    "arw": .filetypeRaw,
    "bay": .filetypeRaw,
    "cr2": .filetypeRaw,
    "dcr": .filetypeRaw,
    "dng": .filetypeRaw,
    "fff": .filetypeRaw,
    "mef": .filetypeRaw,
    "mrw": .filetypeRaw,
    "nef": .filetypeRaw,
    "orf": .filetypeRaw,
    "pef": .filetypeRaw,
    "rwl": .filetypeRaw,
    "rw2": .filetypeRaw,
    "srf": .filetypeRaw,
    
    "3g2": .filetypeVideo,
    "3gp": .filetypeVideo,
    "asf": .filetypeVideo,
    "avi": .filetypeVideo,
    "m4v": .filetypeVideo,
    "mkv": .filetypeVideo,
    "mov": .filetypeVideo,
    "mp4": .filetypeVideo,
    "mpeg": .filetypeVideo,
    "mpg": .filetypeVideo,
    "ogv": .filetypeVideo,
    "vob": .filetypeVideo,
    "webm": .filetypeVideo,
    "wmv": .filetypeVideo,
    
    "3ga": .filetypeAudio,
    "aac": .filetypeAudio,
    "ac3": .filetypeAudio,
    "aif": .filetypeAudio,
    "aiff": .filetypeAudio,
    "flac": .filetypeAudio,
    "iff": .filetypeAudio,
    "mid": .filetypeAudio,
    "midi": .filetypeAudio,
    "mp3": .filetypeAudio,
    "m4a": .filetypeAudio,
    "wav": .filetypeAudio,
    "wma": .filetypeAudio,
    
    "7z": .filetypeCompressed,
    "zip": .filetypeCompressed,
    "tar": .filetypeCompressed,
    "tbz": .filetypeCompressed,
    "sitx": .filetypeCompressed,
    "tgz": .filetypeCompressed,
    "rar": .filetypeCompressed,
    "bz2": .filetypeCompressed,
    "gz": .filetypeCompressed,
    
    "abr": .filetypePhotoshop,
    "psb": .filetypePhotoshop,
    "psd": .filetypePhotoshop,
    
    "accdb": .filetypeWebLang,
    "asp": .filetypeWebLang,
    "aspx": .filetypeWebLang,
    "db": .filetypeWebLang,
    "dbf": .filetypeWebLang,
    "c": .filetypeWebLang,
    "cc": .filetypeWebLang,
    "cgi": .filetypeWebLang,
    "dll": .filetypeWebLang,
    "cxx": .filetypeWebLang,
    "cpp": .filetypeWebLang,
    "php": .filetypeWebLang,
    "php3": .filetypeWebLang,
    "php4": .filetypeWebLang,
    "php5": .filetypeWebLang,
    "phtml": .filetypeWebLang,
    "pl": .filetypeWebLang,
    "pdb": .filetypeWebLang,
    "py": .filetypeWebLang,
    "sh": .filetypeWebLang,
    "sql": .filetypeWebLang,
    "hpp": .filetypeWebLang,
    "h": .filetypeWebLang,
    "m": .filetypeWebLang,
    "mm": .filetypeWebLang,
    "inc": .filetypeWebLang,
    "mdb": .filetypeWebLang,
    
    "aep": .filetypeAfterEffects,
    "aet": .filetypeAfterEffects,
    
    "ai": .filetypeIllustrator,
    "ait": .filetypeIllustrator,
    
    "ans": .filetypeText,
    "rtf": .filetypeText,
    "srt": .filetypeText,
    "txt": .filetypeText,
    "wpd": .filetypeText,
    "ascii": .filetypeText,
    "log": .filetypeText,
    
    "apk": .filetypeExecutable,
    "app": .filetypeExecutable,
    "com": .filetypeExecutable,
    "cmd": .filetypeExecutable,
    "bin": .filetypeExecutable,
    "exe": .filetypeExecutable,
    "gadget": .filetypeExecutable,
    "msi": .filetypeExecutable,
    
    "cdr": .filetypeVector,
    "eps": .filetypeVector,
    "svg": .filetypeVector,
    "svgz": .filetypeVector,
    
    "avif": .filetypeImages,
    "bmp": .filetypeImages,
    "gif": .filetypeImages,
    "jpeg": .filetypeImages,
    "jpg": .filetypeImages,
    "jxl": .filetypeImages,
    "heic": .filetypeImages,
    "tga": .filetypeImages,
    "tif": .filetypeImages,
    "tiff": .filetypeImages,
    "png": .filetypeImages,
    
    "class": .filetypeWebData,
    "css": .filetypeWebData,
    "dhtml": .filetypeWebData,
    "jar": .filetypeWebData,
    "java": .filetypeWebData,
    "html": .filetypeWebData,
    "js": .filetypeWebData,
    "shtml": .filetypeWebData,
    "xml": .filetypeWebData,
    
    "doc": .filetypeWord,
    "docx": .filetypeWord,
    "dotx": .filetypeWord,
    "wps": .filetypeWord,
    
    "dwg": .filetypeCAD,
    "dxf": .filetypeCAD,
    
    "dmg": .filetypeDmg,
    
    "fnt": .filetypeFont,
    "fon": .filetypeFont,
    "otf": .filetypeFont,
    "ttf": .filetypeFont,
    
    "gsheet": .filetypeSpreadsheet,
    "nb": .filetypeSpreadsheet,
    "ods": .filetypeSpreadsheet,
    "ots": .filetypeSpreadsheet,
    "xlr": .filetypeSpreadsheet,
    
    "indd": .filetypeIndesign,
    
    "pps": .filetypePowerpoint,
    "ppt": .filetypePowerpoint,
    "pptx": .filetypePowerpoint,
    
    "key": .filetypeKeynote,
    "numbers": .filetypeNumbers,
    "odp": .filetypeGeneric,
    "odt": .filetypeOpenoffice,
    
    "xls": .filetypeExcel,
    "xlsx": .filetypeExcel,
    "xlt": .filetypeExcel,
    "xltm": .filetypeExcel,
    
    "pages": .filetypePages,
    "pdf": .filetypePdf,
    
    "ppj": .filetypePremiere,
    "prproj": .filetypePremiere,
    
    "torrent": .filetypeTorrent,
    "url": .filetypeUrl,
    "xd": .filetypeExperiencedesign
]

enum MEGAAssetsFileType: CaseIterable, Sendable {
    case filetypeFolder,
         filetype3D,
         filetypeRaw,
         filetypeVideo,
         filetypeAudio,
         filetypeCompressed,
         filetypePhotoshop,
         filetypeWebLang,
         filetypeAfterEffects,
         filetypeIllustrator,
         filetypeText,
         filetypeExecutable,
         filetypeVector,
         filetypeImages,
         filetypeWebData,
         filetypeWord,
         filetypeCAD,
         filetypeDmg,
         filetypeFont,
         filetypeSpreadsheet,
         filetypeIndesign,
         filetypePowerpoint,
         filetypeKeynote,
         filetypeNumbers,
         filetypeGeneric,
         filetypeOpenoffice,
         filetypeExcel,
         filetypePages,
         filetypePdf,
         filetypePremiere,
         filetypeTorrent,
         filetypeUrl,
         filetypeExperiencedesign,
         filetypeFolderCamera
}

extension MEGAAssetsFileType {
    init(withFileExtension fileExtension: String) {
        self = fileTypeImageResources[fileExtension.lowercased(), default: MEGAAssetsFileType.filetypeGeneric]
    }
    
    init(withFileName fileName: String) {
        self.init(withFileExtension: fileName.pathExtension)
    }
}
