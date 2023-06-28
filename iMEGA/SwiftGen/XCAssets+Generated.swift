// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif

// Deprecated typealiases
@available(*, deprecated, renamed: "ImageAsset.Image", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetImageTypeAlias = ImageAsset.Image

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
internal enum Asset {
  internal enum Images {
    internal enum _3DTouchQuickActions {
      internal static let quickActionOffline = ImageAsset(name: "quickActionOffline")
      internal static let quickActionSearch = ImageAsset(name: "quickActionSearch")
      internal static let quickActionUpload = ImageAsset(name: "quickActionUpload")
    }
    internal enum Achievements {
      internal static let achievementsCheck = ImageAsset(name: "achievementsCheck")
      internal static let achievementsInstallMega = ImageAsset(name: "achievementsInstallMega")
      internal static let achievementsInstallMobile = ImageAsset(name: "achievementsInstallMobile")
      internal static let achievementsRegistration = ImageAsset(name: "achievementsRegistration")
      internal static let inviteFriends = ImageAsset(name: "inviteFriends")
      internal static let inviteFriendsButton = ImageAsset(name: "inviteFriendsButton")
    }
    internal enum ActionSheetIcons {
      internal enum ChatPermissions {
        internal static let moderator = ImageAsset(name: "moderator")
        internal static let readOnlyChat = ImageAsset(name: "readOnly_chat")
        internal static let standard = ImageAsset(name: "standard")
      }
      internal enum SortBy {
        internal static let ascending = ImageAsset(name: "ascending")
        internal static let descending = ImageAsset(name: "descending")
        internal static let largest = ImageAsset(name: "largest")
        internal static let newest = ImageAsset(name: "newest")
        internal static let oldest = ImageAsset(name: "oldest")
        internal static let smallest = ImageAsset(name: "smallest")
        internal static let sortFavourite = ImageAsset(name: "sortFavourite")
        internal static let sortLabel = ImageAsset(name: "sortLabel")
      }
      internal static let capture = ImageAsset(name: "capture")
      internal static let filter = ImageAsset(name: "filter")
      internal static let filterActive = ImageAsset(name: "filterActive")
      internal static let gridThin = ImageAsset(name: "gridThin")
      internal static let mediaDiscovery = ImageAsset(name: "mediaDiscovery")
      internal static let newFolder = ImageAsset(name: "newFolder")
      internal static let scanDocument = ImageAsset(name: "scanDocument")
      internal static let select = ImageAsset(name: "select")
      internal enum Sendtochat {
        internal static let fromCloudDrive = ImageAsset(name: "fromCloudDrive")
        internal static let sendContact = ImageAsset(name: "sendContact")
        internal static let sendLocation = ImageAsset(name: "sendLocation")
      }
      internal static let sort = ImageAsset(name: "sort")
      internal static let thumbnailsThin = ImageAsset(name: "thumbnailsThin")
      internal static let upload = ImageAsset(name: "upload")
      internal static let verifyContact = ImageAsset(name: "verifyContact")
    }
    internal enum Activities {
      internal static let activityGetLink = ImageAsset(name: "activity_getLink")
      internal static let activityOpenIn = ImageAsset(name: "activity_openIn")
      internal static let activitySaveImage = ImageAsset(name: "activity_saveImage")
      internal static let activitySendToChat = ImageAsset(name: "activity_sendToChat")
      internal static let activityShareFolder = ImageAsset(name: "activity_shareFolder")
    }
    internal enum Album {
      internal static let deleteAlbum = ImageAsset(name: "deleteAlbum")
      internal static let placeholder = ImageAsset(name: "placeholder")
      internal static let selectAlbumCover = ImageAsset(name: "selectAlbumCover")
    }
    internal enum AppIcons {
      internal static let altIconDay = ImageAsset(name: "altIconDay")
      internal static let altIconMinimal = ImageAsset(name: "altIconMinimal")
      internal static let altIconNight = ImageAsset(name: "altIconNight")
      internal static let defaultIcon = ImageAsset(name: "defaultIcon")
      internal static let iconSelectorBackground = ImageAsset(name: "iconSelectorBackground")
    }
    internal enum AudioPlayer {
      internal enum MiniPlayer {
        internal static let miniplayerClose = ImageAsset(name: "miniplayerClose")
        internal static let miniplayerPause = ImageAsset(name: "miniplayerPause")
        internal static let miniplayerPlay = ImageAsset(name: "miniplayerPlay")
      }
      internal enum SpeedMode {
        internal static let double = ImageAsset(name: "double")
        internal static let half = ImageAsset(name: "half")
        internal static let normal = ImageAsset(name: "normal")
        internal static let oneAndAHalf = ImageAsset(name: "oneAndAHalf")
      }
      internal static let backTrack = ImageAsset(name: "backTrack")
      internal static let defaultArtwork = ImageAsset(name: "defaultArtwork")
      internal static let fastForward = ImageAsset(name: "fastForward")
      internal static let goBackward15 = ImageAsset(name: "goBackward15")
      internal static let goForward15 = ImageAsset(name: "goForward15")
      internal static let pause = ImageAsset(name: "pause")
      internal static let play = ImageAsset(name: "play")
      internal static let repeatAudio = ImageAsset(name: "repeatAudio")
      internal static let repeatOneAudio = ImageAsset(name: "repeatOneAudio")
      internal static let shuffleAudio = ImageAsset(name: "shuffleAudio")
      internal static let viewPlaylist = ImageAsset(name: "viewPlaylist")
    }
    internal enum Backup {
      internal static let deviceCenter = ImageAsset(name: "device_center")
      internal static let drive = ImageAsset(name: "drive")
      internal static let folderSync = ImageAsset(name: "folder_sync")
      internal static let linux = ImageAsset(name: "linux")
      internal static let mac = ImageAsset(name: "mac")
      internal static let mobile = ImageAsset(name: "mobile")
      internal static let pc = ImageAsset(name: "pc")
      internal static let win = ImageAsset(name: "win")
    }
    internal enum Banner {
      internal static let closeCircle = ImageAsset(name: "closeCircle")
    }
    internal enum Business {
      internal static let accountExpiredAdmin = ImageAsset(name: "accountExpiredAdmin")
      internal static let accountExpiredUser = ImageAsset(name: "accountExpiredUser")
      internal static let paymentOverdue = ImageAsset(name: "paymentOverdue")
      internal static let userManagement = ImageAsset(name: "userManagement")
    }
    internal enum Chat {
      internal enum AddToChat {
        internal static let attachCloud = ImageAsset(name: "attachCloud")
        internal static let attachContact = ImageAsset(name: "attachContact")
        internal static let attachFilesApp = ImageAsset(name: "attachFilesApp")
        internal static let attachGIF = ImageAsset(name: "attachGIF")
        internal static let attachGallery = ImageAsset(name: "attachGallery")
        internal static let attachLocation = ImageAsset(name: "attachLocation")
        internal static let attachVoiceClip = ImageAsset(name: "attachVoiceClip")
        internal static let chatScanDocument = ImageAsset(name: "chatScanDocument")
      }
      internal static let allowAcess = ImageAsset(name: "Allow Acess")
      internal enum Calls {
        internal static let audioSource = ImageAsset(name: "audioSource")
        internal static let audioSourceActive = ImageAsset(name: "audioSourceActive")
        internal static let callSlotsBanner = ImageAsset(name: "callSlots-banner")
        internal static let callSlots = ImageAsset(name: "callSlots")
        internal static let cameraOff = ImageAsset(name: "cameraOff")
        internal static let cameraOn = ImageAsset(name: "cameraOn")
        internal static let micOff = ImageAsset(name: "micOff")
        internal static let micOn = ImageAsset(name: "micOn")
        internal static let rejectCall = ImageAsset(name: "rejectCall")
        internal static let remoteMicMute = ImageAsset(name: "remote_mic_mute")
        internal static let rotateOFF = ImageAsset(name: "rotateOFF")
        internal static let rotateON = ImageAsset(name: "rotateON")
        internal static let speakerOff = ImageAsset(name: "speakerOff")
        internal static let speakerOn = ImageAsset(name: "speakerOn")
        internal static let userMutedBanner = ImageAsset(name: "userMuted-banner")
        internal static let userMuted = ImageAsset(name: "userMuted")
        internal static let userMutedBig = ImageAsset(name: "userMutedBig")
      }
      internal enum ContactDetails {
        internal static let clearChatHistory = ImageAsset(name: "clearChatHistory")
      }
      internal enum ContextualMenu {
        internal static let archiveChatMenu = ImageAsset(name: "archiveChat_menu")
        internal static let markUnreadMenu = ImageAsset(name: "markUnread_menu")
        internal static let mutedChatMenu = ImageAsset(name: "mutedChat_menu")
      }
      internal enum InputToolbar {
        internal static let bucketBody = ImageAsset(name: "bucketBody")
        internal static let bucketLid = ImageAsset(name: "bucketLid")
        internal static let buttonCameraDefault = ImageAsset(name: "button_camera_default")
        internal static let buttonMediaDefault = ImageAsset(name: "button_media_default")
        internal static let buttonUploadDefault = ImageAsset(name: "button_upload_default")
        internal static let collapse = ImageAsset(name: "collapse")
        internal static let expand = ImageAsset(name: "expand")
        internal static let lockRecording = ImageAsset(name: "lockRecording")
        internal static let sendButton = ImageAsset(name: "sendButton")
        internal static let sendVoiceClipActive = ImageAsset(name: "sendVoiceClipActive")
        internal static let sendVoiceClipInactive = ImageAsset(name: "sendVoiceClipInactive")
      }
      internal static let megaIconCall = ImageAsset(name: "MEGA_icon_call")
      internal enum Messages {
        internal enum Management {
          internal static let callCancelled = ImageAsset(name: "callCancelled")
          internal static let callEnded = ImageAsset(name: "callEnded")
          internal static let callFailed = ImageAsset(name: "callFailed")
          internal static let callRejected = ImageAsset(name: "callRejected")
          internal static let callWithXIncoming = ImageAsset(name: "callWithXIncoming")
          internal static let missedCall = ImageAsset(name: "missedCall")
        }
        internal static let forward = ImageAsset(name: "forward")
        internal static let pauseVoiceClip = ImageAsset(name: "pauseVoiceClip")
        internal static let playButton = ImageAsset(name: "playButton")
        internal static let playVoiceClip = ImageAsset(name: "playVoiceClip")
        internal static let sendingManual = ImageAsset(name: "sending_manual")
        internal static let voiceWave = ImageAsset(name: "voiceWave")
      }
      internal enum NavigationBar {
        internal static let audioCall = ImageAsset(name: "audioCall")
        internal static let startConversation = ImageAsset(name: "startConversation")
        internal static let videoCall = ImageAsset(name: "videoCall")
      }
      internal enum ShareLocation {
        internal static let location = ImageAsset(name: "location")
        internal static let locationPin = ImageAsset(name: "locationPin")
        internal static let sendThisLocation = ImageAsset(name: "sendThisLocation")
      }
      internal enum VoiceHud {
        internal static let hudMic = ImageAsset(name: "hudMic")
      }
      internal enum Wave {
        internal static let waveform0000 = ImageAsset(name: "waveform_0000")
        internal static let waveform0001 = ImageAsset(name: "waveform_0001")
        internal static let waveform00010 = ImageAsset(name: "waveform_00010")
        internal static let waveform00011 = ImageAsset(name: "waveform_00011")
        internal static let waveform00012 = ImageAsset(name: "waveform_00012")
        internal static let waveform00013 = ImageAsset(name: "waveform_00013")
        internal static let waveform00014 = ImageAsset(name: "waveform_00014")
        internal static let waveform00015 = ImageAsset(name: "waveform_00015")
        internal static let waveform00016 = ImageAsset(name: "waveform_00016")
        internal static let waveform00017 = ImageAsset(name: "waveform_00017")
        internal static let waveform00018 = ImageAsset(name: "waveform_00018")
        internal static let waveform00019 = ImageAsset(name: "waveform_00019")
        internal static let waveform0002 = ImageAsset(name: "waveform_0002")
        internal static let waveform00020 = ImageAsset(name: "waveform_00020")
        internal static let waveform00021 = ImageAsset(name: "waveform_00021")
        internal static let waveform00022 = ImageAsset(name: "waveform_00022")
        internal static let waveform00023 = ImageAsset(name: "waveform_00023")
        internal static let waveform00024 = ImageAsset(name: "waveform_00024")
        internal static let waveform00025 = ImageAsset(name: "waveform_00025")
        internal static let waveform00026 = ImageAsset(name: "waveform_00026")
        internal static let waveform00027 = ImageAsset(name: "waveform_00027")
        internal static let waveform00028 = ImageAsset(name: "waveform_00028")
        internal static let waveform00029 = ImageAsset(name: "waveform_00029")
        internal static let waveform0003 = ImageAsset(name: "waveform_0003")
        internal static let waveform00030 = ImageAsset(name: "waveform_00030")
        internal static let waveform00031 = ImageAsset(name: "waveform_00031")
        internal static let waveform00032 = ImageAsset(name: "waveform_00032")
        internal static let waveform00033 = ImageAsset(name: "waveform_00033")
        internal static let waveform00034 = ImageAsset(name: "waveform_00034")
        internal static let waveform00035 = ImageAsset(name: "waveform_00035")
        internal static let waveform00036 = ImageAsset(name: "waveform_00036")
        internal static let waveform00037 = ImageAsset(name: "waveform_00037")
        internal static let waveform00038 = ImageAsset(name: "waveform_00038")
        internal static let waveform00039 = ImageAsset(name: "waveform_00039")
        internal static let waveform0004 = ImageAsset(name: "waveform_0004")
        internal static let waveform00040 = ImageAsset(name: "waveform_00040")
        internal static let waveform00041 = ImageAsset(name: "waveform_00041")
        internal static let waveform00042 = ImageAsset(name: "waveform_00042")
        internal static let waveform00043 = ImageAsset(name: "waveform_00043")
        internal static let waveform00044 = ImageAsset(name: "waveform_00044")
        internal static let waveform00045 = ImageAsset(name: "waveform_00045")
        internal static let waveform00046 = ImageAsset(name: "waveform_00046")
        internal static let waveform00047 = ImageAsset(name: "waveform_00047")
        internal static let waveform00048 = ImageAsset(name: "waveform_00048")
        internal static let waveform00049 = ImageAsset(name: "waveform_00049")
        internal static let waveform0005 = ImageAsset(name: "waveform_0005")
        internal static let waveform00050 = ImageAsset(name: "waveform_00050")
        internal static let waveform00051 = ImageAsset(name: "waveform_00051")
        internal static let waveform00052 = ImageAsset(name: "waveform_00052")
        internal static let waveform00053 = ImageAsset(name: "waveform_00053")
        internal static let waveform00054 = ImageAsset(name: "waveform_00054")
        internal static let waveform00055 = ImageAsset(name: "waveform_00055")
        internal static let waveform00056 = ImageAsset(name: "waveform_00056")
        internal static let waveform00057 = ImageAsset(name: "waveform_00057")
        internal static let waveform00058 = ImageAsset(name: "waveform_00058")
        internal static let waveform00059 = ImageAsset(name: "waveform_00059")
        internal static let waveform0006 = ImageAsset(name: "waveform_0006")
        internal static let waveform0007 = ImageAsset(name: "waveform_0007")
        internal static let waveform0008 = ImageAsset(name: "waveform_0008")
        internal static let waveform0009 = ImageAsset(name: "waveform_0009")
      }
      internal static let addGroupAvatar = ImageAsset(name: "addGroupAvatar")
      internal static let addReactionSmall = ImageAsset(name: "addReactionSmall")
      internal static let archiveChat = ImageAsset(name: "archiveChat")
      internal static let archiveChatSwipeActionButton = ImageAsset(name: "archiveChatSwipeActionButton")
      internal static let backArrow = ImageAsset(name: "backArrow")
      internal static let bubbleTailless = ImageAsset(name: "bubble_tailless")
      internal static let cameraIcon = ImageAsset(name: "cameraIcon")
      internal static let cameraIconWhite = ImageAsset(name: "cameraIconWhite")
      internal static let cancelVoice = ImageAsset(name: "cancelVoice")
      internal static let chatLink = ImageAsset(name: "chatLink")
      internal static let chatLinkCreation = ImageAsset(name: "chatLinkCreation")
      internal static let chatNotifications = ImageAsset(name: "chatNotifications")
      internal static let chatObservers = ImageAsset(name: "chatObservers")
      internal static let checkmarkWelcomeMessage = ImageAsset(name: "checkmark_welcomeMessage")
      internal static let clearEdit = ImageAsset(name: "clearEdit")
      internal static let closeTip = ImageAsset(name: "closeTip")
      internal static let confirmEdit = ImageAsset(name: "confirmEdit")
      internal static let createGroup = ImageAsset(name: "createGroup")
      internal static let downloadGif = ImageAsset(name: "download_gif")
      internal static let endCall = ImageAsset(name: "endCall")
      internal static let forwardToolbar = ImageAsset(name: "forwardToolbar")
      internal static let giphyCellBackground = ImageAsset(name: "giphyCellBackground")
      internal static let groupChat = ImageAsset(name: "groupChat")
      internal static let ilMeeting = ImageAsset(name: "il_meeting")
      internal static let inviteToChat = ImageAsset(name: "inviteToChat")
      internal static let joinMeeting = ImageAsset(name: "joinMeeting")
      internal static let jumpBottom = ImageAsset(name: "jumpBottom")
      internal static let jumpToLatest = ImageAsset(name: "jumpToLatest")
      internal static let leaveGroup = ImageAsset(name: "leaveGroup")
      internal static let locationMessage = ImageAsset(name: "locationMessage")
      internal static let locationMessageGrey = ImageAsset(name: "locationMessageGrey")
      internal static let lock = ImageAsset(name: "lock")
      internal static let lockRecording1 = ImageAsset(name: "lockRecording-1")
      internal static let lockWelcomeMessage = ImageAsset(name: "lock_welcomeMessage")
      internal static let mutedChat = ImageAsset(name: "mutedChat")
      internal static let newMeeting = ImageAsset(name: "newMeeting")
      internal static let noGIF = ImageAsset(name: "noGIF")
      internal static let onACall = ImageAsset(name: "onACall")
      internal static let outgoingPauseVoiceClip = ImageAsset(name: "outgoing_pauseVoiceClip")
      internal static let outgoingPlayVoiceClip = ImageAsset(name: "outgoing_playVoiceClip")
      internal static let poweredByGIPHY = ImageAsset(name: "poweredByGIPHY")
      internal static let privacyWarningIco = ImageAsset(name: "privacy_warning_ico")
      internal static let privateChat = ImageAsset(name: "privateChat")
      internal static let recurringMeeting = ImageAsset(name: "recurringMeeting")
      internal static let removeMedia = ImageAsset(name: "remove_media")
      internal static let sendChatDisabled = ImageAsset(name: "sendChatDisabled")
      internal static let sendVoiceClipDefault1 = ImageAsset(name: "sendVoiceClipDefault-1")
      internal static let sendVoiceClipDefault = ImageAsset(name: "sendVoiceClipDefault")
      internal static let sharedFiles = ImageAsset(name: "sharedFiles")
      internal static let speakerView = ImageAsset(name: "speakerView")
      internal static let thumbSliderGreen = ImageAsset(name: "thumbSliderGreen")
      internal static let thumbSliderWhite = ImageAsset(name: "thumbSliderWhite")
      internal static let triangle = ImageAsset(name: "triangle")
      internal static let unArchiveChat = ImageAsset(name: "unArchiveChat")
      internal static let voiceMessage = ImageAsset(name: "voiceMessage")
      internal static let voiceMessageGrey = ImageAsset(name: "voiceMessageGrey")
      internal static let voiceTip = ImageAsset(name: "voiceTip")
    }
    internal enum Contacts {
      internal static let more = ImageAsset(name: "More")
      internal static let addContact = ImageAsset(name: "addContact")
      internal static let callVideoRoundDisabled = ImageAsset(name: "callVideoRound, disabled")
      internal static let callVideoRound = ImageAsset(name: "callVideoRound")
      internal static let contactRequests = ImageAsset(name: "contactRequests")
      internal static let contactVerified = ImageAsset(name: "contactVerified")
      internal static let contactRequestAccept = ImageAsset(name: "contact_request_accept")
      internal static let contactRequestDeny = ImageAsset(name: "contact_request_deny")
      internal static let enterEmail = ImageAsset(name: "enter email")
      internal static let groups = ImageAsset(name: "groups")
      internal static let inviteContact = ImageAsset(name: "inviteContact")
      internal static let inviteSent = ImageAsset(name: "inviteSent")
      internal static let makeCallRoundDisabled = ImageAsset(name: "makeCallRound, disabled")
      internal static let makeCallRound = ImageAsset(name: "makeCallRound")
      internal static let scanQRCode = ImageAsset(name: "scan QR code")
      internal static let sendMessageRoundDisabled = ImageAsset(name: "sendMessageRound, disabled")
      internal static let sendMessageRound = ImageAsset(name: "sendMessageRound")
      internal static let verifyCredentials = ImageAsset(name: "verifyCredentials")
    }
    internal enum Cookies {
      internal static let cookie = ImageAsset(name: "cookie")
    }
    internal enum DiskQuotaPaywall {
      internal static let storageFull = ImageAsset(name: "StorageFull")
    }
    internal enum EmptyStates {
      internal enum Skeletons {
        internal static let chatListLoading = ImageAsset(name: "chatListLoading")
        internal static let chatroomLoading = ImageAsset(name: "chatroomLoading")
      }
      internal static let cameraEmptyState = ImageAsset(name: "cameraEmptyState")
      internal static let cameraUploadsBoarding = ImageAsset(name: "cameraUploadsBoarding")
      internal static let chatEmptyState = ImageAsset(name: "chatEmptyState")
      internal static let chatsArchivedEmptyState = ImageAsset(name: "chatsArchivedEmptyState")
      internal static let cloudEmptyState = ImageAsset(name: "cloudEmptyState")
      internal static let contactsEmptyState = ImageAsset(name: "contactsEmptyState")
      internal static let favouritesEmptyState = ImageAsset(name: "favouritesEmptyState")
      internal static let folderEmptyState = ImageAsset(name: "folderEmptyState")
      internal static let incomingEmptyState = ImageAsset(name: "incomingEmptyState")
      internal static let invalidFileLink = ImageAsset(name: "invalidFileLink")
      internal static let invalidFolderLink = ImageAsset(name: "invalidFolderLink")
      internal static let linksEmptyState = ImageAsset(name: "linksEmptyState")
      internal static let meetingEmptyState = ImageAsset(name: "meetingEmptyState")
      internal static let noInternetEmptyState = ImageAsset(name: "noInternetEmptyState")
      internal static let notificationsEmptyState = ImageAsset(name: "notificationsEmptyState")
      internal static let offlineEmptyState = ImageAsset(name: "offlineEmptyState")
      internal static let outgoingEmptyState = ImageAsset(name: "outgoingEmptyState")
      internal static let pausedTransfersEmptyState = ImageAsset(name: "pausedTransfersEmptyState")
      internal static let recentsEmptyState = ImageAsset(name: "recentsEmptyState")
      internal static let rubbishEmptyState = ImageAsset(name: "rubbishEmptyState")
      internal static let searchEmptyState = ImageAsset(name: "searchEmptyState")
      internal static let sharedFilesEmptyState = ImageAsset(name: "sharedFilesEmptyState")
      internal static let transfersEmptyState = ImageAsset(name: "transfersEmptyState")
    }
    internal enum Filetypes {
      internal static let _3d = ImageAsset(name: "3d")
      internal static let afterEffects = ImageAsset(name: "after_effects")
      internal static let audio = ImageAsset(name: "audio")
      internal static let cad = ImageAsset(name: "cad")
      internal static let compressed = ImageAsset(name: "compressed")
      internal static let dmg = ImageAsset(name: "dmg")
      internal static let excel = ImageAsset(name: "excel")
      internal static let executable = ImageAsset(name: "executable")
      internal static let experiencedesign = ImageAsset(name: "experiencedesign")
      internal static let folder = ImageAsset(name: "folder")
      internal static let folderChat = ImageAsset(name: "folder_chat")
      internal static let folderImage = ImageAsset(name: "folder_image")
      internal static let folderIncoming = ImageAsset(name: "folder_incoming")
      internal static let folderOutgoing = ImageAsset(name: "folder_outgoing")
      internal static let font = ImageAsset(name: "font")
      internal static let generic = ImageAsset(name: "generic")
      internal static let illustrator = ImageAsset(name: "illustrator")
      internal static let image = ImageAsset(name: "image")
      internal static let indesign = ImageAsset(name: "indesign")
      internal static let keynote = ImageAsset(name: "keynote")
      internal static let numbers = ImageAsset(name: "numbers")
      internal static let openoffice = ImageAsset(name: "openoffice")
      internal static let pages = ImageAsset(name: "pages")
      internal static let pdf = ImageAsset(name: "pdf")
      internal static let photoshop = ImageAsset(name: "photoshop")
      internal static let powerpoint = ImageAsset(name: "powerpoint")
      internal static let premiere = ImageAsset(name: "premiere")
      internal static let raw = ImageAsset(name: "raw")
      internal static let sketch = ImageAsset(name: "sketch")
      internal static let spreadsheet = ImageAsset(name: "spreadsheet")
      internal static let text = ImageAsset(name: "text")
      internal static let torrent = ImageAsset(name: "torrent")
      internal static let url = ImageAsset(name: "url")
      internal static let vector = ImageAsset(name: "vector")
      internal static let video = ImageAsset(name: "video")
      internal static let webData = ImageAsset(name: "web_data")
      internal static let webLang = ImageAsset(name: "web_lang")
      internal static let word = ImageAsset(name: "word")
    }
    internal enum Generic {
      internal static let spotlightFile = ImageAsset(name: "Spotlight_file")
      internal static let spotlightFolder = ImageAsset(name: "Spotlight_folder")
      internal static let cancel = ImageAsset(name: "cancel")
      internal static let currentEmail = ImageAsset(name: "currentEmail")
      internal static let downloaded = ImageAsset(name: "downloaded")
      internal static let favouriteThumbnail = ImageAsset(name: "favouriteThumbnail")
      internal static let iconKeyOnly = ImageAsset(name: "icon-key-only")
      internal static let info = ImageAsset(name: "info")
      internal static let isTakedown = ImageAsset(name: "isTakedown")
      internal static let link = ImageAsset(name: "link")
      internal static let linked = ImageAsset(name: "linked")
      internal static let linkedThumbnail = ImageAsset(name: "linkedThumbnail")
      internal static let littleQuestionMark = ImageAsset(name: "littleQuestionMark")
      internal static let mail = ImageAsset(name: "mail")
      internal static let moreGrid = ImageAsset(name: "moreGrid")
      internal static let moreList = ImageAsset(name: "moreList")
      internal static let moreListChatSwipeActionButton = ImageAsset(name: "moreListChatSwipeActionButton")
      internal static let padlock = ImageAsset(name: "padlock")
      internal static let rename = ImageAsset(name: "rename")
      internal static let search = ImageAsset(name: "search")
      internal static let standardDisclosureIndicator = ImageAsset(name: "standardDisclosureIndicator")
      internal static let thumbnailSelected = ImageAsset(name: "thumbnail_selected")
      internal static let turquoiseCheckmark = ImageAsset(name: "turquoise_checkmark")
      internal static let versioned = ImageAsset(name: "versioned")
      internal static let versionedThumbnail = ImageAsset(name: "versionedThumbnail")
      internal static let versions = ImageAsset(name: "versions")
      internal static let videoList = ImageAsset(name: "video_list")
      internal static let whiteCheckmark = ImageAsset(name: "white_checkmark")
    }
    internal enum GetLinkView {
      internal static let linkGetLink = ImageAsset(name: "linkGetLink")
    }
    internal enum Hud {
      internal static let hudCameraUploads = ImageAsset(name: "hudCameraUploads")
      internal static let hudDownload = ImageAsset(name: "hudDownload")
      internal static let hudError = ImageAsset(name: "hudError")
      internal static let hudForbidden = ImageAsset(name: "hudForbidden")
      internal static let hudLink = ImageAsset(name: "hudLink")
      internal static let hudLogOut = ImageAsset(name: "hudLogOut")
      internal static let hudMinus = ImageAsset(name: "hudMinus")
      internal static let hudNoCamera = ImageAsset(name: "hudNoCamera")
      internal static let hudSharedFolder = ImageAsset(name: "hudSharedFolder")
      internal static let hudSuccess = ImageAsset(name: "hudSuccess")
      internal static let hudWarning = ImageAsset(name: "hudWarning")
    }
    internal enum Home {
      internal static let allPhotosEmptyState = ImageAsset(name: "allPhotosEmptyState")
      internal static let audioCard = ImageAsset(name: "audioCard")
      internal static let audioEmptyState = ImageAsset(name: "audioEmptyState")
      internal static let closeBanner = ImageAsset(name: "closeBanner")
      internal static let docsCard = ImageAsset(name: "docsCard")
      internal static let documentsEmptyState = ImageAsset(name: "documentsEmptyState")
      internal static let explorerCardAudio = ImageAsset(name: "explorerCardAudio")
      internal static let explorerCardDocs = ImageAsset(name: "explorerCardDocs")
      internal static let explorerCardFavourites = ImageAsset(name: "explorerCardFavourites")
      internal static let explorerCardImage = ImageAsset(name: "explorerCardImage")
      internal static let explorerCardVideoFilmStrips = ImageAsset(name: "explorerCardVideoFilmStrips")
      internal static let explorerCardVideoFilmStripsBlue = ImageAsset(name: "explorerCardVideoFilmStrips_blue")
      internal static let explorerCardVideoPlay = ImageAsset(name: "explorerCardVideoPlay")
      internal static let explorerCardVideoPlayBlue = ImageAsset(name: "explorerCardVideoPlay_blue")
      internal static let imagesCard = ImageAsset(name: "imagesCard")
      internal static let pathCloudDrive = ImageAsset(name: "pathCloudDrive")
      internal static let pathInShares = ImageAsset(name: "pathInShares")
      internal static let searchBarIcon = ImageAsset(name: "searchBarIcon")
      internal static let startChat = ImageAsset(name: "startChat")
      internal static let uploadFile = ImageAsset(name: "uploadFile")
      internal static let videoCard = ImageAsset(name: "videoCard")
      internal static let videoEmptyState = ImageAsset(name: "videoEmptyState")
    }
    internal enum InfoActions {
      internal static let cancelIcon = ImageAsset(name: "cancelIcon")
      internal static let `import` = ImageAsset(name: "import")
      internal static let openWith = ImageAsset(name: "openWith")
    }
    internal enum Labels {
      internal static let blue = ImageAsset(name: "Blue")
      internal static let blueSmall = ImageAsset(name: "BlueSmall")
      internal static let green = ImageAsset(name: "Green")
      internal static let greenSmall = ImageAsset(name: "GreenSmall")
      internal static let grey = ImageAsset(name: "Grey")
      internal static let greySmall = ImageAsset(name: "GreySmall")
      internal static let orange = ImageAsset(name: "Orange")
      internal static let orangeSmall = ImageAsset(name: "OrangeSmall")
      internal static let purple = ImageAsset(name: "Purple")
      internal static let purpleSmall = ImageAsset(name: "PurpleSmall")
      internal static let red = ImageAsset(name: "Red")
      internal static let redSmall = ImageAsset(name: "RedSmall")
      internal static let yellow = ImageAsset(name: "Yellow")
      internal static let yellowSmall = ImageAsset(name: "YellowSmall")
      internal static let favouriteSmall = ImageAsset(name: "favouriteSmall")
    }
    internal enum Links {
      internal static let decryptionKeyIllustration = ImageAsset(name: "decryptionKeyIllustration")
    }
    internal enum Login {
      internal static let checkBoxSelected = ImageAsset(name: "checkBoxSelected")
      internal static let checkBoxUnselected = ImageAsset(name: "checkBoxUnselected")
      internal static let iconLinkWKey = ImageAsset(name: "icon-link-w-key")
      internal static let mailBig = ImageAsset(name: "mailBig")
      internal static let name = ImageAsset(name: "name")
    }
    internal enum Logo {
      internal static let megaShareContactLink = ImageAsset(name: "MEGA_ShareContactLink")
      internal static let megaLogoGrayscale = ImageAsset(name: "MEGA_logo_grayscale")
      internal static let favicon = ImageAsset(name: "favicon")
      internal static let megaThePrivacyCompanyLogo = ImageAsset(name: "megaThePrivacyCompanyLogo")
      internal static let splashScreenMEGALogo = ImageAsset(name: "splashScreenMEGALogo")
    }
    internal enum Meetings {
      internal enum Info {
        internal static let allowNonHostToAddParticipant = ImageAsset(name: "allowNonHostToAddParticipant")
        internal static let enableChatNotifications = ImageAsset(name: "enableChatNotifications")
        internal static let manageChatHistory = ImageAsset(name: "manageChatHistory")
        internal static let meetingLink = ImageAsset(name: "meetingLink")
        internal static let sharedFilesInfo = ImageAsset(name: "sharedFilesInfo")
      }
      internal static let infoMeetings = ImageAsset(name: "InfoMeetings")
      internal enum Scheduled {
        internal enum ContextMenu {
          internal static let joinMeeting2 = ImageAsset(name: "joinMeeting2")
          internal static let occurrences = ImageAsset(name: "occurrences")
          internal static let startMeeting2 = ImageAsset(name: "startMeeting2")
        }
      }
      internal static let shareWhite = ImageAsset(name: "ShareWhite")
      internal static let addContactMeetings = ImageAsset(name: "addContactMeetings")
      internal static let addContactWhite = ImageAsset(name: "addContactWhite")
      internal static let audioSourceMeetingAction = ImageAsset(name: "audioSourceMeetingAction")
      internal static let cameraxMeetingAction = ImageAsset(name: "cameraxMeetingAction")
      internal static let endCallMeetingAction = ImageAsset(name: "endCallMeetingAction")
      internal static let expandLocalVideo = ImageAsset(name: "expandLocalVideo")
      internal static let flipCameraMeetingAction = ImageAsset(name: "flipCameraMeetingAction")
      internal static let galleryView = ImageAsset(name: "galleryView")
      internal static let hangCallMeetingAction = ImageAsset(name: "hangCallMeetingAction")
      internal static let joinAMeeting = ImageAsset(name: "joinAMeeting")
      internal static let moderatorMeetings = ImageAsset(name: "moderatorMeetings")
      internal static let muteMeetingAction = ImageAsset(name: "muteMeetingAction")
      internal static let removeModerator = ImageAsset(name: "removeModerator")
      internal static let scheduleMeeting = ImageAsset(name: "scheduleMeeting")
      internal static let sendMessageMeetings = ImageAsset(name: "sendMessageMeetings")
      internal static let speakerMeetingAction = ImageAsset(name: "speakerMeetingAction")
      internal static let startMeeting = ImageAsset(name: "startMeeting")
      internal static let userMicOn = ImageAsset(name: "userMicOn")
      internal static let userMutedMeetings = ImageAsset(name: "userMutedMeetings")
      internal static let videoOff = ImageAsset(name: "videoOff")
    }
    internal enum MyAccount {
      internal static let backups = ImageAsset(name: "backups")
      internal static let iconAchievements = ImageAsset(name: "icon-achievements")
      internal static let iconContacts = ImageAsset(name: "icon-contacts")
      internal static let iconNotifications = ImageAsset(name: "icon-notifications")
      internal static let iconOffline = ImageAsset(name: "icon-offline")
      internal static let iconSettings = ImageAsset(name: "icon-settings")
      internal static let iconStorage = ImageAsset(name: "icon-storage")
      internal static let iconTransfers = ImageAsset(name: "icon-transfers")
      internal static let plan = ImageAsset(name: "plan")
      internal static let qrCodeIcon = ImageAsset(name: "qrCodeIcon")
      internal static let scanQRCode = ImageAsset(name: "scanQRCode")
      internal static let upgradeSecurity = ImageAsset(name: "upgradeSecurity")
      internal static let upgradeSecurityClose = ImageAsset(name: "upgradeSecurityClose")
      internal static let viewAndEditProfile = ImageAsset(name: "viewAndEditProfile")
    }
    internal enum NavigationBar {
      internal static let add = ImageAsset(name: "add")
      internal static let done = ImageAsset(name: "done")
      internal static let downArrow = ImageAsset(name: "down-arrow")
      internal static let moreNavigationBar = ImageAsset(name: "moreNavigationBar")
      internal static let selectAll = ImageAsset(name: "selectAll")
      internal static let selected = ImageAsset(name: "selected")
    }
    internal enum NodeActions {
      internal static let copy = ImageAsset(name: "copy")
      internal static let delete = ImageAsset(name: "delete")
      internal static let disputeTakedown = ImageAsset(name: "disputeTakedown")
      internal static let edittext = ImageAsset(name: "edittext")
      internal static let export = ImageAsset(name: "export")
      internal static let favourite = ImageAsset(name: "favourite")
      internal static let history = ImageAsset(name: "history")
      internal static let label = ImageAsset(name: "label")
      internal static let leaveShare = ImageAsset(name: "leaveShare")
      internal static let move = ImageAsset(name: "move")
      internal static let offline = ImageAsset(name: "offline")
      internal static let removeFavourite = ImageAsset(name: "removeFavourite")
      internal static let removeLink = ImageAsset(name: "removeLink")
      internal static let restore = ImageAsset(name: "restore")
      internal static let rubbishBin = ImageAsset(name: "rubbishBin")
      internal static let saveToPhotos = ImageAsset(name: "saveToPhotos")
      internal static let sendToChat = ImageAsset(name: "sendToChat")
      internal static let share = ImageAsset(name: "share")
      internal static let shareFolder = ImageAsset(name: "shareFolder")
      internal static let slideshow = ImageAsset(name: "slideshow")
      internal static let textfile = ImageAsset(name: "textfile")
    }
    internal enum Onboarding {
      internal static let accessContact = ImageAsset(name: "access contact")
      internal static let notificationDevicePermission = ImageAsset(name: "notificationDevicePermission")
      internal static let onboarding1Encryption = ImageAsset(name: "onboarding1_encryption")
      internal static let onboarding2Chat = ImageAsset(name: "onboarding2_chat")
      internal static let onboarding3Contacts = ImageAsset(name: "onboarding3_contacts")
      internal static let onboarding4CameraUploads = ImageAsset(name: "onboarding4_camera_uploads")
      internal static let photosPermission = ImageAsset(name: "photosPermission")
    }
    internal enum PasswordStregthIndicator {
      internal static let indicatorGood = ImageAsset(name: "indicatorGood")
      internal static let indicatorMedium = ImageAsset(name: "indicatorMedium")
      internal static let indicatorStrong = ImageAsset(name: "indicatorStrong")
      internal static let indicatorVeryWeak = ImageAsset(name: "indicatorVeryWeak")
      internal static let indicatorWeak = ImageAsset(name: "indicatorWeak")
    }
    internal enum PhotoBrowser {
      internal static let blackCrossedPlayButton = ImageAsset(name: "blackCrossedPlayButton")
      internal static let blackPlayButton = ImageAsset(name: "blackPlayButton")
      internal static let pageView = ImageAsset(name: "pageView")
    }
    internal enum Photos {
      internal static let cameraUploadsV2Migration = ImageAsset(name: "cameraUploadsV2Migration")
      internal static let photoCardPlaceholder = ImageAsset(name: "photoCardPlaceholder")
    }
    internal enum Pro {
      internal static let listCrestFREE = ImageAsset(name: "list_crest_FREE")
      internal static let listCrestLITE = ImageAsset(name: "list_crest_LITE")
      internal static let listCrestPROI = ImageAsset(name: "list_crest_PROI")
      internal static let listCrestPROII = ImageAsset(name: "list_crest_PROII")
      internal static let listCrestPROIII = ImageAsset(name: "list_crest_PROIII")
      internal static let proLabel = ImageAsset(name: "proLabel")
      internal static let upgradePro = ImageAsset(name: "upgradePro")
      internal static let whiteCrestLITE = ImageAsset(name: "white_crest_LITE")
      internal static let whiteCrestPROI = ImageAsset(name: "white_crest_PROI")
      internal static let whiteCrestPROII = ImageAsset(name: "white_crest_PROII")
      internal static let whiteCrestPROIII = ImageAsset(name: "white_crest_PROIII")
    }
    internal enum Recents {
      internal static let miniFolderIncoming = ImageAsset(name: "mini_folder_incoming")
      internal static let miniFolderOutgoing = ImageAsset(name: "mini_folder_outgoing")
      internal static let multiplePhotos = ImageAsset(name: "multiplePhotos")
      internal static let recentUpload = ImageAsset(name: "recentUpload")
    }
    internal enum RemindPassword {
      internal static let keyIcon = ImageAsset(name: "keyIcon")
      internal static let showHidePassword = ImageAsset(name: "showHidePassword")
      internal static let showHidePasswordActive = ImageAsset(name: "showHidePassword_active")
      internal static let showHidePasswordWhite = ImageAsset(name: "showHidePassword_white")
    }
    internal enum RubbishBinCleaningScheduler {
      internal static let retentionIllustration = ImageAsset(name: "retention_illustration")
    }
    internal enum SMSVerification {
      internal static let addPhoneNumberMedium = ImageAsset(name: "addPhoneNumberMedium")
      internal static let addPhoneNumberSmall = ImageAsset(name: "addPhoneNumberSmall")
      internal static let phoneNumber = ImageAsset(name: "phoneNumber")
      internal static let verificationCountry = ImageAsset(name: "verificationCountry")
      internal static let verificationHeader = ImageAsset(name: "verificationHeader")
    }
    internal enum Settings {
      internal static let aboutSettings = ImageAsset(name: "aboutSettings")
      internal static let advancedSettings = ImageAsset(name: "advancedSettings")
      internal static let callsSettings = ImageAsset(name: "callsSettings")
      internal static let cameraUploadsSettings = ImageAsset(name: "cameraUploadsSettings")
      internal static let changeLaunchTab = ImageAsset(name: "changeLaunchTab")
      internal static let chatSettings = ImageAsset(name: "chatSettings")
      internal static let cookieSettings = ImageAsset(name: "cookieSettings")
      internal static let fileManagementSettings = ImageAsset(name: "fileManagementSettings")
      internal static let helpSettings = ImageAsset(name: "helpSettings")
      internal static let keyIllustration = ImageAsset(name: "key_illustration")
      internal static let securitySettings = ImageAsset(name: "securitySettings")
      internal static let termsAndPoliciesSettings = ImageAsset(name: "termsAndPoliciesSettings")
      internal static let userInterfaceSettings = ImageAsset(name: "userInterfaceSettings")
    }
    internal enum SharedItems {
      internal static let fullAccessPermissions = ImageAsset(name: "fullAccessPermissions")
      internal static let incomingSegmentControler = ImageAsset(name: "incomingSegmentControler")
      internal static let linksSegmentControler = ImageAsset(name: "linksSegmentControler")
      internal static let outgoingSegmentControler = ImageAsset(name: "outgoingSegmentControler")
      internal static let readPermissions = ImageAsset(name: "readPermissions")
      internal static let readWritePermissions = ImageAsset(name: "readWritePermissions")
      internal static let removeShare = ImageAsset(name: "removeShare")
      internal static let verifyPendingOutshareEmail = ImageAsset(name: "verifyPendingOutshareEmail")
      internal static let warningPermission = ImageAsset(name: "warningPermission")
    }
    internal enum TabBarIcons {
      internal static let cameraUploadsIcon = ImageAsset(name: "cameraUploadsIcon")
      internal static let chatIcon = ImageAsset(name: "chatIcon")
      internal static let cloudDriveIcon = ImageAsset(name: "cloudDriveIcon")
      internal static let home = ImageAsset(name: "home")
      internal static let sharedItemsIcon = ImageAsset(name: "sharedItemsIcon")
    }
    internal enum Transfers {
      internal static let cancelTransfers = ImageAsset(name: "cancelTransfers")
      internal static let downloadError = ImageAsset(name: "downloadError")
      internal static let downloadQueued = ImageAsset(name: "downloadQueued")
      internal static let downloading = ImageAsset(name: "downloading")
      internal static let downloadingOverquota = ImageAsset(name: "downloadingOverquota")
      internal static let pauseTransfers = ImageAsset(name: "pauseTransfers")
      internal static let resumeTransfers = ImageAsset(name: "resumeTransfers")
      internal static let transfersDownload = ImageAsset(name: "transfersDownload")
      internal static let transfersUpload = ImageAsset(name: "transfersUpload")
      internal static let uploadQueued = ImageAsset(name: "uploadQueued")
      internal static let uploading = ImageAsset(name: "uploading")
      internal static let uploadingOverquota = ImageAsset(name: "uploadingOverquota")
      internal enum Widget {
        internal enum Complete {
          internal static let completedBadge = ImageAsset(name: "completedBadge")
        }
        internal enum Download {
          internal static let downloadBadge = ImageAsset(name: "downloadBadge")
        }
        internal enum Error {
          internal enum FileList {
            internal enum FileAcessory {
              internal static let errorBadge = ImageAsset(name: "errorBadge")
            }
          }
        }
        internal static let overquota = ImageAsset(name: "overquota")
        internal enum Pause {
          internal static let combinedShape = ImageAsset(name: "Combined Shape")
        }
        internal enum Upload {
          internal static let uploadBadge = ImageAsset(name: "uploadBadge")
        }
      }
    }
    internal enum TwoFactorAuthentication {
      internal static let _2FASetup = ImageAsset(name: "2FASetup")
    }
    internal enum VerifyEmail {
      internal static let lockedAccounts = ImageAsset(name: "lockedAccounts")
      internal static let warning = ImageAsset(name: "warning")
    }
    internal enum WarningStorageAlmostFull {
      internal static let blockingDiskFull = ImageAsset(name: "blockingDiskFull")
      internal static let deviceStorageAlmostFull = ImageAsset(name: "deviceStorageAlmostFull")
      internal static let diskStorageFull = ImageAsset(name: "disk_storage_full")
      internal static let storageAlmostFull = ImageAsset(name: "storage_almost_full")
      internal static let storageFull = ImageAsset(name: "storage_full")
    }
    internal enum WarningTransferQuota {
      internal static let transferQuotaEmpty = ImageAsset(name: "transfer-quota-empty")
      internal static let transferQuotaSemiEmpty = ImageAsset(name: "transfer-quota-semi-empty")
    }
    internal enum WarningTurnonNotifications {
      internal static let allowNotifications = ImageAsset(name: "allowNotifications")
      internal static let openSettings = ImageAsset(name: "openSettings")
      internal static let tapMega = ImageAsset(name: "tapMega")
      internal static let tapNotifications = ImageAsset(name: "tapNotifications")
    }
  }
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

internal struct ImageAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Image = UIImage
  #endif

  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, macOS 10.7, *)
  internal var image: Image {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    let name = NSImage.Name(self.name)
    let image = (bundle == .main) ? NSImage(named: name) : bundle.image(forResource: name)
    #elseif os(watchOS)
    let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }

  #if os(iOS) || os(tvOS)
  @available(iOS 8.0, tvOS 9.0, *)
  internal func image(compatibleWith traitCollection: UITraitCollection) -> Image {
    let bundle = BundleToken.bundle
    guard let result = Image(named: name, in: bundle, compatibleWith: traitCollection) else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }
  #endif
}

internal extension ImageAsset.Image {
  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, *)
  @available(macOS, deprecated,
    message: "This initializer is unsafe on macOS, please use the ImageAsset.image property")
  convenience init?(asset: ImageAsset) {
    #if os(iOS) || os(tvOS)
    let bundle = BundleToken.bundle
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSImage.Name(asset.name))
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
