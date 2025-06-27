import MEGAAssetsBundle
import SwiftUI
import UIKit

extension MEGAAssets {
    public struct Image {
        static func image(forAssetsFileType fileType: MEGAAssetsFileType) -> SwiftUI.Image {
            switch fileType {
            case .filetypeFolder: MEGAImageBundle.filetypeFolder
            case .filetype3D: MEGAImageBundle.filetype3D
            case .filetypeRaw: MEGAImageBundle.filetypeRaw
            case .filetypeVideo: MEGAImageBundle.filetypeVideo
            case .filetypeAudio: MEGAImageBundle.filetypeAudio
            case .filetypeCompressed: MEGAImageBundle.filetypeCompressed
            case .filetypePhotoshop: MEGAImageBundle.filetypePhotoshop
            case .filetypeWebLang: MEGAImageBundle.filetypeWebLang
            case .filetypeAfterEffects: MEGAImageBundle.filetypeAfterEffects
            case .filetypeIllustrator: MEGAImageBundle.filetypeIllustrator
            case .filetypeText: MEGAImageBundle.filetypeText
            case .filetypeExecutable: MEGAImageBundle.filetypeExecutable
            case .filetypeVector: MEGAImageBundle.filetypeVector
            case .filetypeImages: MEGAImageBundle.filetypeImages
            case .filetypeWebData: MEGAImageBundle.filetypeWebData
            case .filetypeWord: MEGAImageBundle.filetypeWord
            case .filetypeCAD: MEGAImageBundle.filetypeCAD
            case .filetypeDmg: MEGAImageBundle.filetypeDmg
            case .filetypeFont: MEGAImageBundle.filetypeFont
            case .filetypeSpreadsheet: MEGAImageBundle.filetypeSpreadsheet
            case .filetypeIndesign: MEGAImageBundle.filetypeIndesign
            case .filetypePowerpoint: MEGAImageBundle.filetypePowerpoint
            case .filetypeKeynote: MEGAImageBundle.filetypeKeynote
            case .filetypeNumbers: MEGAImageBundle.filetypeNumbers
            case .filetypeGeneric: MEGAImageBundle.filetypeGeneric
            case .filetypeOpenoffice: MEGAImageBundle.filetypeOpenoffice
            case .filetypeExcel: MEGAImageBundle.filetypeExcel
            case .filetypePages: MEGAImageBundle.filetypePages
            case .filetypePdf: MEGAImageBundle.filetypePdf
            case .filetypePremiere: MEGAImageBundle.filetypePremiere
            case .filetypeTorrent: MEGAImageBundle.filetypeTorrent
            case .filetypeUrl: MEGAImageBundle.filetypeUrl
            case .filetypeExperiencedesign: MEGAImageBundle.filetypeExperiencedesign
            case .filetypeFolderCamera: MEGAImageBundle.filetypeFolderCamera
            }
        }
        
        public static func image(named: String) -> SwiftUI.Image {
            SwiftUI.Image(named, bundle: Bundle.MEGAAssetsBundle)
        }
        
        public static func image(forFileExtension fileExtension: String) -> SwiftUI.Image {
            MEGAAssets.Image.image(forAssetsFileType: MEGAAssetsFileType(withFileExtension: fileExtension))
        }
        
        public static func image(forFileName fileName: String) -> SwiftUI.Image {
            MEGAAssets.Image.image(forAssetsFileType: MEGAAssetsFileType(withFileName: fileName))
        }
        
        public static var filetypeFolder: SwiftUI.Image { MEGAImageBundle.filetypeFolder }
        public static var megaLogoGrayscale: SwiftUI.Image { MEGAImageBundle.megaLogoGrayscale }
        public static var recentsEmptyState: SwiftUI.Image { MEGAImageBundle.recentsEmptyState }
        public static var favouritesEmptyState: SwiftUI.Image { MEGAImageBundle.favouritesEmptyState }
        public static var offlineEmptyState: SwiftUI.Image { MEGAImageBundle.offlineEmptyState }
        public static var filetypeGeneric: SwiftUI.Image { MEGAImageBundle.filetypeGeneric }
        public static var versioned: SwiftUI.Image { MEGAImageBundle.versioned }
        public static var recentUpload: SwiftUI.Image { MEGAImageBundle.recentUpload }
        public static var standardDisclosureIndicatorDesignToken: SwiftUI.Image { MEGAImageBundle.standardDisclosureIndicatorDesignToken }
        public static var restore: SwiftUI.Image { MEGAImageBundle.restore }
        public static var link: SwiftUI.Image { MEGAImageBundle.link }
        public static var offline: SwiftUI.Image { MEGAImageBundle.offline }
        public static var rubbishBin: SwiftUI.Image { MEGAImageBundle.rubbishBin }
        public static var noResultsDocuments: SwiftUI.Image { MEGAImageBundle.noResultsDocuments }
        public static var noResultsAudio: SwiftUI.Image { MEGAImageBundle.noResultsAudio }
        public static var noResultsVideo: SwiftUI.Image { MEGAImageBundle.noResultsVideo }
        public static var noResultsImages: SwiftUI.Image { MEGAImageBundle.noResultsImages }
        public static var noResultsFolders: SwiftUI.Image { MEGAImageBundle.noResultsFolders }
        public static var noResultsPresentations: SwiftUI.Image { MEGAImageBundle.noResultsPresentations }
        public static var noResultsArchives: SwiftUI.Image { MEGAImageBundle.noResultsArchives }
        public static var searchEmptyState: SwiftUI.Image { MEGAImageBundle.searchEmptyState }
        public static var turquoiseCheckmark: SwiftUI.Image { MEGAImageBundle.turquoiseCheckmark }
        public static var closeBanner: SwiftUI.Image { MEGAImageBundle.closeBanner }
        public static var upgradeToProPlan: SwiftUI.Image { MEGAImageBundle.upgradeToProPlan }
        public static var allPhotosEmptyState: SwiftUI.Image { MEGAImageBundle.allPhotosEmptyState }
        public static var videoEmptyState: SwiftUI.Image { MEGAImageBundle.videoEmptyState }
        public static var cameraEmptyState: SwiftUI.Image { MEGAImageBundle.cameraEmptyState }
        public static var info: SwiftUI.Image { MEGAImageBundle.info }
        public static var notificationCta: SwiftUI.Image { MEGAImageBundle.notificationCta }
        public static var cameraBackupsCta: SwiftUI.Image { MEGAImageBundle.cameraBackupsCta }
        public static var callControlCameraDisabled: SwiftUI.Image { MEGAImageBundle.callControlCameraDisabled }
        public static var callControlCameraEnabled: SwiftUI.Image { MEGAImageBundle.callControlCameraEnabled }
        public static var callControlMicDisabled: SwiftUI.Image { MEGAImageBundle.callControlMicDisabled }
        public static var callControlMicEnabled: SwiftUI.Image { MEGAImageBundle.callControlMicEnabled }
        public static var callControlSpeakerEnabled: SwiftUI.Image { MEGAImageBundle.callControlSpeakerEnabled }
        public static var callControlSpeakerDisabled: SwiftUI.Image { MEGAImageBundle.callControlSpeakerDisabled }
        public static var saveToPhotos: SwiftUI.Image { MEGAImageBundle.saveToPhotos }
        public static var capture: SwiftUI.Image { MEGAImageBundle.capture }
        public static var subscriptionFeatureCloud: SwiftUI.Image { MEGAImageBundle.subscriptionFeatureCloud }
        public static var subscriptionFeatureTransfers: SwiftUI.Image { MEGAImageBundle.subscriptionFeatureTransfers }
        public static var subscriptionFeatureVPN: SwiftUI.Image { MEGAImageBundle.subscriptionFeatureVPN }
        public static var subscriptionFeatureTransfersPWM: SwiftUI.Image { MEGAImageBundle.subscriptionFeatureTransfersPWM }
        public static var subscriptionImageHeader: SwiftUI.Image { MEGAImageBundle.subscriptionImageHeader }
        public static var subscriptionImageHeaderLandscape: SwiftUI.Image { MEGAImageBundle.subscriptionImageHeaderLandscape }
        public static var eyeOff: SwiftUI.Image { MEGAImageBundle.eyeOff }
        public static var eyeOffRegular: SwiftUI.Image { MEGAImageBundle.eyeOffRegular }
        public static var imagesRegular: SwiftUI.Image { MEGAImageBundle.imagesRegular }
        public static var eyeRegular: SwiftUI.Image { MEGAImageBundle.eyeRegular }
        public static var onboardingLock: SwiftUI.Image { MEGAImageBundle.onboardingLock }
        public static var occurrences: SwiftUI.Image { MEGAImageBundle.occurrences }
        public static var makeCallRoundToken: SwiftUI.Image { MEGAImageBundle.makeCallRoundToken }
        public static var edittext: SwiftUI.Image { MEGAImageBundle.edittext }
        public static var mutedChat: SwiftUI.Image { MEGAImageBundle.mutedChat }
        public static var speakerOnBluetooth: SwiftUI.Image { MEGAImageBundle.speakerOnBluetooth }
        public static var waitingRoomDeny: SwiftUI.Image { MEGAImageBundle.waitingRoomDeny }
        public static var waitingRoomAdmit: SwiftUI.Image { MEGAImageBundle.waitingRoomAdmit }
        public static var closeBannerButton: SwiftUI.Image { MEGAImageBundle.closeBannerButton }
        public static var closeCircle: SwiftUI.Image { MEGAImageBundle.closeCircle }
        public static var shareLink: SwiftUI.Image { MEGAImageBundle.shareLink }
        public static var joinMeeting2: SwiftUI.Image { MEGAImageBundle.joinMeeting2 }
        public static var startMeeting2: SwiftUI.Image { MEGAImageBundle.startMeeting2 }
        public static var editMeeting: SwiftUI.Image { MEGAImageBundle.editMeeting }
        public static var archiveChatMenu: SwiftUI.Image { MEGAImageBundle.archiveChatMenu }
        public static var noInternetEmptyState: SwiftUI.Image { MEGAImageBundle.noInternetEmptyState }
        public static var inviteToChatDesignToken: SwiftUI.Image { MEGAImageBundle.inviteToChatDesignToken }
        public static var check: SwiftUI.Image { MEGAImageBundle.check }
        public static var enableChatNotifications: SwiftUI.Image { MEGAImageBundle.enableChatNotifications }
        public static var cuStatusUploadSync: SwiftUI.Image { MEGAImageBundle.cuStatusUploadSync }
        public static var cuStatusUploadInProgressCheckMark: SwiftUI.Image { MEGAImageBundle.cuStatusUploadInProgressCheckMark }
        public static var cuStatusUploadCompleteGreenCheckMark: SwiftUI.Image { MEGAImageBundle.cuStatusUploadCompleteGreenCheckMark }
        public static var cuStatusUploadIdleCheckMark: SwiftUI.Image { MEGAImageBundle.cuStatusUploadIdleCheckMark }
        public static var cuStatusUploadWarningCheckMark: SwiftUI.Image { MEGAImageBundle.cuStatusUploadWarningCheckMark }
        public static var cuStatusEnable: SwiftUI.Image { MEGAImageBundle.cuStatusEnable }
        public static var cuStatusUpload: SwiftUI.Image { MEGAImageBundle.cuStatusUpload }
        public static var selectAllItems: SwiftUI.Image { MEGAImageBundle.selectAllItems }
        public static var enableCameraUploadsPhotoLibraryEmpty: SwiftUI.Image { MEGAImageBundle.enableCameraUploadsPhotoLibraryEmpty }
        public static var cloudEmptyState: SwiftUI.Image { MEGAImageBundle.cloudEmptyState }
        public static var rubbishEmptyState: SwiftUI.Image { MEGAImageBundle.rubbishEmptyState }
        public static var folderEmptyState: SwiftUI.Image { MEGAImageBundle.folderEmptyState }
        public static var `import`: SwiftUI.Image { MEGAImageBundle.import }
        public static var textfile: SwiftUI.Image { MEGAImageBundle.textfile }
        public static var newFolder: SwiftUI.Image { MEGAImageBundle.newFolder }
        public static var scanDocument: SwiftUI.Image { MEGAImageBundle.scanDocument }
        public static var chatEmptyStateNew: SwiftUI.Image { MEGAImageBundle.chatEmptyStateNew }
        public static var meetingsEmptyStateNew: SwiftUI.Image { MEGAImageBundle.meetingsEmptyStateNew }
        public static var newChatEmptyContacts: SwiftUI.Image { MEGAImageBundle.newChatEmptyContacts }
        public static var readOnlyChat: SwiftUI.Image { MEGAImageBundle.readOnlyChat }
        public static var moderator: SwiftUI.Image { MEGAImageBundle.moderator }
        public static var standard: SwiftUI.Image { MEGAImageBundle.standard }
        public static var startMeeting: SwiftUI.Image { MEGAImageBundle.startMeeting }
        public static var joinAMeeting: SwiftUI.Image { MEGAImageBundle.joinAMeeting }
        public static var scheduleMeeting: SwiftUI.Image { MEGAImageBundle.scheduleMeeting }
        public static var privateChat: SwiftUI.Image { MEGAImageBundle.privateChat }
        public static var markUnreadMenu: SwiftUI.Image { MEGAImageBundle.markUnreadMenu }
        public static var allowNonHostToAddParticipant: SwiftUI.Image { MEGAImageBundle.allowNonHostToAddParticipant }
        public static var enableWaitingRoom: SwiftUI.Image { MEGAImageBundle.enableWaitingRoom }
        public static var callControlSwitchCameraEnabled: SwiftUI.Image { MEGAImageBundle.callControlSwitchCameraEnabled }
        public static var callControlSwitchCameraDisabled: SwiftUI.Image { MEGAImageBundle.callControlSwitchCameraDisabled }
        public static var callControlEndCall: SwiftUI.Image { MEGAImageBundle.callControlEndCall }
        public static var callContextMenu: SwiftUI.Image { MEGAImageBundle.callContextMenu }
        public static var videoList: SwiftUI.Image { MEGAImageBundle.videoList }
        public static var videoPlaylistThumbnailFallback: SwiftUI.Image { MEGAImageBundle.videoPlaylistThumbnailFallback }
        public static var linked: SwiftUI.Image { MEGAImageBundle.linked }
        public static var linksSegmentControler: SwiftUI.Image { MEGAImageBundle.linksSegmentControler }
        public static var folderUsers: SwiftUI.Image { MEGAImageBundle.folderUsers }
        public static var folderChat: SwiftUI.Image { MEGAImageBundle.folderChat }
        public static var placeholder: SwiftUI.Image { MEGAImageBundle.placeholder }
        public static var rectangleVideoStack: SwiftUI.Image { MEGAImageBundle.rectangleVideoStack }
        public static var rectangleVideoStackOutline: SwiftUI.Image { MEGAImageBundle.rectangleVideoStackOutline }
        public static var moreList: SwiftUI.Image { MEGAImageBundle.moreList }
        public static var playlist: SwiftUI.Image { MEGAImageBundle.playlist }
        public static var navigationBarAdd: SwiftUI.Image { MEGAImageBundle.navigationBarAdd }
        public static var timeline: SwiftUI.Image { MEGAImageBundle.timeline }
        public static var clockMediumThin: SwiftUI.Image { MEGAImageBundle.clockMediumThin }
        public static var glassPlaylist: SwiftUI.Image { MEGAImageBundle.glassPlaylist }
        public static var splashScreenMEGALogo: SwiftUI.Image { MEGAImageBundle.splashScreenMEGALogo }
        public static var glassSearch: SwiftUI.Image { MEGAImageBundle.glassSearch }
        public static var noteToSelf: SwiftUI.Image { MEGAImageBundle.noteToSelf }
        public static var noteToSelfSmall: SwiftUI.Image { MEGAImageBundle.noteToSelfSmall }
        public static var noteToSelfBlue: SwiftUI.Image { MEGAImageBundle.noteToSelfBlue }
        public static var sharedFiles: SwiftUI.Image { MEGAImageBundle.sharedFiles }
        public static var clearChatHistory: SwiftUI.Image { MEGAImageBundle.clearChatHistory }
        public static var unArchiveChat: SwiftUI.Image { MEGAImageBundle.unArchiveChat }
        public static var archiveChat: SwiftUI.Image { MEGAImageBundle.archiveChat }
        public static var sharedFilesInfo: SwiftUI.Image { MEGAImageBundle.sharedFilesInfo }
        public static var manageChatHistory: SwiftUI.Image { MEGAImageBundle.manageChatHistory }
        public static var meetingLink: SwiftUI.Image { MEGAImageBundle.meetingLink }
        public static var onboardingCarousel1: SwiftUI.Image { MEGAImageBundle.onboardingCarousel1 }
        public static var onboardingCarousel2: SwiftUI.Image { MEGAImageBundle.onboardingCarousel2 }
        public static var onboardingCarousel3: SwiftUI.Image { MEGAImageBundle.onboardingCarousel3 }
        public static var onboardingCarousel4: SwiftUI.Image { MEGAImageBundle.onboardingCarousel4 }
        public static var photoCardPlaceholder: SwiftUI.Image { MEGAImageBundle.photoCardPlaceholder }
        public static var enableCameraUploadsBannerIcon: SwiftUI.Image { MEGAImageBundle.enableCameraUploadsBannerIcon }
        public static var cuBannerChevronRevamp: SwiftUI.Image { MEGAImageBundle.cuBannerChevronRevamp }
        public static var favouritePlaylistThumbnail: SwiftUI.Image { MEGAImageBundle.favouritePlaylistThumbnail }
        public static var filetypeWebData: SwiftUI.Image { MEGAImageBundle.filetypeWebData }
        public static var filetypeImages: SwiftUI.Image { MEGAImageBundle.filetypeImages }
        // MARK: - DeviceCenter
        public static var android: SwiftUI.Image { MEGAImageBundle.android }
        public static var drive: SwiftUI.Image { MEGAImageBundle.drive }
        public static var ios: SwiftUI.Image { MEGAImageBundle.ios }
        public static var mobile: SwiftUI.Image { MEGAImageBundle.mobile }
        public static var pc: SwiftUI.Image { MEGAImageBundle.pc }
        public static var pcLinux: SwiftUI.Image { MEGAImageBundle.pcLinux }
        public static var pcMac: SwiftUI.Image { MEGAImageBundle.pcMac }
        public static var pcWindows: SwiftUI.Image { MEGAImageBundle.pcWindows }
        public static var backupFolder: SwiftUI.Image { MEGAImageBundle.backupFolder }
        public static var cameraUploadsFolder: SwiftUI.Image { MEGAImageBundle.cameraUploadsFolder }
        public static var syncFolder: SwiftUI.Image { MEGAImageBundle.syncFolder }
        public static var attentionNeeded: SwiftUI.Image { MEGAImageBundle.attentionNeeded }
        public static var disabled: SwiftUI.Image { MEGAImageBundle.disabled }
        public static var error: SwiftUI.Image { MEGAImageBundle.error }
        public static var inactive: SwiftUI.Image { MEGAImageBundle.inactive }
        public static var noCameraUploads: SwiftUI.Image { MEGAImageBundle.noCameraUploads }
        public static var outOfQuota: SwiftUI.Image { MEGAImageBundle.outOfQuota }
        public static var paused: SwiftUI.Image { MEGAImageBundle.paused }
        public static var updating: SwiftUI.Image { MEGAImageBundle.updating }
        public static var upToDate: SwiftUI.Image { MEGAImageBundle.upToDate }
        public static var externalLink: SwiftUI.Image { MEGAImageBundle.externalLink }
        public static var arrowLeftMediumOutline: SwiftUI.Image { MEGAImageBundle.arrowLeftMediumOutline }
        public static var notificationsInMenu: SwiftUI.Image { MEGAImageBundle.notificationsInMenu }
        public static var proLitePlanInMenu: SwiftUI.Image { MEGAImageBundle.proLitePlanInMenu }
        public static var proOnePlanInMenu: SwiftUI.Image { MEGAImageBundle.proOnePlanInMenu }
        public static var proTwoPlanInMenu: SwiftUI.Image { MEGAImageBundle.proTwoPlanInMenu }
        public static var proThreePlanInMenu: SwiftUI.Image { MEGAImageBundle.proThreePlanInMenu }
        public static var otherPlansInMenu: SwiftUI.Image { MEGAImageBundle.otherPlansInMenu }
        public static var storageInMenu: SwiftUI.Image { MEGAImageBundle.storageInMenu }
        public static var contactsInMenu: SwiftUI.Image { MEGAImageBundle.contactsInMenu }
        public static var achievementsInMenu: SwiftUI.Image { MEGAImageBundle.achievementsInMenu }
        public static var sharedItemsInMenu: SwiftUI.Image { MEGAImageBundle.sharedItemsInMenu }
        public static var deviceCentreInMenu: SwiftUI.Image { MEGAImageBundle.deviceCentreInMenu }
        public static var transfersInMenu: SwiftUI.Image { MEGAImageBundle.transfersInMenu }
        public static var offlineFilesInMenu: SwiftUI.Image { MEGAImageBundle.offlineFilesInMenu }
        public static var rubbishBinInMenu: SwiftUI.Image { MEGAImageBundle.rubbishBinInMenu }
        public static var settingsInMenu: SwiftUI.Image { MEGAImageBundle.settingsInMenu }
        public static var vpnAppInMenu: SwiftUI.Image { MEGAImageBundle.vpnAppInMenu }
        public static var passAppInMenu: SwiftUI.Image { MEGAImageBundle.passAppInMenu }
        public static var transferItAppInMenu: SwiftUI.Image { MEGAImageBundle.transferItAppInMenu }
        public static var externalLinkInMenu: SwiftUI.Image { MEGAImageBundle.externalLinkInMenu }
    }
}

extension MEGAAssets {
    public struct UIImage {
        static func image(forAssetsFileType fileType: MEGAAssetsFileType) -> UIKit.UIImage {
            switch fileType {
            case .filetypeFolder: MEGAUIImageBundle.filetypeFolder
            case .filetype3D: MEGAUIImageBundle.filetype3D
            case .filetypeRaw: MEGAUIImageBundle.filetypeRaw
            case .filetypeVideo: MEGAUIImageBundle.filetypeVideo
            case .filetypeAudio: MEGAUIImageBundle.filetypeAudio
            case .filetypeCompressed: MEGAUIImageBundle.filetypeCompressed
            case .filetypePhotoshop: MEGAUIImageBundle.filetypePhotoshop
            case .filetypeWebLang: MEGAUIImageBundle.filetypeWebLang
            case .filetypeAfterEffects: MEGAUIImageBundle.filetypeAfterEffects
            case .filetypeIllustrator: MEGAUIImageBundle.filetypeIllustrator
            case .filetypeText: MEGAUIImageBundle.filetypeText
            case .filetypeExecutable: MEGAUIImageBundle.filetypeExecutable
            case .filetypeVector: MEGAUIImageBundle.filetypeVector
            case .filetypeImages: MEGAUIImageBundle.filetypeImages
            case .filetypeWebData: MEGAUIImageBundle.filetypeWebData
            case .filetypeWord: MEGAUIImageBundle.filetypeWord
            case .filetypeCAD: MEGAUIImageBundle.filetypeCAD
            case .filetypeDmg: MEGAUIImageBundle.filetypeDmg
            case .filetypeFont: MEGAUIImageBundle.filetypeFont
            case .filetypeSpreadsheet: MEGAUIImageBundle.filetypeSpreadsheet
            case .filetypeIndesign: MEGAUIImageBundle.filetypeIndesign
            case .filetypePowerpoint: MEGAUIImageBundle.filetypePowerpoint
            case .filetypeKeynote: MEGAUIImageBundle.filetypeKeynote
            case .filetypeNumbers: MEGAUIImageBundle.filetypeNumbers
            case .filetypeGeneric: MEGAUIImageBundle.filetypeGeneric
            case .filetypeOpenoffice: MEGAUIImageBundle.filetypeOpenoffice
            case .filetypeExcel: MEGAUIImageBundle.filetypeExcel
            case .filetypePages: MEGAUIImageBundle.filetypePages
            case .filetypePdf: MEGAUIImageBundle.filetypePdf
            case .filetypePremiere: MEGAUIImageBundle.filetypePremiere
            case .filetypeTorrent: MEGAUIImageBundle.filetypeTorrent
            case .filetypeUrl: MEGAUIImageBundle.filetypeUrl
            case .filetypeExperiencedesign: MEGAUIImageBundle.filetypeExperiencedesign
            case .filetypeFolderCamera: MEGAUIImageBundle.filetypeFolderCamera
            }
        }
        
        public static func image(named: String) -> UIKit.UIImage? {
            UIKit.UIImage(named: named, in: Bundle.MEGAAssetsBundle, with: nil)
        }
        
        public static func image(forFileExtension fileExtension: String) -> UIKit.UIImage {
            MEGAAssets.UIImage.image(forAssetsFileType: MEGAAssetsFileType(withFileExtension: fileExtension))
        }
        
        public static func image(forFileName fileName: String) -> UIKit.UIImage {
            MEGAAssets.UIImage.image(forAssetsFileType: MEGAAssetsFileType(withFileName: fileName))
        }
        
        public static var chatNotifications: UIKit.UIImage { MEGAUIImageBundle.chatNotifications }
        public static var iconContacts: UIKit.UIImage { MEGAUIImageBundle.iconContacts }
        public static var groupChatToken: UIKit.UIImage { MEGAUIImageBundle.groupChatToken }
        public static var newMeetingToken: UIKit.UIImage { MEGAUIImageBundle.newMeetingToken }
        public static var joinMeetingToken: UIKit.UIImage { MEGAUIImageBundle.joinMeetingToken }
        public static var inviteContactShare: UIKit.UIImage { MEGAUIImageBundle.inviteContactShare }
        public static var checkBoxSelectedSemantic: UIKit.UIImage { MEGAUIImageBundle.checkBoxSelectedSemantic }
        public static var checkBoxUnselected: UIKit.UIImage { MEGAUIImageBundle.checkBoxUnselected }
        public static var noteToSelfSmall: UIKit.UIImage { MEGAUIImageBundle.noteToSelfSmall }
        public static var noteToSelfBlue: UIKit.UIImage { MEGAUIImageBundle.noteToSelfBlue }
        public static var deviceStorageAlmostFull: UIKit.UIImage { MEGAUIImageBundle.deviceStorageAlmostFull }
        public static var hudDownload: UIKit.UIImage { MEGAUIImageBundle.hudDownload }
        public static var upload: UIKit.UIImage { MEGAUIImageBundle.upload }
        public static var sendToChat: UIKit.UIImage { MEGAUIImageBundle.sendToChat }
        public static var folderChat: UIKit.UIImage { MEGAUIImageBundle.folderChat }
        public static var filetypeFolderCamera: UIKit.UIImage { MEGAUIImageBundle.filetypeFolderCamera }
        public static var filetypeGeneric: UIKit.UIImage { MEGAUIImageBundle.filetypeGeneric }
        public static var folderUsers: UIKit.UIImage { MEGAUIImageBundle.folderUsers }
        public static var filetypeFolder: UIKit.UIImage { MEGAUIImageBundle.filetypeFolder }
        public static var export: UIKit.UIImage { MEGAUIImageBundle.export }
        public static var shareFolder: UIKit.UIImage { MEGAUIImageBundle.shareFolder }
        public static var verifyContact: UIKit.UIImage { MEGAUIImageBundle.verifyContact }
        public static var offline: UIKit.UIImage { MEGAUIImageBundle.offline }
        public static var info: UIKit.UIImage { MEGAUIImageBundle.info }
        public static var rename: UIKit.UIImage { MEGAUIImageBundle.rename }
        public static var copy: UIKit.UIImage { MEGAUIImageBundle.copy }
        public static var move: UIKit.UIImage { MEGAUIImageBundle.move }
        public static var rubbishBin: UIKit.UIImage { MEGAUIImageBundle.rubbishBin }
        public static var hudMinus: UIKit.UIImage { MEGAUIImageBundle.hudMinus }
        public static var leaveShare: UIKit.UIImage { MEGAUIImageBundle.leaveShare }
        public static var link: UIKit.UIImage { MEGAUIImageBundle.link }
        public static var removeLink: UIKit.UIImage { MEGAUIImageBundle.removeLink }
        public static var removeShare: UIKit.UIImage { MEGAUIImageBundle.removeShare }
        public static var search: UIKit.UIImage { MEGAUIImageBundle.search }
        public static var cancelTransfers: UIKit.UIImage { MEGAUIImageBundle.cancelTransfers }
        public static var `import`: UIKit.UIImage { MEGAUIImageBundle.import }
        public static var versions: UIKit.UIImage { MEGAUIImageBundle.versions }
        public static var history: UIKit.UIImage { MEGAUIImageBundle.history }
        public static var delete: UIKit.UIImage { MEGAUIImageBundle.delete }
        public static var selectItem: UIKit.UIImage { MEGAUIImageBundle.selectItem }
        public static var restore: UIKit.UIImage { MEGAUIImageBundle.restore }
        public static var saveToPhotos: UIKit.UIImage { MEGAUIImageBundle.saveToPhotos }
        public static var pageView: UIKit.UIImage { MEGAUIImageBundle.pageView }
        public static var thumbnailsThin: UIKit.UIImage { MEGAUIImageBundle.thumbnailsThin }
        public static var edittext: UIKit.UIImage { MEGAUIImageBundle.edittext }
        public static var forwardToolbar: UIKit.UIImage { MEGAUIImageBundle.forwardToolbar }
        public static var removeFavourite: UIKit.UIImage { MEGAUIImageBundle.removeFavourite }
        public static var favourite: UIKit.UIImage { MEGAUIImageBundle.favourite }
        public static var label: UIKit.UIImage { MEGAUIImageBundle.label }
        public static var gridThin: UIKit.UIImage { MEGAUIImageBundle.gridThin }
        public static var sort: UIKit.UIImage { MEGAUIImageBundle.sort }
        public static var disputeTakedown: UIKit.UIImage { MEGAUIImageBundle.disputeTakedown }
        public static var mediaDiscovery: UIKit.UIImage { MEGAUIImageBundle.mediaDiscovery }
        public static var helpCircleThinMedium: UIKit.UIImage { MEGAUIImageBundle.helpCircleThinMedium }
        public static var eyeOff: UIKit.UIImage { MEGAUIImageBundle.eyeOff }
        public static var eyeOn: UIKit.UIImage { MEGAUIImageBundle.eyeOn }
        public static var addTo: UIKit.UIImage { MEGAUIImageBundle.addTo }
        public static var standardDisclosureIndicator: UIKit.UIImage { MEGAUIImageBundle.standardDisclosureIndicator }
        public static var hudSuccess: UIKit.UIImage { MEGAUIImageBundle.hudSuccess }
        public static var hudError: UIKit.UIImage { MEGAUIImageBundle.hudError }
        public static var backArrow: UIKit.UIImage { MEGAUIImageBundle.backArrow }
        public static var moreNavigationBar: UIKit.UIImage { MEGAUIImageBundle.moreNavigationBar }
        public static var openSettings: UIKit.UIImage { MEGAUIImageBundle.openSettings }
        public static var tapNotifications: UIKit.UIImage { MEGAUIImageBundle.tapNotifications }
        public static var tapMega: UIKit.UIImage { MEGAUIImageBundle.tapMega }
        public static var allowNotifications: UIKit.UIImage { MEGAUIImageBundle.allowNotifications }
        public static var groupChat: UIKit.UIImage { MEGAUIImageBundle.groupChat }
        public static var turquoiseCheckmark: UIKit.UIImage { MEGAUIImageBundle.turquoiseCheckmark }
        public static var miniplayerClose: UIKit.UIImage { MEGAUIImageBundle.miniplayerClose }
        public static var moreList: UIKit.UIImage { MEGAUIImageBundle.moreList }
        public static var videoList: UIKit.UIImage { MEGAUIImageBundle.videoList }
        public static var downloaded: UIKit.UIImage { MEGAUIImageBundle.downloaded }
        public static var moreGrid: UIKit.UIImage { MEGAUIImageBundle.moreGrid }
        public static var shuffleAudio: UIKit.UIImage { MEGAUIImageBundle.shuffleAudio }
        public static var newest: UIKit.UIImage { MEGAUIImageBundle.newest }
        public static var oldest: UIKit.UIImage { MEGAUIImageBundle.oldest }
        public static var cameraUploadsSettings: UIKit.UIImage { MEGAUIImageBundle.cameraUploadsSettings }
        public static var chatSettings: UIKit.UIImage { MEGAUIImageBundle.chatSettings }
        public static var callsSettings: UIKit.UIImage { MEGAUIImageBundle.callsSettings }
        public static var securitySettings: UIKit.UIImage { MEGAUIImageBundle.securitySettings }
        public static var userInterfaceSettings: UIKit.UIImage { MEGAUIImageBundle.userInterfaceSettings }
        public static var fileManagementSettings: UIKit.UIImage { MEGAUIImageBundle.fileManagementSettings }
        public static var advancedSettings: UIKit.UIImage { MEGAUIImageBundle.advancedSettings }
        public static var helpSettings: UIKit.UIImage { MEGAUIImageBundle.helpSettings }
        public static var aboutSettings: UIKit.UIImage { MEGAUIImageBundle.aboutSettings }
        public static var termsAndPoliciesSettings: UIKit.UIImage { MEGAUIImageBundle.termsAndPoliciesSettings }
        public static var cookieSettings: UIKit.UIImage { MEGAUIImageBundle.cookieSettings }
        public static var iconSettings: UIKit.UIImage { MEGAUIImageBundle.iconSettings }
        public static var isTakedown: UIKit.UIImage { MEGAUIImageBundle.isTakedown }
        public static var warningPermission: UIKit.UIImage { MEGAUIImageBundle.warningPermission }
        public static var searchEmptyState: UIKit.UIImage { MEGAUIImageBundle.searchEmptyState }
        public static var incomingEmptyState: UIKit.UIImage { MEGAUIImageBundle.incomingEmptyState }
        public static var outgoingEmptyState: UIKit.UIImage { MEGAUIImageBundle.outgoingEmptyState }
        public static var linksEmptyState: UIKit.UIImage { MEGAUIImageBundle.linksEmptyState }
        public static var noInternetEmptyState: UIKit.UIImage { MEGAUIImageBundle.noInternetEmptyState }
        public static var lockedAccounts: UIKit.UIImage { MEGAUIImageBundle.lockedAccounts }
        public static var noResultsVideoV2: UIKit.UIImage { MEGAUIImageBundle.noResultsVideoV2 }
        public static var filterChipDownArrow: UIKit.UIImage { MEGAUIImageBundle.filterChipDownArrow }
        public static var favouriteThumbnail: UIKit.UIImage { MEGAUIImageBundle.favouriteThumbnail }
        public static var blackPlayButton: UIKit.UIImage { MEGAUIImageBundle.blackPlayButton }
        public static var linked: UIKit.UIImage { MEGAUIImageBundle.linked }
        public static var navigationbarAdd: UIKit.UIImage { MEGAUIImageBundle.navigationbarAdd }
        public static var rectangleVideoStack: UIKit.UIImage { MEGAUIImageBundle.rectangleVideoStack }
        public static var favouritePlaylistThumbnail: UIKit.UIImage { MEGAUIImageBundle.favouritePlaylistThumbnail }
        public static var grabberIcon: UIKit.UIImage { MEGAUIImageBundle.grabberIcon }
        public static var redSmall: UIKit.UIImage { MEGAUIImageBundle.redSmall }
        public static var orangeSmall: UIKit.UIImage { MEGAUIImageBundle.orangeSmall }
        public static var yellowSmall: UIKit.UIImage { MEGAUIImageBundle.yellowSmall }
        public static var greenSmall: UIKit.UIImage { MEGAUIImageBundle.greenSmall }
        public static var blueSmall: UIKit.UIImage { MEGAUIImageBundle.blueSmall }
        public static var purpleSmall: UIKit.UIImage { MEGAUIImageBundle.purpleSmall }
        public static var greySmall: UIKit.UIImage { MEGAUIImageBundle.greySmall }
        public static var recentlyWatchedVideosEmptyState: UIKit.UIImage { MEGAUIImageBundle.recentlyWatchedVideosEmptyState }
        public static var selectAllItems: UIKit.UIImage { MEGAUIImageBundle.selectAllItems }
        public static var clockPlay: UIKit.UIImage { MEGAUIImageBundle.clockPlay }
        public static var ascending: UIKit.UIImage { MEGAUIImageBundle.ascending }
        public static var descending: UIKit.UIImage { MEGAUIImageBundle.descending }
        public static var largest: UIKit.UIImage { MEGAUIImageBundle.largest }
        public static var smallest: UIKit.UIImage { MEGAUIImageBundle.smallest }
        public static var sortLabel: UIKit.UIImage { MEGAUIImageBundle.sortLabel }
        public static var sortFavourite: UIKit.UIImage { MEGAUIImageBundle.sortFavourite }
        public static var standardDisclosureIndicatorDesignToken: UIKit.UIImage { MEGAUIImageBundle.standardDisclosureIndicatorDesignToken }
        public static var verificationCountry: UIKit.UIImage { MEGAUIImageBundle.verificationCountry }
        public static var phoneNumber: UIKit.UIImage { MEGAUIImageBundle.phoneNumber }
        public static var spotlightFile: UIKit.UIImage { MEGAUIImageBundle.spotlightFile }
        public static var defaultArtwork: UIKit.UIImage { MEGAUIImageBundle.defaultArtwork }
        public static var filterActive: UIKit.UIImage { MEGAUIImageBundle.filterActive }
        public static var moreActionActiveNavigationBar: UIKit.UIImage { MEGAUIImageBundle.moreActionActiveNavigationBar }
        public static var allPhotosEmptyState: UIKit.UIImage { MEGAUIImageBundle.allPhotosEmptyState }
        public static var cameraEmptyState: UIKit.UIImage { MEGAUIImageBundle.cameraEmptyState }
        public static var videoEmptyState: UIKit.UIImage { MEGAUIImageBundle.videoEmptyState }
        public static var spotlightFolder: UIKit.UIImage { MEGAUIImageBundle.spotlightFolder }
        public static var addReactionSmall: UIKit.UIImage { MEGAUIImageBundle.addReactionSmall }
        public static var versioned: UIKit.UIImage { MEGAUIImageBundle.versioned }
        public static var recentUpload: UIKit.UIImage { MEGAUIImageBundle.recentUpload }
        public static var transfersDownload: UIKit.UIImage { MEGAUIImageBundle.transfersDownload }
        public static var completedBadgeDesignToken: UIKit.UIImage { MEGAUIImageBundle.completedBadgeDesignToken }
        public static var errorBadgeDesignToken: UIKit.UIImage { MEGAUIImageBundle.errorBadgeDesignToken }
        public static var overquotaDesignToken: UIKit.UIImage { MEGAUIImageBundle.overquotaDesignToken }
        public static var pauseDesignToken: UIKit.UIImage { MEGAUIImageBundle.pauseDesignToken }
        public static var transfersDownloadDesignToken: UIKit.UIImage { MEGAUIImageBundle.transfersDownloadDesignToken }
        public static var transfersUploadDesignToken: UIKit.UIImage { MEGAUIImageBundle.transfersUploadDesignToken }
        public static var fullAccessPermissions: UIKit.UIImage { MEGAUIImageBundle.fullAccessPermissions }
        public static var readWritePermissions: UIKit.UIImage { MEGAUIImageBundle.readWritePermissions }
        public static var readPermissions: UIKit.UIImage { MEGAUIImageBundle.readPermissions }
        public static var contactRequestDeny: UIKit.UIImage { MEGAUIImageBundle.contactRequestDeny }
        public static var contactRequestAccept: UIKit.UIImage { MEGAUIImageBundle.contactRequestAccept }
        public static var disclosure: UIKit.UIImage { MEGAUIImageBundle.disclosure }
        public static var voiceTip: UIKit.UIImage { MEGAUIImageBundle.voiceTip }
        public static var folderEmptyState: UIKit.UIImage { MEGAUIImageBundle.folderEmptyState }
        public static var cloudDriveIcon: UIKit.UIImage { MEGAUIImageBundle.cloudDriveIcon }
        public static var cameraUploadsIcon: UIKit.UIImage { MEGAUIImageBundle.cameraUploadsIcon }
        public static var miniplayerPause: UIKit.UIImage { MEGAUIImageBundle.miniplayerPause }
        public static var miniplayerPlay: UIKit.UIImage { MEGAUIImageBundle.miniplayerPlay }
        public static var sendButton: UIKit.UIImage { MEGAUIImageBundle.sendButton }
        public static var expand: UIKit.UIImage { MEGAUIImageBundle.expand }
        public static var checkBoxSelected: UIKit.UIImage { MEGAUIImageBundle.checkBoxSelected }
        public static var home: UIKit.UIImage { MEGAUIImageBundle.home }
        public static var chatIcon: UIKit.UIImage { MEGAUIImageBundle.chatIcon }
        public static var sharedItemsIcon: UIKit.UIImage { MEGAUIImageBundle.sharedItemsIcon }
        public static var collapse: UIKit.UIImage { MEGAUIImageBundle.collapse }
        public static var textfile: UIKit.UIImage { MEGAUIImageBundle.textfile }
        public static var capture: UIKit.UIImage { MEGAUIImageBundle.capture }
        public static var scanDocument: UIKit.UIImage { MEGAUIImageBundle.scanDocument }
        public static var explorerCardFavourites: UIKit.UIImage { MEGAUIImageBundle.explorerCardFavourites }
        public static var explorerCardDocs: UIKit.UIImage { MEGAUIImageBundle.explorerCardDocs }
        public static var explorerCardAudio: UIKit.UIImage { MEGAUIImageBundle.explorerCardAudio }
        public static var explorerCardVideoPlayBlue: UIKit.UIImage { MEGAUIImageBundle.explorerCardVideoPlayBlue }
        public static var explorerCardVideoFilmStripsBlue: UIKit.UIImage { MEGAUIImageBundle.explorerCardVideoFilmStripsBlue }
        public static var infoMeetings: UIKit.UIImage { MEGAUIImageBundle.infoMeetings }
        public static var storage: UIKit.UIImage { MEGAUIImageBundle.storage }
        public static var fileSharing: UIKit.UIImage { MEGAUIImageBundle.fileSharing }
        public static var backup: UIKit.UIImage { MEGAUIImageBundle.backup }
        public static var mega: UIKit.UIImage { MEGAUIImageBundle.mega }
        public static var onboardingHeader: UIKit.UIImage { MEGAUIImageBundle.onboardingHeader }
        public static var blockingDiskFull: UIKit.UIImage { MEGAUIImageBundle.blockingDiskFull }
        public static var placeholder: UIKit.UIImage { MEGAUIImageBundle.placeholder }
        public static var linkGetLink: UIKit.UIImage { MEGAUIImageBundle.linkGetLink }
        public static var iconKeyOnly: UIKit.UIImage { MEGAUIImageBundle.iconKeyOnly }
        public static var addFromContacts: UIKit.UIImage { MEGAUIImageBundle.addFromContacts }
        public static var enterUserEmail: UIKit.UIImage { MEGAUIImageBundle.enterUserEmail }
        public static var scanUserQRCode: UIKit.UIImage { MEGAUIImageBundle.scanUserQRCode }
        public static var inviteContactMore: UIKit.UIImage { MEGAUIImageBundle.inviteContactMore }
        public static var megaShareContactLink: UIKit.UIImage { MEGAUIImageBundle.megaShareContactLink }
        public static var cameraIconWhite: UIKit.UIImage { MEGAUIImageBundle.cameraIconWhite }
        public static var cameraIcon: UIKit.UIImage { MEGAUIImageBundle.cameraIcon }
        public static var sendChatDisabled: UIKit.UIImage { MEGAUIImageBundle.sendChatDisabled }
        public static var userMutedBanner: UIKit.UIImage { MEGAUIImageBundle.userMutedBanner }
        public static var callSlotsBanner: UIKit.UIImage { MEGAUIImageBundle.callSlotsBanner }
        public static var accountExpiredAdmin: UIKit.UIImage { MEGAUIImageBundle.accountExpiredAdmin }
        public static var accountExpiredUser: UIKit.UIImage { MEGAUIImageBundle.accountExpiredUser }
        public static var red: UIKit.UIImage { MEGAUIImageBundle.red }
        public static var orange: UIKit.UIImage { MEGAUIImageBundle.orange }
        public static var yellow: UIKit.UIImage { MEGAUIImageBundle.yellow }
        public static var green: UIKit.UIImage { MEGAUIImageBundle.green }
        public static var blue: UIKit.UIImage { MEGAUIImageBundle.blue }
        public static var purple: UIKit.UIImage { MEGAUIImageBundle.purple }
        public static var grey: UIKit.UIImage { MEGAUIImageBundle.grey }
        public static var contactRequests: UIKit.UIImage { MEGAUIImageBundle.contactRequests }
        public static var chatEmptyState: UIKit.UIImage { MEGAUIImageBundle.chatEmptyState }
        public static var moderator: UIKit.UIImage { MEGAUIImageBundle.moderator }
        public static var standard: UIKit.UIImage { MEGAUIImageBundle.standard }
        public static var readOnlyChat: UIKit.UIImage { MEGAUIImageBundle.readOnlyChat }
        public static var sendMessageRoundToken: UIKit.UIImage { MEGAUIImageBundle.sendMessageRoundToken }
        public static var groupAvatar: UIKit.UIImage { MEGAUIImageBundle.groupAvatar }
        public static var newFolder: UIKit.UIImage { MEGAUIImageBundle.newFolder }
        public static var filter: UIKit.UIImage { MEGAUIImageBundle.filter }
        public static var startMeeting: UIKit.UIImage { MEGAUIImageBundle.startMeeting }
        public static var joinAMeeting: UIKit.UIImage { MEGAUIImageBundle.joinAMeeting }
        public static var scheduleMeeting: UIKit.UIImage { MEGAUIImageBundle.scheduleMeeting }
        public static var deleteVideoPlaylist: UIKit.UIImage { MEGAUIImageBundle.deleteVideoPlaylist }
        public static var favicon: UIKit.UIImage { MEGAUIImageBundle.favicon }
        public static var privacyWarningIco: UIKit.UIImage { MEGAUIImageBundle.privacyWarningIco }
        public static var clearChatHistory: UIKit.UIImage { MEGAUIImageBundle.clearChatHistory }
        public static var searchBarIconSemantic: UIKit.UIImage { MEGAUIImageBundle.searchBarIconSemantic }
        public static var downloadGif: UIKit.UIImage { MEGAUIImageBundle.downloadGif }
        public static var playButton: UIKit.UIImage { MEGAUIImageBundle.playButton }
        public static var addContact: UIKit.UIImage { MEGAUIImageBundle.addContact }
        public static var giphyCellBackground: UIKit.UIImage { MEGAUIImageBundle.giphyCellBackground }
        public static var noGIF: UIKit.UIImage { MEGAUIImageBundle.noGIF }
        public static var poweredByGIPHY: UIKit.UIImage { MEGAUIImageBundle.poweredByGIPHY }
        public static var leaveGroup: UIKit.UIImage { MEGAUIImageBundle.leaveGroup }
        public static var groupChatAddParticipant: UIKit.UIImage { MEGAUIImageBundle.groupChatAddParticipant }
        public static var contactGroups: UIKit.UIImage { MEGAUIImageBundle.contactGroups }
        public static var selectAlbumCover: UIKit.UIImage { MEGAUIImageBundle.selectAlbumCover }
        public static var deleteAlbum: UIKit.UIImage { MEGAUIImageBundle.deleteAlbum }
        public static var versionedThumbnail: UIKit.UIImage { MEGAUIImageBundle.versionedThumbnail }
        public static var linkedThumbnail: UIKit.UIImage { MEGAUIImageBundle.linkedThumbnail }
        public static var proLabel: UIKit.UIImage { MEGAUIImageBundle.proLabel }
        public static var hudForbidden: UIKit.UIImage { MEGAUIImageBundle.hudForbidden }
        public static var plan: UIKit.UIImage { MEGAUIImageBundle.plan }
        public static var iconStorage: UIKit.UIImage { MEGAUIImageBundle.iconStorage }
        public static var myAccount: UIKit.UIImage { MEGAUIImageBundle.myAccount }
        public static var iconNotifications: UIKit.UIImage { MEGAUIImageBundle.iconNotifications }
        public static var iconTransfers: UIKit.UIImage { MEGAUIImageBundle.iconTransfers }
        public static var iconAchievements: UIKit.UIImage { MEGAUIImageBundle.iconAchievements }
        public static var deviceCenter: UIKit.UIImage { MEGAUIImageBundle.deviceCenter }
        public static var iconOffline: UIKit.UIImage { MEGAUIImageBundle.iconOffline }
        public static var businessPaymentOverdue: UIKit.UIImage { MEGAUIImageBundle.businessPaymentOverdue }
        public static var favouritesEmptyState: UIKit.UIImage { MEGAUIImageBundle.favouritesEmptyState }
        public static var documentsEmptyState: UIKit.UIImage { MEGAUIImageBundle.documentsEmptyState }
        public static var audioEmptyState: UIKit.UIImage { MEGAUIImageBundle.audioEmptyState }
        public static var waveform0000: UIKit.UIImage { MEGAUIImageBundle.waveform0000 }
        public static var playVoiceClip: UIKit.UIImage { MEGAUIImageBundle.playVoiceClip }
        public static var pauseVoiceClip: UIKit.UIImage { MEGAUIImageBundle.pauseVoiceClip }
        public static var playVoiceClipButton: UIKit.UIImage { MEGAUIImageBundle.playVoiceClipButton }
        public static var closeCircle: UIKit.UIImage { MEGAUIImageBundle.closeCircle }
        public static var inviteToChatDesignToken: UIKit.UIImage { MEGAUIImageBundle.inviteToChatDesignToken }
        public static var archiveChat: UIKit.UIImage { MEGAUIImageBundle.archiveChat }
        public static var markUnreadMenu: UIKit.UIImage { MEGAUIImageBundle.markUnreadMenu }
        public static var mutedChatMenu: UIKit.UIImage { MEGAUIImageBundle.mutedChatMenu }
        public static var callControlSpeakerDisabled: UIKit.UIImage { MEGAUIImageBundle.callControlSpeakerDisabled }
        public static var audioSourceMeetingAction: UIKit.UIImage { MEGAUIImageBundle.audioSourceMeetingAction }
        public static var callControlSpeakerEnabled: UIKit.UIImage { MEGAUIImageBundle.callControlSpeakerEnabled }
        public static var chatLinkCreation: UIKit.UIImage { MEGAUIImageBundle.chatLinkCreation }
        public static var sharedFilesEmptyState: UIKit.UIImage { MEGAUIImageBundle.sharedFilesEmptyState }
        public static var contactInviteSent: UIKit.UIImage { MEGAUIImageBundle.contactInviteSent }
        public static var cookie: UIKit.UIImage { MEGAUIImageBundle.cookie }
        public static var verifyPendingOutshareEmail: UIKit.UIImage { MEGAUIImageBundle.verifyPendingOutshareEmail }
        public static var changeLaunchTab: UIKit.UIImage { MEGAUIImageBundle.changeLaunchTab }
        public static var storageAlmostFull: UIKit.UIImage { MEGAUIImageBundle.storageAlmostFull }
        public static var warningStorageFull: UIKit.UIImage { MEGAUIImageBundle.warningStorageFull  }
        public static var transferLimitedQuota: UIKit.UIImage { MEGAUIImageBundle.transferLimitedQuota }
        public static var transferExceededQuota: UIKit.UIImage { MEGAUIImageBundle.transferExceededQuota }
        public static var _2FASetup: UIKit.UIImage { MEGAUIImageBundle._2FASetup }
        public static var accountUpgradeSecurity: UIKit.UIImage { MEGAUIImageBundle.accountUpgradeSecurity }
        public static var upgradePro: UIKit.UIImage { MEGAUIImageBundle.upgradePro }
        public static var startChat: UIKit.UIImage { MEGAUIImageBundle.startChat }
        public static var uploadFile: UIKit.UIImage { MEGAUIImageBundle.uploadFile }
        public static var phoneCallAll: UIKit.UIImage { MEGAUIImageBundle.phoneCallAll }
        public static var userMicOn: UIKit.UIImage { MEGAUIImageBundle.userMicOn }
        public static var userMutedMeetings: UIKit.UIImage { MEGAUIImageBundle.userMutedMeetings }
        public static var callSlots: UIKit.UIImage { MEGAUIImageBundle.callSlots }
        public static var videoOff: UIKit.UIImage { MEGAUIImageBundle.videoOff }
        public static var sendMessageMeetings: UIKit.UIImage { MEGAUIImageBundle.sendMessageMeetings }
        public static var moderatorMeetings: UIKit.UIImage { MEGAUIImageBundle.moderatorMeetings }
        public static var removeModerator: UIKit.UIImage { MEGAUIImageBundle.removeModerator }
        public static var speakerView: UIKit.UIImage { MEGAUIImageBundle.speakerView }
        public static var muteParticipant: UIKit.UIImage { MEGAUIImageBundle.muteParticipant }
        public static var share: UIKit.UIImage { MEGAUIImageBundle.share }
        public static var callControlSwitchCameraEnabled: UIKit.UIImage { MEGAUIImageBundle.callControlSwitchCameraEnabled }
        public static var callControlSwitchCameraDisabled: UIKit.UIImage { MEGAUIImageBundle.callControlSwitchCameraDisabled }
        public static var shareCallLink: UIKit.UIImage { MEGAUIImageBundle.shareCallLink }
        public static var galleryView: UIKit.UIImage { MEGAUIImageBundle.galleryView }
        public static var micActive: UIKit.UIImage { MEGAUIImageBundle.micActive }
        public static var micMuted: UIKit.UIImage { MEGAUIImageBundle.micMuted }
        public static var jumpToLatest: UIKit.UIImage { MEGAUIImageBundle.jumpToLatest }
        public static var audioCall: UIKit.UIImage { MEGAUIImageBundle.audioCall }
        public static var videoCall: UIKit.UIImage { MEGAUIImageBundle.videoCall }
        public static var megaIconCall: UIKit.UIImage { MEGAUIImageBundle.megaIconCall }
        public static var triangle: UIKit.UIImage { MEGAUIImageBundle.triangle }
        public static var forwardButton: UIKit.UIImage { MEGAUIImageBundle.forwardButton }
        public static var pause: UIKit.UIImage { MEGAUIImageBundle.pause }
        public static var play: UIKit.UIImage { MEGAUIImageBundle.play }
        public static var repeatAudio: UIKit.UIImage { MEGAUIImageBundle.repeatAudio }
        public static var repeatOneAudio: UIKit.UIImage { MEGAUIImageBundle.repeatOneAudio }
        public static var normal: UIKit.UIImage { MEGAUIImageBundle.normal }
        public static var double: UIKit.UIImage { MEGAUIImageBundle.double }
        public static var half: UIKit.UIImage { MEGAUIImageBundle.half }
        public static var oneAndAHalf: UIKit.UIImage { MEGAUIImageBundle.oneAndAHalf }
        public static var lock: UIKit.UIImage { MEGAUIImageBundle.lock }
        public static var callRaiseHand: UIKit.UIImage { MEGAUIImageBundle.callRaiseHand }
        public static var callWithXIncoming: UIKit.UIImage { MEGAUIImageBundle.callWithXIncoming }
        public static var chatroomLoading: UIKit.UIImage { MEGAUIImageBundle.chatroomLoading }
        public static var locationMessage: UIKit.UIImage { MEGAUIImageBundle.locationMessage }
        public static var locationMessageGrey: UIKit.UIImage { MEGAUIImageBundle.locationMessageGrey }
        public static var voiceMessage: UIKit.UIImage { MEGAUIImageBundle.voiceMessage }
        public static var voiceMessageGrey: UIKit.UIImage { MEGAUIImageBundle.voiceMessageGrey }
        public static var activitySendToChat: UIKit.UIImage { MEGAUIImageBundle.activitySendToChat }
        public static var notificationDevicePermission: UIKit.UIImage { MEGAUIImageBundle.notificationDevicePermission }
        public static var glassSearch: UIKit.UIImage { MEGAUIImageBundle.glassSearch }
        public static var addContactMeetings: UIKit.UIImage { MEGAUIImageBundle.addContactMeetings }
        public static var achievementsFreeTrialVPN: UIKit.UIImage { MEGAUIImageBundle.achievementsFreeTrialVPN }
        public static var achievementsFreeTrialPass: UIKit.UIImage { MEGAUIImageBundle.achievementsFreeTrialPass }
        public static var tabBarHome: UIKit.UIImage { MEGAUIImageBundle.tabBarHome }
        public static var tabBarDrive: UIKit.UIImage { MEGAUIImageBundle.tabBarDrive }
        public static var tabBarPhotos: UIKit.UIImage { MEGAUIImageBundle.tabBarPhotos }
        public static var tabBarChat: UIKit.UIImage { MEGAUIImageBundle.tabBarChat }
        public static var tabBarMenu: UIKit.UIImage { MEGAUIImageBundle.tabBarMenu }
    }
}
