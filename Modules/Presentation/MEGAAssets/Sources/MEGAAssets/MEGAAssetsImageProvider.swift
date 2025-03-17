import SwiftUI
import UIKit
/// A provider type to access MEGAAssets image by it's name for SPM support. At the moment, SPM does not support assets extension (e.g. UIImage.myImageNameFromAssets), thus, this provider hepls to simplify the access, wrapping bundle reference.
public class MEGAAssetsImageProvider {
    
    /// Static function to get image of MEGAAssets. See `MEGAAssetsImageProviderTests.testImageNamed_withNotFoundImageName_returnsNil()` to check how to use this API.
    /// - Parameter named: your desired image name from MEGAAssets
    /// - Returns: A nullable UIImage. Returns nil if the image is not found.
    /// - Warning: This method should no longer be used, it allows for errors in asset names to be introduced. Please use ``MEGAAssetsImageProvider/image(named:)-2v25t`` instead.
    public static func image(named: String) -> UIImage? {
        return UIImage(named: named, in: .module, with: nil)
    }
    
    /// Static function to get image of MEGAAssets.
    /// - Parameter named: your desired image name from MEGAAssets
    /// - Returns: A UIImage.
    public static func image(named: MEGAAssetsImageName) -> UIImage {
        guard let image = image(named: named.rawValue) else {
            assertionFailure("MEGAAssetsImageProvider failed to load asset \(named)")
            return UIImage()
        }
        return image
    }
    
    /// Static function to get image of MEGAAssets.
    /// - Parameter named: your desired image name from MEGAAssets
    /// - Returns: A SwiftUI.Image.
    public static func image(named: MEGAAssetsImageName) -> Image {
        Image(named.rawValue, bundle: .module)
    }
    
    /// Static function to get UIImage associated with the name of the file, this will reference the extension of the filename.
    /// - Parameter name: your desired image name from MEGAAssets
    /// - Returns: A UIKit.UIImage.
    public static func fileTypeResource(forFileName name: String) -> UIImage {
        image(named: FileTypes.fileTypeResource(forFileName: name))
    }
    
    /// Static function to get UIImage of that best represents a file, by the given file extension.
    /// - Parameter fileExtension: your desired image name from MEGAAssets
    /// - Returns: A UIKit.UIImage.
    public static func fileTypeResource(forFileExtension fileExtension: String) -> UIImage {
        image(named: FileTypes.fileTypeResource(forFileExtension: fileExtension))
    }
    
    /// Static function to get Image associated with the name of the file, this will reference the extension of the filename.
    /// - Parameter name: your desired image name from MEGAAssets
    /// - Returns: A SwiftUI.Image.
    public static func fileTypeResource(forFileName name: String) -> Image {
        image(named: FileTypes.fileTypeResource(forFileName: name))
    }
    
    /// Static function to get Image of that best represents a file, by the given file extension.
    /// - Parameter fileExtension: your desired image name from MEGAAssets
    /// - Returns: A SwiftUI.Image.
    public static func fileTypeResource(forFileExtension fileExtension: String) -> Image {
        image(named: FileTypes.fileTypeResource(forFileExtension: fileExtension))
    }
    
    /// Static function to get the MEGAAssetsImageName associated with the name of the file, this will reference the extension of the filename.
    /// - Parameter name: your desired image name from MEGAAssets
    /// - Returns: A SwiftUI.Image.
    public static func fileTypeResource(forFileName name: String) -> MEGAAssetsImageName {
        FileTypes.fileTypeResource(forFileName: name)
    }
}

public enum MEGAAssetsImageName: String, CaseIterable, Sendable {
    case photoCardPlaceholder,
         enableCameraUploadsBannerIcon,
         cuBannerChevronRevamp,
         favouritesEmptyState,
         favouritePlaylistThumbnail = "FavouritePlaylistThumbnail",
         filetypeFolder = "filetype_folder",
         filetype3D = "filetype_3d",
         filetypeRaw = "filetype_raw",
         filetypeVideo = "filetype_video",
         filetypeAudio = "filetype_audio",
         filetypeCompressed = "filetype_compressed",
         filetypePhotoshop = "filetype_photoshop",
         filetypeWebLang = "filetype_web_lang",
         filetypeAfterEffects = "filetype_after_effects",
         filetypeIllustrator = "filetype_illustrator",
         filetypeText = "filetype_text",
         filetypeExecutable = "filetype_executable",
         filetypeVector = "filetype_vector",
         filetypeImages = "filetype_images",
         filetypeWebData = "filetype_web_data",
         filetypeWord = "filetype_word",
         filetypeCAD = "filetype_CAD",
         filetypeDmg = "filetype_dmg",
         filetypeFont = "filetype_font",
         filetypeSpreadsheet = "filetype_spreadsheet",
         filetypeIndesign = "filetype_indesign",
         filetypePowerpoint = "filetype_powerpoint",
         filetypeKeynote = "filetype_keynote",
         filetypeNumbers = "filetype_numbers",
         filetypeGeneric = "filetype_generic",
         filetypeOpenoffice = "filetype_openoffice",
         filetypeExcel = "filetype_excel",
         filetypePages = "filetype_pages",
         filetypePdf = "filetype_pdf",
         filetypePremiere = "filetype_premiere",
         filetypeSketch = "filetype_sketch",
         filetypeTorrent = "filetype_torrent",
         filetypeUrl = "filetype_url",
         filetypeExperiencedesign = "filetype_experiencedesign",
         filetypeFolderCamera = "filetype_folder_camera",
         videoList = "video_list",
         videoPlaylistThumbnailFallback = "videoPlaylistThumbnailFallbackImage",
         linked,
         linksSegmentControler,
         folderIncoming = "folder_incoming",
         folderOutgoing = "folder_outgoing",
         folderChat = "folder_chat",
         placeholder,
         rectangleVideoStack,
         rectangleVideoStackOutline,
         moreList,
         playlist,
         navigationBarAdd = "navigationbar_add",
         timeline,
         clockMediumThin,
         glassPlaylist,
         check,
         splashScreenMEGALogo,
         glassSearch,
         noteToSelf,
         noteToSelfSmall,
         noteToSelfBlue,
         sharedFiles,
         clearChatHistory,
         unArchiveChat,
         archiveChat,
         sharedFilesInfo,
         manageChatHistory,
         meetingLink
}
