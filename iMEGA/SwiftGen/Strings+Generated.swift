// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum Strings {
  public enum InfoPlist {
    /// MEGA accesses your camera when you capture a video, photo or make a call inside the app.
    public static let nsCameraUsageDescription = Strings.tr("InfoPlist", "NSCameraUsageDescription")
    /// If you allow access, MEGA will save the information in your address book on its servers. This will help you find existing MEGA users in your contacts and connect with them on MEGA. MEGA will never send messages to your contacts or share this information with third parties.
    public static let nsContactsUsageDescription = Strings.tr("InfoPlist", "NSContactsUsageDescription")
    /// MEGA accesses Face ID to allow you to easily unlock the app’s passcode when you enable this option.
    public static let nsFaceIDUsageDescription = Strings.tr("InfoPlist", "NSFaceIDUsageDescription")
    /// This will let you use MEGA to place and receive calls through devices that are on the same Wi-Fi or local network.
    public static let nsLocalNetworkUsageDescription = Strings.tr("InfoPlist", "NSLocalNetworkUsageDescription")
    /// MEGA accesses your location when you share it with your contacts in chat.
    public static let nsLocationWhenInUseUsageDescription = Strings.tr("InfoPlist", "NSLocationWhenInUseUsageDescription")
    /// MEGA accesses your microphone when you capture a video, make a call or record voice messages inside the app.
    public static let nsMicrophoneUsageDescription = Strings.tr("InfoPlist", "NSMicrophoneUsageDescription")
    /// MEGA requires access to your photo library to add photos and videos to your device gallery
    public static let nsPhotoLibraryAddUsageDescription = Strings.tr("InfoPlist", "NSPhotoLibraryAddUsageDescription")
    /// MEGA accesses your photos and videos when you upload them, share them through the chat and when Camera Uploads is enabled.
    public static let nsPhotoLibraryUsageDescription = Strings.tr("InfoPlist", "NSPhotoLibraryUsageDescription")
    /// Offline
    public static let quickActionOfflineString = Strings.tr("InfoPlist", "quickActionOfflineString")
    /// Search
    public static let quickActionSearchString = Strings.tr("InfoPlist", "quickActionSearchString")
    /// Upload
    public static let quickActionUploadString = Strings.tr("InfoPlist", "quickActionUploadString")
  }
  public enum Localizable {
    /// %1 and [A]%2 more[/A]
    public static let _1AndA2MoreA = Strings.tr("Localizable", "%1 and [A]%2 more[/A]")
    /// %1 of %2
    public static let _1Of2 = Strings.tr("Localizable", "%1 of %2")
    /// %1$d items
    public static func _1DItems(_ p1: Int) -> String {
      return Strings.tr("Localizable", "%1$d items", p1)
    }
    /// %@ created a chat link
    public static func createdAPublicLinkForTheChat(_ p1: Any) -> String {
      return Strings.tr("Localizable", "%@ created a public link for the chat.", String(describing: p1))
    }
    /// %@ enabled encryption key rotation.
    public static func enabledEncryptedKeyRotation(_ p1: Any) -> String {
      return Strings.tr("Localizable", "%@ enabled Encrypted Key Rotation", String(describing: p1))
    }
    /// %@ joined the call.
    public static func joinedTheCall(_ p1: Any) -> String {
      return Strings.tr("Localizable", "%@ joined the call.", String(describing: p1))
    }
    /// %@ joined the group chat.
    public static func joinedTheGroupChat(_ p1: Any) -> String {
      return Strings.tr("Localizable", "%@ joined the group chat.", String(describing: p1))
    }
    /// %@ left the call.
    public static func leftTheCall(_ p1: Any) -> String {
      return Strings.tr("Localizable", "%@ left the call.", String(describing: p1))
    }
    /// %@ removed the chat link
    public static func removedAPublicLinkForTheChat(_ p1: Any) -> String {
      return Strings.tr("Localizable", "%@ removed a public link for the chat.", String(describing: p1))
    }
    /// %@ Storage Full
    public static func storageFull(_ p1: Any) -> String {
      return Strings.tr("Localizable", "%@ Storage Full", String(describing: p1))
    }
    /// %d days
    public static func dDays(_ p1: Int) -> String {
      return Strings.tr("Localizable", "%d days", p1)
    }
    /// %d participant
    public static func dParticipant(_ p1: Int) -> String {
      return Strings.tr("Localizable", "%d participant", p1)
    }
    /// %d participants
    public static func dParticipants(_ p1: Int) -> String {
      return Strings.tr("Localizable", "%d participants", p1)
    }
    /// (Recommended)
    public static let recommended = Strings.tr("Localizable", "(Recommended)")
    /// 1 contact found on MEGA
    public static let _1ContactFoundOnMEGA = Strings.tr("Localizable", "1 contact found on MEGA")
    /// 1 selected
    public static let _1Selected = Strings.tr("Localizable", "1 selected")
    /// 24 hours
    public static let _24Hours = Strings.tr("Localizable", "24 hours")
    /// 30 minutes
    public static let _30Minutes = Strings.tr("Localizable", "30 minutes")
    /// 4-digit numeric code
    public static let _4DigitNumericCode = Strings.tr("Localizable", "4-Digit Numeric Code")
    /// 6 hours
    public static let _6Hours = Strings.tr("Localizable", "6 hours")
    /// 6-digit numeric code
    public static let _6DigitNumericCode = Strings.tr("Localizable", "6-Digit Numeric Code")
    /// < Slide to cancel
    public static let slideToCancel = Strings.tr("Localizable", "< Slide to cancel")
    /// [S]Please verify your email address[/S] and follow the steps in MEGA’s email to unlock your account.
    public static let sPleaseVerifyYourEmailSAndFollowItsStepsToUnlockYourAccount = Strings.tr("Localizable", "[S]Please verify your email[/S] and follow its steps to unlock your account.")
    /// [X] contacts found on MEGA
    public static let xContactsFoundOnMEGA = Strings.tr("Localizable", "[X] contacts found on MEGA")
    /// A user has left the shared folder {0}
    public static let aUserHasLeftTheSharedFolder0 = Strings.tr("Localizable", "A user has left the shared folder {0}")
    /// About
    public static let about = Strings.tr("Localizable", "about")
    /// Accepted your contact request
    public static let acceptedYourContactRequest = Strings.tr("Localizable", "Accepted your contact request")
    /// Access denied
    public static let accessDenied = Strings.tr("Localizable", "Access denied")
    /// Access denied for non-admin users
    public static let accessDeniedForUsers = Strings.tr("Localizable", "Access denied for users")
    /// Access Pro only features like setting password protection and expiry dates for public files.
    public static let accessProOnlyFeaturesLikeSettingPasswordProtectionAndExpiryDatesForPublicFiles = Strings.tr("Localizable", "Access Pro only features like setting password protection and expiry dates for public files.")
    /// Access to folders was removed.
    public static let accessToFoldersWasRemoved = Strings.tr("Localizable", "Access to folders was removed.")
    /// Account has been deleted or deactivated
    public static let accountHasBeenDeletedDeactivated = Strings.tr("Localizable", "Account has been deleted/deactivated")
    /// Your account has been activated. Please log in.
    public static let accountAlreadyConfirmed = Strings.tr("Localizable", "accountAlreadyConfirmed")
    /// Your account was terminated due to a breach of MEGA’s Terms of Service including, but not limited to, clause 15.
    public static let accountBlocked = Strings.tr("Localizable", "accountBlocked")
    /// Your account has been deleted successfully.
    public static let accountCanceledSuccessfully = Strings.tr("Localizable", "accountCanceledSuccessfully")
    /// Please check your email and follow the link to confirm your account.
    public static let accountNotConfirmed = Strings.tr("Localizable", "accountNotConfirmed")
    /// Account Type:
    public static let accountType = Strings.tr("Localizable", "accountType")
    /// Accurate to %d meters
    public static func accurateToDMeters(_ p1: Int) -> String {
      return Strings.tr("Localizable", "Accurate to %d meters", p1)
    }
    /// Achievements
    public static let achievementsTitle = Strings.tr("Localizable", "achievementsTitle")
    /// Acknowledgements
    public static let acknowledgements = Strings.tr("Localizable", "acknowledgements")
    /// Active
    public static let active = Strings.tr("Localizable", "Active")
    /// Add contacts, create a network, collaborate, and make voice and video calls without ever leaving MEGA
    public static let addContactsCreateANetworkColaborateMakeVoiceAndVideoCallsWithoutEverLeavingMEGA = Strings.tr("Localizable", "Add contacts, create a network, colaborate, make voice and video calls without ever leaving MEGA")
    /// Add Phone Number
    public static let addPhoneNumber = Strings.tr("Localizable", "Add Phone Number")
    /// Add Photo
    public static let addPhoto = Strings.tr("Localizable", "Add Photo")
    /// Add Your Phone Number
    public static let addYourPhoneNumber = Strings.tr("Localizable", "Add Your Phone Number")
    /// Add Contact
    public static let addContact = Strings.tr("Localizable", "addContact")
    /// Add
    public static let addContactButton = Strings.tr("Localizable", "addContactButton")
    /// Add contacts
    public static let addContacts = Strings.tr("Localizable", "addContacts")
    /// Added
    public static let added = Strings.tr("Localizable", "Added")
    /// Added %lld files
    public static func addedLldFiles(_ p1: Int) -> String {
      return Strings.tr("Localizable", "Added %lld files", p1)
    }
    /// Added %lld files and 1 folder
    public static func addedLldFilesAnd1Folder(_ p1: Int) -> String {
      return Strings.tr("Localizable", "Added %lld files and 1 folder", p1)
    }
    /// Added %lld folders
    public static func addedLldFolders(_ p1: Int) -> String {
      return Strings.tr("Localizable", "Added %lld folders", p1)
    }
    /// Added 1 file
    public static let added1File = Strings.tr("Localizable", "Added 1 file")
    /// Added 1 file and %lld folders
    public static func added1FileAndLldFolders(_ p1: Int) -> String {
      return Strings.tr("Localizable", "Added 1 file and %lld folders", p1)
    }
    /// Added 1 file and 1 folder
    public static let added1FileAnd1Folder = Strings.tr("Localizable", "Added 1 file and 1 folder")
    /// Added 1 folder
    public static let added1Folder = Strings.tr("Localizable", "Added 1 folder")
    /// Added [A] files and [B] folders
    public static let addedAFilesAndBFolders = Strings.tr("Localizable", "Added [A] files and [B] folders")
    /// Add files
    public static let addFiles = Strings.tr("Localizable", "addFiles")
    /// Add from Contacts
    public static let addFromContacts = Strings.tr("Localizable", "addFromContacts")
    /// Enter an email address
    public static let addFromEmail = Strings.tr("Localizable", "addFromEmail")
    /// Add Participant…
    public static let addParticipant = Strings.tr("Localizable", "addParticipant")
    /// Add participants
    public static let addParticipants = Strings.tr("Localizable", "addParticipants")
    /// Administrator
    public static let administrator = Strings.tr("Localizable", "Administrator")
    /// Advanced
    public static let advanced = Strings.tr("Localizable", "advanced")
    /// After that, your data is subject to deletion.
    public static let afterThatYourDataIsSubjectToDeletion = Strings.tr("Localizable", "After that, your data is subject to deletion.")
    /// Agree
    public static let agree = Strings.tr("Localizable", "agree")
    /// I understand that [S]if I lose my password, I may lose my data.[/S] Read more about <a href="terms">MEGA’s end-to-end encryption</a>.
    public static let agreeWithLosingPasswordYouLoseData = Strings.tr("Localizable", "agreeWithLosingPasswordYouLoseData")
    /// I agree with the MEGA <a href="terms">Terms of Service</a>
    public static let agreeWithTheMEGATermsOfService = Strings.tr("Localizable", "agreeWithTheMEGATermsOfService")
    /// Albums
    public static let albums = Strings.tr("Localizable", "Albums")
    /// Alias or nickname
    public static let aliasNickname = Strings.tr("Localizable", "Alias/ Nickname")
    /// All
    public static let all = Strings.tr("Localizable", "all")
    /// All Media
    public static let allMedia = Strings.tr("Localizable", "All Media")
    /// All the photos from your burst photo sequences will be uploaded.
    public static let allThePhotosFromYourBurstPhotoSequencesWillBeUploaded = Strings.tr("Localizable", "All the photos from your burst photo sequences will be uploaded.")
    /// ALL transfers
    public static let allInUppercaseTransfers = Strings.tr("Localizable", "allInUppercaseTransfers")
    /// Allow Access
    public static let allowAccess = Strings.tr("Localizable", "Allow Access")
    /// Allow Access to Photos
    public static let allowAccessToPhotos = Strings.tr("Localizable", "Allow Access to Photos")
    /// Allow your contacts to see the last time you were active on MEGA.
    public static let allowYourContactsToSeeTheLastTimeYouWereActiveOnMEGA = Strings.tr("Localizable", "Allow your contacts to see the last time you were active on MEGA.")
    /// You must enable In-App Purchases in your iOS Settings before restoring a purchase.
    public static let allowPurchaseMessage = Strings.tr("Localizable", "allowPurchase_message")
    /// Allow purchases
    public static let allowPurchaseTitle = Strings.tr("Localizable", "allowPurchase_title")
    /// Already exists
    public static let alreadyExists = Strings.tr("Localizable", "Already exists")
    /// %s is already a contact.
    public static func alreadyAContact(_ p1: UnsafePointer<CChar>) -> String {
      return Strings.tr("Localizable", "alreadyAContact", p1)
    }
    /// Always Allow
    public static let alwaysAllow = Strings.tr("Localizable", "alwaysAllow")
    /// App Icon
    public static let appIcon = Strings.tr("Localizable", "App Icon")
    /// App Version
    public static let appVersion = Strings.tr("Localizable", "App Version")
    /// In-App Purchases is disabled, please enable it in the iOS Settings
    public static let appPurchaseDisabled = Strings.tr("Localizable", "appPurchaseDisabled")
    /// Approve
    public static let approve = Strings.tr("Localizable", "approve")
    /// Archive Chat
    public static let archiveChat = Strings.tr("Localizable", "archiveChat")
    /// Are you sure you want to archive this conversation?
    public static let archiveChatMessage = Strings.tr("Localizable", "archiveChatMessage")
    /// Archived
    public static let archived = Strings.tr("Localizable", "archived")
    /// Archived chats
    public static let archivedChats = Strings.tr("Localizable", "archivedChats")
    /// Are you sure you want to change to a test server? Your account may suffer irrecoverable problems.
    public static let areYouSureYouWantToChangeToATestServerYourAccountMaySufferIrrecoverableProblems = Strings.tr("Localizable", "Are you sure you want to change to a test server? Your account may suffer irrecoverable problems")
    /// Are you sure you want to move the Camera Uploads folder to the Rubbish Bin? If so, a new folder will be automatically generated for Camera Uploads.
    public static let areYouSureYouWantToMoveCameraUploadsFolderToRubbishBinIfSoANewFolderWillBeAutoGeneratedForCameraUploads = Strings.tr("Localizable", "Are you sure you want to move Camera Uploads folder to Rubbish Bin? If so, a new folder will be auto-generated for Camera Uploads.")
    /// Are you sure you want to abort the registration?
    public static let areYouSureYouWantToAbortTheRegistration = Strings.tr("Localizable", "areYouSureYouWantToAbortTheRegistration")
    /// Ask us how you can upgrade to a custom plan:
    public static let askUsHowYouCanUpgradeToACustomPlan = Strings.tr("Localizable", "Ask us how you can upgrade to a custom plan:")
    /// Attached: %s
    public static func attachedFile(_ p1: UnsafePointer<CChar>) -> String {
      return Strings.tr("Localizable", "attachedFile", p1)
    }
    /// Attached %s files.
    public static func attachedXFiles(_ p1: UnsafePointer<CChar>) -> String {
      return Strings.tr("Localizable", "attachedXFiles", p1)
    }
    /// Attention
    public static let attention = Strings.tr("Localizable", "attention")
    /// Audio
    public static let audio = Strings.tr("Localizable", "Audio")
    /// Authenticator app required
    public static let authenticatorAppRequired = Strings.tr("Localizable", "Authenticator app required")
    /// [S]Authenticity.[/S] The system ensures that the data received is from the sender displayed, and its content has not been manipulated during transit.
    public static let authenticityExplanation = Strings.tr("Localizable", "authenticityExplanation")
    /// Auto-Accept
    public static let autoAccept = Strings.tr("Localizable", "autoAccept")
    /// MEGA users who scan your QR code will be automatically added to your contact list.
    public static let autoAcceptFooter = Strings.tr("Localizable", "autoAcceptFooter")
    /// Auto-away
    public static let autoAway = Strings.tr("Localizable", "autoAway")
    /// Automatically back up your photos and videos to your Cloud drive.
    public static let automaticallyBackupYourPhotosAndVideosToTheCloudDrive = Strings.tr("Localizable", "Automatically backup your photos and videos to the Cloud Drive.")
    /// Automatically delete messages older than a certain amount of time.
    public static let automaticallyDeleteMessagesOlderThanACertainAmountOfTime = Strings.tr("Localizable", "Automatically delete messages older than a certain amount of time")
    /// Automatically delete messages older than one day.
    public static let automaticallyDeleteMessagesOlderThanOneDay = Strings.tr("Localizable", "Automatically delete messages older than one day")
    /// Automatically delete messages older than one month.
    public static let automaticallyDeleteMessagesOlderThanOneMonth = Strings.tr("Localizable", "Automatically delete messages older than one month")
    /// Automatically delete messages older than one week.
    public static let automaticallyDeleteMessagesOlderThanOneWeek = Strings.tr("Localizable", "Automatically delete messages older than one week")
    /// Subscriptions are renewed automatically for successive subscription periods of the same duration and at the same price as the initial period chosen. You can switch off the automatic renewal of your MEGA Pro subscription no later than 24 hours before your next subscription payment is due via your iTunes account settings page. To manage your subscriptions, simply tap on the App Store icon on your mobile device, sign in with your Apple ID at the bottom of the page (if you haven’t already done so) and then tap View ID. You’ll be taken to your account page where you can scroll down to Manage App Subscriptions. From there, you can select your MEGA Pro subscription and view your scheduled renewal date, choose a different subscription package or toggle the on-off switch to off to disable the auto-renewal of your subscription.
    public static let autorenewableDescription = Strings.tr("Localizable", "autorenewableDescription")
    /// Available
    public static let availableLabel = Strings.tr("Localizable", "availableLabel")
    /// Awaiting email confirmation.
    public static let awaitingEmailConfirmation = Strings.tr("Localizable", "awaitingEmailConfirmation")
    /// Away
    public static let away = Strings.tr("Localizable", "away")
    /// Back up Recovery key
    public static let backupRecoveryKey = Strings.tr("Localizable", "backupRecoveryKey")
    /// Bad session ID
    public static let badSessionID = Strings.tr("Localizable", "Bad session ID")
    /// Balance error
    public static let balanceError = Strings.tr("Localizable", "Balance error")
    /// Begin Setup
    public static let beginSetup = Strings.tr("Localizable", "beginSetup")
    /// Billing failed
    public static let billingFailed = Strings.tr("Localizable", "Billing failed")
    /// Blocked
    public static let blocked = Strings.tr("Localizable", "Blocked")
    /// Blocked you as a contact
    public static let blockedYouAsAContact = Strings.tr("Localizable", "Blocked you as a contact")
    /// Blue
    public static let blue = Strings.tr("Localizable", "Blue")
    /// Business
    public static let business = Strings.tr("Localizable", "Business")
    /// Account deactivated
    public static let businessAccountHasExpired = Strings.tr("Localizable", "Business account has expired")
    /// Busy
    public static let busy = Strings.tr("Localizable", "busy")
    /// Audio
    public static let call = Strings.tr("Localizable", "Call")
    /// Call Started
    public static let callStarted = Strings.tr("Localizable", "Call Started")
    /// Call ended.
    public static let callEnded = Strings.tr("Localizable", "callEnded")
    /// Call failed
    public static let callFailed = Strings.tr("Localizable", "callFailed")
    /// Calling…
    public static let calling = Strings.tr("Localizable", "calling...")
    /// Call was cancelled
    public static let callWasCancelled = Strings.tr("Localizable", "callWasCancelled")
    /// Call was not answered
    public static let callWasNotAnswered = Strings.tr("Localizable", "callWasNotAnswered")
    /// Call was rejected
    public static let callWasRejected = Strings.tr("Localizable", "callWasRejected")
    /// Camera
    public static let camera = Strings.tr("Localizable", "Camera")
    /// Please give MEGA permission to access your Camera in Settings
    public static let cameraPermissions = Strings.tr("Localizable", "cameraPermissions")
    /// Camera uploads complete
    public static let cameraUploadsComplete = Strings.tr("Localizable", "cameraUploadsComplete")
    /// Camera Uploads enabled
    public static let cameraUploadsEnabled = Strings.tr("Localizable", "cameraUploadsEnabled")
    /// Camera Uploads
    public static let cameraUploadsLabel = Strings.tr("Localizable", "cameraUploadsLabel")
    /// Upload in progress, 1 file pending
    public static let cameraUploadsPendingFile = Strings.tr("Localizable", "cameraUploadsPendingFile")
    /// Upload in progress, %lu files pending
    public static func cameraUploadsPendingFiles(_ p1: Int) -> String {
      return Strings.tr("Localizable", "cameraUploadsPendingFiles", p1)
    }
    /// Cancel
    public static let cancel = Strings.tr("Localizable", "cancel")
    /// Cancellation link has expired.
    public static let cancellationLinkHasExpired = Strings.tr("Localizable", "cancellationLinkHasExpired")
    /// Cancelled
    public static let cancelled = Strings.tr("Localizable", "Cancelled")
    /// Cancelled their contact request
    public static let cancelledTheirContactRequest = Strings.tr("Localizable", "Cancelled their contact request")
    /// Do you want to cancel ALL transfers?
    public static let cancelTransfersText = Strings.tr("Localizable", "cancelTransfersText")
    /// Cancel transfers
    public static let cancelTransfersTitle = Strings.tr("Localizable", "cancelTransfersTitle")
    /// Delete Account
    public static let cancelYourAccount = Strings.tr("Localizable", "cancelYourAccount")
    /// Capture
    public static let capturePhotoVideo = Strings.tr("Localizable", "capturePhotoVideo")
    /// Change Email
    public static let changeEmail = Strings.tr("Localizable", "Change Email")
    /// Change Launch Tab
    public static let changeLaunchTab = Strings.tr("Localizable", "Change Launch Tab")
    /// Change Photo
    public static let changePhoto = Strings.tr("Localizable", "Change Photo")
    /// Change Setting
    public static let changeSetting = Strings.tr("Localizable", "Change Setting")
    /// Change to a test server?
    public static let changeToATestServer = Strings.tr("Localizable", "Change to a test server?")
    /// [A] changed the group chat name to “[B]”
    public static let changedGroupChatNameTo = Strings.tr("Localizable", "changedGroupChatNameTo")
    /// Change Name
    public static let changeName = Strings.tr("Localizable", "changeName")
    /// Change Passcode
    public static let changePasscodeLabel = Strings.tr("Localizable", "changePasscodeLabel")
    /// Change Password
    public static let changePasswordLabel = Strings.tr("Localizable", "changePasswordLabel")
    /// Chat
    public static let chat = Strings.tr("Localizable", "chat")
    /// Chat created on %s1
    public static func chatCreatedOnS1(_ p1: UnsafePointer<CChar>) -> String {
      return Strings.tr("Localizable", "Chat created on %s1", p1)
    }
    /// Chat history has been cleared
    public static let chatHistoryHasBeenCleared = Strings.tr("Localizable", "Chat History has Been Cleared")
    /// Chat link
    public static let chatLink = Strings.tr("Localizable", "Chat Link")
    /// Chat Link Unavailable
    public static let chatLinkUnavailable = Strings.tr("Localizable", "Chat Link Unavailable")
    /// Chat Notifications
    public static let chatNotifications = Strings.tr("Localizable", "Chat Notifications")
    /// MEGA protects your chat with end-to-end (user controlled) encryption providing essential safety assurances:
    public static let chatIntroductionMessage = Strings.tr("Localizable", "chatIntroductionMessage")
    /// Chat not found
    public static let chatNotFound = Strings.tr("Localizable", "chatNotFound")
    /// Chatting with
    public static let chattingWith = Strings.tr("Localizable", "chattingWith")
    /// Choose Your Country
    public static let chooseYourCountry = Strings.tr("Localizable", "Choose Your Country")
    /// Choose from Photos
    public static let choosePhotoVideo = Strings.tr("Localizable", "choosePhotoVideo")
    /// Choose one of the plans from below:
    public static let choosePlan = Strings.tr("Localizable", "choosePlan")
    /// Choose your account type
    public static let chooseYourAccountType = Strings.tr("Localizable", "chooseYourAccountType")
    /// Circular linkage detected
    public static let circularLinkageDetected = Strings.tr("Localizable", "Circular linkage detected")
    /// Clear
    public static let clear = Strings.tr("Localizable", "clear")
    /// Clear All
    public static let clearAll = Strings.tr("Localizable", "Clear All")
    /// Clear Messages Older Than
    public static let clearMessagesOlderThan = Strings.tr("Localizable", "Clear Messages Older Than")
    /// Clear Selected
    public static let clearSelected = Strings.tr("Localizable", "Clear Selected")
    /// Clear Cache
    public static let clearCache = Strings.tr("Localizable", "clearCache")
    /// Clear Chat History
    public static let clearChatHistory = Strings.tr("Localizable", "clearChatHistory")
    /// [A] cleared the chat history.
    public static let clearedTheChatHistory = Strings.tr("Localizable", "clearedTheChatHistory")
    /// Clear Offline Files
    public static let clearOfflineFiles = Strings.tr("Localizable", "clearOfflineFiles")
    /// Are you sure you want to clear the full message history of this conversation?
    public static let clearTheFullMessageHistory = Strings.tr("Localizable", "clearTheFullMessageHistory")
    /// Close
    public static let close = Strings.tr("Localizable", "close")
    /// Close account
    public static let closeAccount = Strings.tr("Localizable", "closeAccount")
    /// Close other sessions
    public static let closeOtherSessions = Strings.tr("Localizable", "closeOtherSessions")
    /// Cloud drive
    public static let cloudDrive = Strings.tr("Localizable", "cloudDrive")
    /// No files in your Cloud drive
    public static let cloudDriveEmptyStateTitle = Strings.tr("Localizable", "cloudDriveEmptyState_title")
    /// Empty Rubbish bin
    public static let cloudDriveEmptyStateTitleRubbishBin = Strings.tr("Localizable", "cloudDriveEmptyState_titleRubbishBin")
    /// [S]Your Cloud Drive is almost full.[/S] [A]Upgrade now[/A] to a Pro account and get [S]up to %@ TB (%@ GB)[/S] of cloud storage space.
    public static func cloudDriveIsAlmostFull(_ p1: Any, _ p2: Any) -> String {
      return Strings.tr("Localizable", "cloudDriveIsAlmostFull", String(describing: p1), String(describing: p2))
    }
    /// [S]Your Cloud Drive is full.[/S] [A]Upgrade now[/A] to a Pro account and get [S]up to %@ TB (%@ GB)[/S] of cloud storage space.
    public static func cloudDriveIsFull(_ p1: Any, _ p2: Any) -> String {
      return Strings.tr("Localizable", "cloudDriveIsFull", String(describing: p1), String(describing: p2))
    }
    /// Code scanned
    public static let codeScanned = Strings.tr("Localizable", "codeScanned")
    /// Completed
    public static let completed = Strings.tr("Localizable", "Completed")
    /// Completing…
    public static let completing = Strings.tr("Localizable", "Completing...")
    /// [S]Confidentiality.[/S] Only the author and intended recipients are able to decipher and read the content.
    public static let confidentialityExplanation = Strings.tr("Localizable", "confidentialityExplanation")
    /// Configure column sorting order on a per-folder basis, or use the same order for all folders.
    public static let configureColumnSortingOrderOnAPerFolderBasisOrUseTheSameOrderForAllFolders = Strings.tr("Localizable", "Configure column sorting order on a per-folder basis, or use the same order for all folders.")
    /// Configure default launch section.
    public static let configureDefaultLaunchSection = Strings.tr("Localizable", "Configure default launch section.")
    /// Configure sorting order and the default view (List or Thumbnail).
    public static let configureSortingOrderAndTheDefaultViewListOrThumbnail = Strings.tr("Localizable", "Configure sorting order and the default view (List or Thumbnail).")
    /// Confirm
    public static let confirm = Strings.tr("Localizable", "confirm")
    /// Confirm account
    public static let confirmAccount = Strings.tr("Localizable", "Confirm account")
    /// Confirm email
    public static let confirmEmail = Strings.tr("Localizable", "confirmEmail")
    /// Confirm new email
    public static let confirmNewEmail = Strings.tr("Localizable", "confirmNewEmail")
    /// Confirm Password
    public static let confirmPassword = Strings.tr("Localizable", "confirmPassword")
    /// Please enter your password to confirm your account
    public static let confirmText = Strings.tr("Localizable", "confirmText")
    /// Congratulations, your new email address for this MEGA account is: [X]
    public static let congratulationsNewEmailAddress = Strings.tr("Localizable", "congratulationsNewEmailAddress")
    /// Connecting…
    public static let connecting = Strings.tr("Localizable", "connecting")
    /// Connection overflow
    public static let connectionOverflow = Strings.tr("Localizable", "Connection overflow")
    /// Contact
    public static let contact = Strings.tr("Localizable", "Contact")
    /// Contact relationship established
    public static let contactRelationshipEstablished = Strings.tr("Localizable", "Contact relationship established")
    /// Contact your business account administrator to resolve the issue and activate your account.
    public static let contactYourBusinessAccountAdministratorToResolveTheIssueAndActivateYourAccount = Strings.tr("Localizable", "Contact your business account administrator to resolve the issue and activate your account.")
    /// Contact Credentials
    public static let contactCredentials = Strings.tr("Localizable", "contactCredentials")
    /// Contact email
    public static let contactEmail = Strings.tr("Localizable", "contactEmail")
    /// Contact Request
    public static let contactRequest = Strings.tr("Localizable", "contactRequest")
    /// Contact requests
    public static let contactRequests = Strings.tr("Localizable", "contactRequests")
    /// CONTACTS ON MEGA
    public static let contactsOnMega = Strings.tr("Localizable", "CONTACTS ON MEGA")
    /// No Contacts
    public static let contactsEmptyStateTitle = Strings.tr("Localizable", "contactsEmptyState_title")
    /// Contacts
    public static let contactsTitle = Strings.tr("Localizable", "contactsTitle")
    /// Contains
    public static let contains = Strings.tr("Localizable", "contains")
    /// Continue
    public static let `continue` = Strings.tr("Localizable", "continue")
    /// %1$s will continue at %2$s
    public static func continueOrRestartVideoMessage(_ p1: UnsafePointer<CChar>, _ p2: UnsafePointer<CChar>) -> String {
      return Strings.tr("Localizable", "continueOrRestartVideoMessage", p1, p2)
    }
    /// Copied to the clipboard
    public static let copiedToTheClipboard = Strings.tr("Localizable", "copiedToTheClipboard")
    /// Copy
    public static let copy = Strings.tr("Localizable", "copy")
    /// Copy All
    public static let copyAll = Strings.tr("Localizable", "Copy All")
    /// 1 file and 1 folder copied
    public static let copyFileFolderMessage = Strings.tr("Localizable", "copyFileFolderMessage")
    /// 1 file and %d folders copied
    public static func copyFileFoldersMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "copyFileFoldersMessage", p1)
    }
    /// 1 file copied
    public static let copyFileMessage = Strings.tr("Localizable", "copyFileMessage")
    /// %d files and 1 folder copied
    public static func copyFilesFolderMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "copyFilesFolderMessage", p1)
    }
    /// [A] files and [B] folders copied
    public static let copyFilesFoldersMessage = Strings.tr("Localizable", "copyFilesFoldersMessage")
    /// %d files copied
    public static func copyFilesMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "copyFilesMessage", p1)
    }
    /// 1 folder copied
    public static let copyFolderMessage = Strings.tr("Localizable", "copyFolderMessage")
    /// %d folders copied
    public static func copyFoldersMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "copyFoldersMessage", p1)
    }
    /// Copy key
    public static let copyKey = Strings.tr("Localizable", "copyKey")
    /// Copy link
    public static let copyLink = Strings.tr("Localizable", "copyLink")
    /// MEGA respects the copyrights of others and requires that users of the MEGA Cloud service comply with the laws of copyright.
    public static let copyrightMessagePart1 = Strings.tr("Localizable", "copyrightMessagePart1")
    /// You are strictly prohibited from using the MEGA Cloud service to infringe copyrights. You may not upload, download, store, share, display, stream, distribute, email, link to, transmit or otherwise make available any files, data or content that infringes any copyright or other proprietary rights of any person or entity.
    public static let copyrightMessagePart2 = Strings.tr("Localizable", "copyrightMessagePart2")
    /// Copyright warning
    public static let copyrightWarning = Strings.tr("Localizable", "copyrightWarning")
    /// Copyright warning to all users
    public static let copyrightWarningToAll = Strings.tr("Localizable", "copyrightWarningToAll")
    /// Could not save Item
    public static let couldNotSaveItem = Strings.tr("Localizable", "Could not save Item")
    /// Country
    public static let country = Strings.tr("Localizable", "Country")
    /// Create new file
    public static let createNewFile = Strings.tr("Localizable", "Create new file")
    /// Create your Network
    public static let createYourNetwork = Strings.tr("Localizable", "Create your Network")
    /// Create Account
    public static let createAccount = Strings.tr("Localizable", "createAccount")
    /// Create
    public static let createFolderButton = Strings.tr("Localizable", "createFolderButton")
    /// Credit card rejected
    public static let creditCardRejected = Strings.tr("Localizable", "Credit card rejected")
    /// Currently using %s
    public static func currentlyUsing(_ p1: UnsafePointer<CChar>) -> String {
      return Strings.tr("Localizable", "currentlyUsing", p1)
    }
    /// Current Version
    public static let currentVersion = Strings.tr("Localizable", "currentVersion")
    /// Current Versions
    public static let currentVersions = Strings.tr("Localizable", "currentVersions")
    /// Custom Alphanumeric Code
    public static let customAlphanumericCode = Strings.tr("Localizable", "Custom Alphanumeric Code")
    /// Custom Settings
    public static let customSettings = Strings.tr("Localizable", "Custom Settings")
    /// Custom…
    public static let custom = Strings.tr("Localizable", "Custom...")
    /// Data Protection Regulation
    public static let dataProtectionRegulationLabel = Strings.tr("Localizable", "dataProtectionRegulationLabel")
    /// day
    public static let day = Strings.tr("Localizable", "day")
    /// days
    public static let days = Strings.tr("Localizable", "days")
    /// Decrypt
    public static let decrypt = Strings.tr("Localizable", "decrypt")
    /// Decryption key
    public static let decryptionKey = Strings.tr("Localizable", "decryptionKey")
    /// To access this folder or file, you will need its Decryption key. If you do not have the key, please contact the creator of the link.
    public static let decryptionKeyAlertMessage = Strings.tr("Localizable", "decryptionKeyAlertMessage")
    /// Enter decryption key
    public static let decryptionKeyAlertTitle = Strings.tr("Localizable", "decryptionKeyAlertTitle")
    /// Invalid decryption key
    public static let decryptionKeyNotValid = Strings.tr("Localizable", "decryptionKeyNotValid")
    /// Default
    public static let `default` = Strings.tr("Localizable", "Default")
    /// Default Tab
    public static let defaultTab = Strings.tr("Localizable", "Default Tab")
    /// Delete
    public static let delete = Strings.tr("Localizable", "delete")
    /// Delete all older versions of my files
    public static let deleteAllOlderVersionsOfMyFiles = Strings.tr("Localizable", "Delete all older versions of my files")
    /// Delete Previous Versions
    public static let deletePreviousVersions = Strings.tr("Localizable", "Delete Previous Versions")
    /// Deleted you as a contact
    public static let deletedYouAsAContact = Strings.tr("Localizable", "Deleted you as a contact")
    /// Delete message
    public static let deleteMessage = Strings.tr("Localizable", "deleteMessage")
    /// Do you want to delete this version?
    public static let deleteVersion = Strings.tr("Localizable", "deleteVersion")
    /// Rejected your contact request
    public static let deniedYourContactRequest = Strings.tr("Localizable", "Denied your contact request")
    /// Your queued download exceeds the current transfer quota available for your account and may therefore be interrupted.
    public static let depletedTransferQuotaMessage = Strings.tr("Localizable", "depletedTransferQuota_message")
    /// Insufficient transfer quota
    public static let depletedTransferQuotaTitle = Strings.tr("Localizable", "depletedTransferQuota_title")
    /// DETAILS
    public static let details = Strings.tr("Localizable", "DETAILS")
    /// Device Storage Almost Full
    public static let deviceStorageAlmostFull = Strings.tr("Localizable", "Device Storage Almost Full")
    /// The log (MEGAiOS.log) will be deleted from the Offline section.
    public static let disableDebugModeMessage = Strings.tr("Localizable", "disableDebugMode_message")
    /// Disable debug mode
    public static let disableDebugModeTitle = Strings.tr("Localizable", "disableDebugMode_title")
    /// Disagree
    public static let disagree = Strings.tr("Localizable", "disagree")
    /// Discard Changes
    public static let discardChanges = Strings.tr("Localizable", "Discard Changes")
    /// Dismiss
    public static let dismiss = Strings.tr("Localizable", "dismiss")
    /// Dispute Takedown
    public static let disputeTakedown = Strings.tr("Localizable", "Dispute Takedown")
    /// Do Not Disturb
    public static let doNotDisturb = Strings.tr("Localizable", "Do Not Disturb")
    /// Do you want to close all other sessions? This will log you out on all other active sessions except the current one.
    public static let doYouWantToCloseAllOtherSessionsThisWillLogYouOutOnAllOtherActiveSessionsExceptTheCurrentOne = Strings.tr("Localizable", "Do you want to close all other sessions? This will log you out on all other active sessions except the current one.")
    /// Do you want to share the password for this link?
    public static let doYouWantToShareThePasswordForThisLink = Strings.tr("Localizable", "Do you want to share the password for this link?")
    /// Docs
    public static let docs = Strings.tr("Localizable", "Docs")
    /// Document scanning is not available
    public static let documentScanningIsNotAvailable = Strings.tr("Localizable", "Document scanning is not available")
    /// Documents
    public static let documents = Strings.tr("Localizable", "Documents")
    /// Done
    public static let done = Strings.tr("Localizable", "done")
    /// Do not show again
    public static let dontShowAgain = Strings.tr("Localizable", "dontShowAgain")
    /// Don’t use HTTP
    public static let dontUseHttp = Strings.tr("Localizable", "dontUseHttp")
    /// Download
    public static let download = Strings.tr("Localizable", "download")
    /// Download options
    public static let downloadOptions = Strings.tr("Localizable", "Download options")
    /// Download
    public static let downloadButton = Strings.tr("Localizable", "downloadButton")
    /// Downloading
    public static let downloading = Strings.tr("Localizable", "downloading")
    /// Downloading %@
    public static func downloading(_ p1: Any) -> String {
      return Strings.tr("Localizable", "Downloading %@", String(describing: p1))
    }
    /// DOWNLOAD transfers
    public static let downloadInUppercaseTransfers = Strings.tr("Localizable", "downloadInUppercaseTransfers")
    /// Downloads
    public static let downloads = Strings.tr("Localizable", "downloads")
    /// Download started
    public static let downloadStarted = Strings.tr("Localizable", "downloadStarted")
    /// Drag left to cancel, release to send
    public static let dragLeftToCancelReleaseToSend = Strings.tr("Localizable", "Drag left to cancel, release to send")
    /// Duration: %@
    public static func duration(_ p1: Any) -> String {
      return Strings.tr("Localizable", "duration", String(describing: p1))
    }
    /// Easily discover contacts from your address book on MEGA.
    public static let easilyDiscoverContactsFromYourAddressBookOnMEGA = Strings.tr("Localizable", "Easily discover contacts from your address book on MEGA.")
    /// Edit
    public static let edit = Strings.tr("Localizable", "edit")
    /// Edit Nickname
    public static let editNickname = Strings.tr("Localizable", "Edit Nickname")
    /// (edited)
    public static let edited = Strings.tr("Localizable", "edited")
    /// Email sent
    public static let emailSent = Strings.tr("Localizable", "Email sent")
    /// You have already requested a confirmation link for that email address.
    public static let emailAddressChangeAlreadyRequested = Strings.tr("Localizable", "emailAddressChangeAlreadyRequested")
    /// Error. This email address is already in use.
    public static let emailAlreadyInUse = Strings.tr("Localizable", "emailAlreadyInUse")
    /// This email address has already registered an account with MEGA
    public static let emailAlreadyRegistered = Strings.tr("Localizable", "emailAlreadyRegistered")
    /// Enter a valid email
    public static let emailInvalidFormat = Strings.tr("Localizable", "emailInvalidFormat")
    /// Please go to your inbox and click the link to confirm your new email address.
    public static let emailIsChangingDescription = Strings.tr("Localizable", "emailIsChanging_description")
    /// Email
    public static let emailPlaceholder = Strings.tr("Localizable", "emailPlaceholder")
    /// Emails do not match
    public static let emailsDoNotMatch = Strings.tr("Localizable", "emailsDoNotMatch")
    /// Empty Folder
    public static let emptyFolder = Strings.tr("Localizable", "emptyFolder")
    /// Empty Rubbish bin
    public static let emptyRubbishBin = Strings.tr("Localizable", "emptyRubbishBin")
    /// All the items in the Rubbish Bin will be deleted
    public static let emptyRubbishBinAlertTitle = Strings.tr("Localizable", "emptyRubbishBinAlertTitle")
    /// Enable
    public static let enable = Strings.tr("Localizable", "enable")
    /// Grant Access to Your Address Book
    public static let enableAccessToYourAddressBook = Strings.tr("Localizable", "Enable Access to Your Address Book")
    /// Enable Encryption Key Rotation
    public static let enableEncryptedKeyRotation = Strings.tr("Localizable", "Enable Encrypted Key Rotation")
    /// Enable Microphone and Camera
    public static let enableMicrophoneAndCamera = Strings.tr("Localizable", "Enable Microphone and Camera")
    /// Enable Notifications
    public static let enableNotifications = Strings.tr("Localizable", "Enable Notifications")
    /// Enable Camera Uploads
    public static let enableCameraUploadsButton = Strings.tr("Localizable", "enableCameraUploadsButton")
    /// Enabled
    public static let enabled = Strings.tr("Localizable", "Enabled")
    /// A log will be created in the Offline section (MEGAiOS.log). Logs can contain information related to your account.
    public static let enableDebugModeMessage = Strings.tr("Localizable", "enableDebugMode_message")
    /// Enable debug mode
    public static let enableDebugModeTitle = Strings.tr("Localizable", "enableDebugMode_title")
    /// Enable rich URL previews
    public static let enableRichUrlPreviews = Strings.tr("Localizable", "enableRichUrlPreviews")
    /// Encrypt
    public static let encrypt = Strings.tr("Localizable", "encrypt")
    /// Encrypted
    public static let encrypted = Strings.tr("Localizable", "encrypted")
    /// Encrypted chat
    public static let encryptedChat = Strings.tr("Localizable", "Encrypted chat")
    /// Encryption Key Rotation
    public static let encryptedKeyRotation = Strings.tr("Localizable", "Encrypted Key Rotation")
    /// Enter Email
    public static let enterEmail = Strings.tr("Localizable", "Enter Email")
    /// Enter group name
    public static let enterGroupName = Strings.tr("Localizable", "Enter group name")
    /// Enter the password
    public static let enterThePassword = Strings.tr("Localizable", "Enter the password")
    /// This is the last step to delete your account. You will permanently lose all the data stored in the cloud. Please enter your password below.
    public static let enterYourPasswordToConfirmThatYouWanToClose = Strings.tr("Localizable", "enterYourPasswordToConfirmThatYouWanToClose")
    /// Erase Local Data
    public static let eraseAllLocalDataLabel = Strings.tr("Localizable", "eraseAllLocalDataLabel")
    /// Error
    public static let error = Strings.tr("Localizable", "error")
    /// Expired
    public static let expired = Strings.tr("Localizable", "Expired")
    /// expires on %@
    public static func expiresOn(_ p1: Any) -> String {
      return Strings.tr("Localizable", "expiresOn", String(describing: p1))
    }
    /// Expiry Date
    public static let expiryDate = Strings.tr("Localizable", "Expiry Date")
    /// Export the link and decryption key separately.
    public static let exportTheLinkAndDecryptionKeySeparately = Strings.tr("Localizable", "Export the link and decryption key separately.")
    /// Exporting the Recovery key and keeping it in a secure location enables you to set a new password without data loss.
    public static let exportMasterKeyFooter = Strings.tr("Localizable", "exportMasterKeyFooter")
    /// Export Recovery key
    public static let exportRecoveryKey = Strings.tr("Localizable", "exportRecoveryKey")
    /// Failed permanently
    public static let failedPermanently = Strings.tr("Localizable", "Failed permanently")
    /// Failed to remove your phone number, please try again later.
    public static let failedToRemoveYourPhoneNumberPleaseTryAgainLater = Strings.tr("Localizable", "Failed to remove your phone number, please try again later.")
    /// failed to send the message
    public static let failedToSendTheMessage = Strings.tr("Localizable", "failed to send the message")
    /// You will be logged out and your offline files will be deleted after 10 failed attempts
    public static let failedAttempstSectionTitle = Strings.tr("Localizable", "failedAttempstSectionTitle")
    /// Either you cancelled the request or Apple reported a transaction error. Please try again later, or contact ios@mega.nz.
    public static let failedPurchaseMessage = Strings.tr("Localizable", "failedPurchase_message")
    /// Purchase stopped
    public static let failedPurchaseTitle = Strings.tr("Localizable", "failedPurchase_title")
    /// Either the request was cancelled or the prior purchase could not be restored. Please try again later, or contact ios@mega.nz.
    public static let failedRestoreMessage = Strings.tr("Localizable", "failedRestore_message")
    /// Restore stopped
    public static let failedRestoreTitle = Strings.tr("Localizable", "failedRestore_title")
    /// Favourite
    public static let favourite = Strings.tr("Localizable", "Favourite")
    /// Favourites
    public static let favourites = Strings.tr("Localizable", "Favourites")
    /// file
    public static let file = Strings.tr("Localizable", "file")
    /// File link unavailable
    public static let fileLinkUnavailable = Strings.tr("Localizable", "File link unavailable")
    /// File Management
    public static let fileManagement = Strings.tr("Localizable", "File Management")
    /// File Type
    public static let fileType = Strings.tr("Localizable", "File Type")
    /// File Versioning
    public static let fileVersioning = Strings.tr("Localizable", "File versioning")
    /// File Versions
    public static let fileVersions = Strings.tr("Localizable", "File Versions")
    /// File name
    public static let fileName = Strings.tr("Localizable", "file_name")
    /// [A] already uploaded with the name [B]
    public static let fileExistAlertControllerMessage = Strings.tr("Localizable", "fileExistAlertController_Message")
    /// 1 file and 1 folder moved to the Rubbish Bin
    public static let fileFolderMovedToRubbishBinMessage = Strings.tr("Localizable", "fileFolderMovedToRubbishBinMessage")
    /// 1 file and 1 folder removed from MEGA
    public static let fileFolderRemovedToRubbishBinMessage = Strings.tr("Localizable", "fileFolderRemovedToRubbishBinMessage")
    /// 1 file and %d folders moved to the Rubbish Bin
    public static func fileFoldersMovedToRubbishBinMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "fileFoldersMovedToRubbishBinMessage", p1)
    }
    /// 1 file and %d folders removed from MEGA
    public static func fileFoldersRemovedToRubbishBinMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "fileFoldersRemovedToRubbishBinMessage", p1)
    }
    /// File imported
    public static let fileImported = Strings.tr("Localizable", "fileImported")
    /// File Link
    public static let fileLink = Strings.tr("Localizable", "fileLink")
    /// This could be due to the following reasons:
    public static let fileLinkUnavailableText1 = Strings.tr("Localizable", "fileLinkUnavailableText1")
    /// The file has been removed as it violated our Terms of Service
    public static let fileLinkUnavailableText2 = Strings.tr("Localizable", "fileLinkUnavailableText2")
    /// Invalid URL - the link you are trying to access does not exist
    public static let fileLinkUnavailableText3 = Strings.tr("Localizable", "fileLinkUnavailableText3")
    /// The file has been deleted by the user.
    public static let fileLinkUnavailableText4 = Strings.tr("Localizable", "fileLinkUnavailableText4")
    /// 1 file moved to the Rubbish Bin
    public static let fileMovedToRubbishBinMessage = Strings.tr("Localizable", "fileMovedToRubbishBinMessage")
    /// File not supported
    public static let fileNotSupported = Strings.tr("Localizable", "fileNotSupported")
    /// 1 file removed from MEGA
    public static let fileRemovedToRubbishBinMessage = Strings.tr("Localizable", "fileRemovedToRubbishBinMessage")
    /// %d files
    public static func files(_ p1: Int) -> String {
      return Strings.tr("Localizable", "files", p1)
    }
    /// %d files selected were already uploaded into this folder.
    public static func filesAlreadyExistMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "filesAlreadyExistMessage", p1)
    }
    /// File sent to chat
    public static let fileSentToChat = Strings.tr("Localizable", "fileSentToChat")
    /// File sent to %1$d chats
    public static func fileSentToXChats(_ p1: Int) -> String {
      return Strings.tr("Localizable", "fileSentToXChats", p1)
    }
    /// %d files and 1 folder moved to the Rubbish Bin
    public static func filesFolderMovedToRubbishBinMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "filesFolderMovedToRubbishBinMessage", p1)
    }
    /// %d files and 1 folder removed from MEGA
    public static func filesFolderRemovedToRubbishBinMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "filesFolderRemovedToRubbishBinMessage", p1)
    }
    /// [A] files and [B] folders moved to the Rubbish Bin
    public static let filesFoldersMovedToRubbishBinMessage = Strings.tr("Localizable", "filesFoldersMovedToRubbishBinMessage")
    /// [A] files and [B] folders removed from MEGA
    public static let filesFoldersRemovedToRubbishBinMessage = Strings.tr("Localizable", "filesFoldersRemovedToRubbishBinMessage")
    /// Files imported
    public static let filesImported = Strings.tr("Localizable", "filesImported")
    /// %d files moved to the Rubbish Bin
    public static func filesMovedToRubbishBinMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "filesMovedToRubbishBinMessage", p1)
    }
    /// %d files removed from MEGA
    public static func filesRemovedToRubbishBinMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "filesRemovedToRubbishBinMessage", p1)
    }
    /// Files sent to chat
    public static let filesSentToChat = Strings.tr("Localizable", "filesSentToChat")
    /// The file you are trying to download is bigger than the available memory.
    public static let fileTooBigMessage = Strings.tr("Localizable", "fileTooBigMessage")
    /// The file you are trying to open is bigger than the available memory.
    public static let fileTooBigMessageOpen = Strings.tr("Localizable", "fileTooBigMessage_open")
    /// Filter
    public static let filter = Strings.tr("Localizable", "filter")
    /// First Name
    public static let firstName = Strings.tr("Localizable", "firstName")
    /// Folder
    public static let folder = Strings.tr("Localizable", "folder")
    /// Folder link unavailable
    public static let folderLinkUnavailable = Strings.tr("Localizable", "Folder link unavailable")
    /// The folder “%@” can’t be created
    public static func folderCreationError(_ p1: Any) -> String {
      return Strings.tr("Localizable", "folderCreationError", String(describing: p1))
    }
    /// Inbox is reserved for use by Apple.
    public static let folderInboxError = Strings.tr("Localizable", "folderInboxError")
    /// Folder Link
    public static let folderLink = Strings.tr("Localizable", "folderLink")
    /// This could be due to the following reasons:
    public static let folderLinkUnavailableText1 = Strings.tr("Localizable", "folderLinkUnavailableText1")
    /// The folder link has been removed as it violated our Terms of Service.
    public static let folderLinkUnavailableText2 = Strings.tr("Localizable", "folderLinkUnavailableText2")
    /// Invalid URL - the link you are trying to access does not exist
    public static let folderLinkUnavailableText3 = Strings.tr("Localizable", "folderLinkUnavailableText3")
    /// The folder link has been disabled by the user.
    public static let folderLinkUnavailableText4 = Strings.tr("Localizable", "folderLinkUnavailableText4")
    /// 1 folder moved to the Rubbish Bin
    public static let folderMovedToRubbishBinMessage = Strings.tr("Localizable", "folderMovedToRubbishBinMessage")
    /// 1 folder removed from MEGA
    public static let folderRemovedToRubbishBinMessage = Strings.tr("Localizable", "folderRemovedToRubbishBinMessage")
    /// %d folders moved to the Rubbish Bin
    public static func foldersMovedToRubbishBinMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "foldersMovedToRubbishBinMessage", p1)
    }
    /// %d folders removed from MEGA
    public static func foldersRemovedToRubbishBinMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "foldersRemovedToRubbishBinMessage", p1)
    }
    /// %d folders
    public static func foldersShared(_ p1: Int) -> String {
      return Strings.tr("Localizable", "foldersShared", p1)
    }
    /// The folder you are trying to download is bigger than the available memory.
    public static let folderTooBigMessage = Strings.tr("Localizable", "folderTooBigMessage")
    /// Forgot password?
    public static let forgotPassword = Strings.tr("Localizable", "forgotPassword")
    /// Forward
    public static let forward = Strings.tr("Localizable", "forward")
    /// Free
    public static let free = Strings.tr("Localizable", "Free")
    /// From Cloud drive
    public static let fromCloudDrive = Strings.tr("Localizable", "fromCloudDrive")
    /// Full access
    public static let fullAccess = Strings.tr("Localizable", "fullAccess")
    /// Fully encrypted chat with voice and video calls, group messaging and file sharing integration with your Cloud drive.
    public static let fullyEncryptedChatWithVoiceAndVideoCallsGroupMessagingAndFileSharingIntegrationWithYourCloudDrive = Strings.tr("Localizable", "Fully encrypted chat with voice and video calls, group messaging and file sharing integration with your Cloud Drive.")
    /// Generating link…
    public static let generatingLink = Strings.tr("Localizable", "generatingLink")
    /// Generating links…
    public static let generatingLinks = Strings.tr("Localizable", "generatingLinks")
    /// Get chat link
    public static let getChatLink = Strings.tr("Localizable", "Get Chat Link")
    /// Good
    public static let good = Strings.tr("Localizable", "good")
    /// Green
    public static let green = Strings.tr("Localizable", "Green")
    /// Grey
    public static let grey = Strings.tr("Localizable", "Grey")
    /// Group call ended
    public static let groupCallEnded = Strings.tr("Localizable", "Group call ended")
    /// Group Chat
    public static let groupChat = Strings.tr("Localizable", "groupChat")
    /// Groups
    public static let groups = Strings.tr("Localizable", "Groups")
    /// Help
    public static let help = Strings.tr("Localizable", "help")
    /// Help Centre
    public static let helpCentreLabel = Strings.tr("Localizable", "helpCentreLabel")
    /// History Clearing
    public static let historyClearing = Strings.tr("Localizable", "History Clearing")
    /// Home
    public static let home = Strings.tr("Localizable", "Home")
    /// How it works
    public static let howItWorks = Strings.tr("Localizable", "howItWorks")
    /// Your friend needs to register for a free account on MEGA and [S]install at least one MEGA client application[/S] (either the MEGA Desktop App or one of our MEGA Mobile Apps)
    public static let howItWorksMain = Strings.tr("Localizable", "howItWorksMain")
    /// You can notify your friend through any method. You will earn the quota if you have entered your friend’s email here prior to them registering with that address.
    public static let howItWorksSecondary = Strings.tr("Localizable", "howItWorksSecondary")
    /// You will not receive credit for inviting someone who has used MEGA previously and you will not be notified about such a rejection.
    public static let howItWorksTertiary = Strings.tr("Localizable", "howItWorksTertiary")
    /// HTTP Error
    public static let httpError = Strings.tr("Localizable", "HTTP error")
    /// If enabled, location information will be included with your pictures. Please be careful when sharing them.
    public static let ifEnabledYouWillUploadInformationAboutWhereYourPicturesAndVideosWereTakenSoBeCarefulWhenSharingThem = Strings.tr("Localizable", "If enabled, you will upload information about where your pictures and videos were taken, so be careful when sharing them.")
    /// If you do not have the password, contact the creator of the link.
    public static let ifYouDoNotHaveThePasswordContactTheCreatorOfTheLink = Strings.tr("Localizable", "If you do not have the password, contact the creator of the link.")
    /// If you lose this Recovery key and forget your password, [B]all your files, folders and messages will be inaccessible, even by MEGA[/B].
    public static let ifYouLoseThisRecoveryKeyAndForgetYourPasswordBAllYourFilesFoldersAndMessagesWillBeInaccessibleEvenByMEGAB = Strings.tr("Localizable", "If you lose this Recovery key and forget your password, [B]all your files, folders and messages will be inaccessible, even by MEGA[/B].")
    /// If you can’t access your email, please contact support@mega.nz
    public static let ifYouCantAccessYourEmailAccount = Strings.tr("Localizable", "ifYouCantAccessYourEmailAccount")
    /// Ignore
    public static let ignore = Strings.tr("Localizable", "ignore")
    /// Image Quality
    public static let imageQuality = Strings.tr("Localizable", "Image Quality")
    /// Images or videos downloaded will be stored in the device’s media library instead of the Offline section.
    public static let imagesAndOrVideosDownloadedWillBeStoredInTheDeviceSMediaLibraryInsteadOfTheOfflineSection = Strings.tr("Localizable", "Images and/or videos downloaded will be stored in the device’s media library instead of the Offline section.")
    /// Immediately
    public static let immediately = Strings.tr("Localizable", "Immediately")
    /// Import
    public static let importToCloudDrive = Strings.tr("Localizable", "Import to Cloud Drive")
    /// In Progress
    public static let inProgress = Strings.tr("Localizable", "In Progress")
    /// Inactive chat
    public static let inactiveChat = Strings.tr("Localizable", "Inactive chat")
    /// Include Location Tags
    public static let includeLocationTags = Strings.tr("Localizable", "Include Location Tags")
    /// Incoming
    public static let incoming = Strings.tr("Localizable", "incoming")
    /// Incoming call
    public static let incomingCall = Strings.tr("Localizable", "Incoming call")
    /// Incoming Shares
    public static let incomingShares = Strings.tr("Localizable", "incomingShares")
    /// Incomplete
    public static let incomplete = Strings.tr("Localizable", "Incomplete")
    /// The previous purchase could not be found. Please select the previously purchased product to restore. You will NOT be charged again.
    public static let incompleteRestoreMessage = Strings.tr("Localizable", "incompleteRestore_message")
    /// Restore issue
    public static let incompleteRestoreTitle = Strings.tr("Localizable", "incompleteRestore_title")
    /// Info
    public static let info = Strings.tr("Localizable", "info")
    /// Insert your friends’ emails:
    public static let insertYourFriendsEmails = Strings.tr("Localizable", "insertYourFriendsEmails")
    /// Internal error
    public static let internalError = Strings.tr("Localizable", "Internal error")
    /// Invalid application key
    public static let invalidApplicationKey = Strings.tr("Localizable", "Invalid application key")
    /// Invalid argument
    public static let invalidArgument = Strings.tr("Localizable", "Invalid argument")
    /// Decryption error
    public static let invalidKeyDecryptionError = Strings.tr("Localizable", "Invalid key/Decryption error")
    /// Invalid code
    public static let invalidCode = Strings.tr("Localizable", "invalidCode")
    /// Invalid email or password. Please try again.
    public static let invalidMailOrPassword = Strings.tr("Localizable", "invalidMailOrPassword")
    /// Invalid Recovery key
    public static let invalidRecoveryKey = Strings.tr("Localizable", "invalidRecoveryKey")
    /// Invite
    public static let invite = Strings.tr("Localizable", "invite")
    /// Invite 1 contact
    public static let invite1Contact = Strings.tr("Localizable", "Invite 1 contact")
    /// Invite [X] contacts
    public static let inviteXContacts = Strings.tr("Localizable", "Invite [X] contacts")
    /// Invite contacts now
    public static let inviteContactNow = Strings.tr("Localizable", "Invite contact now")
    /// Invite contacts and start chatting securely with MEGA’s encrypted chat.
    public static let inviteContactsAndStartChattingSecurelyWithMEGASEncryptedChat = Strings.tr("Localizable", "Invite contacts and start chatting securely with MEGA’s encrypted chat.")
    /// Invite to MEGA
    public static let inviteContact = Strings.tr("Localizable", "inviteContact")
    /// Invite Sent
    public static let inviteSent = Strings.tr("Localizable", "inviteSent")
    /// %@ is typing…
    public static func isTyping(_ p1: Any) -> String {
      return Strings.tr("Localizable", "isTyping", String(describing: p1))
    }
    /// It is not possible to play media files while there is a call in progress.
    public static let itIsNotPossibleToPlayContentWhileThereIsACallInProgress = Strings.tr("Localizable", "It is not possible to play content while there is a call in progress")
    /// It is not possible to record voice messages while there is a call in progress.
    public static let itIsNotPossibleToRecordVoiceMessagesWhileThereIsACallInProgress = Strings.tr("Localizable", "It is not possible to record voice messages while there is a call in progress")
    /// It is possible that you are using the same password for your MEGA account as for other services, and that at least one of these other services has suffered a data breach.
    public static let itIsPossibleThatYouAreUsingTheSamePasswordForYourMEGAAccountAsForOtherServicesAndThatAtLeastOneOfTheseOtherServicesHasSufferedADataBreach = Strings.tr("Localizable", "It is possible that you are using the same password for your MEGA account as for other services, and that at least one of these other services has suffered a data breach.")
    /// %lu items selected
    public static func itemsSelected(_ p1: Int) -> String {
      return Strings.tr("Localizable", "itemsSelected", p1)
    }
    /// Join
    public static let join = Strings.tr("Localizable", "Join")
    /// Join Beta
    public static let joinBeta = Strings.tr("Localizable", "Join Beta")
    /// [A] joined the group chat by invitation from [B].
    public static let joinedTheGroupChatByInvitationFrom = Strings.tr("Localizable", "joinedTheGroupChatByInvitationFrom")
    /// Joining…
    public static let joining = Strings.tr("Localizable", "Joining...")
    /// Jump to latest
    public static let jumpToLatest = Strings.tr("Localizable", "jumpToLatest")
    /// KEY
    public static let key = Strings.tr("Localizable", "KEY")
    /// Key Copied to Clipboard
    public static let keyCopiedToClipboard = Strings.tr("Localizable", "Key Copied to Clipboard")
    /// Encryption key rotation is disabled for conversations with more than 100 participants.
    public static let keyRotationIsDisabledForConversationsWithMoreThan100Participants = Strings.tr("Localizable", "Key rotation is disabled for conversations with more than 100 participants.")
    /// Encryption key rotation is slightly more secure, but does not allow you to create a chat link and new participants will not see past messages.
    public static let keyRotationIsSlightlyMoreSecureButDoesNotAllowYouToCreateAChatLinkAndNewParticipantsWillNotSeePastMessages = Strings.tr("Localizable", "Key rotation is slightly more secure, but does not allow you to create a chat link and new participants will not see past messages.")
    /// Largest
    public static let largest = Strings.tr("Localizable", "largest")
    /// Last seen: %s
    public static func lastSeenS(_ p1: UnsafePointer<CChar>) -> String {
      return Strings.tr("Localizable", "Last seen %s", p1)
    }
    /// Last seen a long time ago
    public static let lastSeenALongTimeAgo = Strings.tr("Localizable", "Last seen a long time ago")
    /// Last Name
    public static let lastName = Strings.tr("Localizable", "lastName")
    /// Later
    public static let later = Strings.tr("Localizable", "later")
    /// Launch
    public static let launch = Strings.tr("Localizable", "Launch")
    /// Launch the MEGA App to perform an action
    public static let launchTheMEGAAppToPerformAnAction = Strings.tr("Localizable", "Launch the MEGA app to perform an action")
    /// Layout
    public static let layout = Strings.tr("Localizable", "Layout")
    /// Learn more
    public static let learnMore = Strings.tr("Localizable", "Learn more")
    /// Leave
    public static let leave = Strings.tr("Localizable", "leave")
    /// Leave
    public static let leaveFolder = Strings.tr("Localizable", "leaveFolder")
    /// Leave Group
    public static let leaveGroup = Strings.tr("Localizable", "leaveGroup")
    /// Are you sure you want to leave this share?
    public static let leaveShareAlertMessage = Strings.tr("Localizable", "leaveShareAlertMessage")
    /// Are you sure you want to leave these shares?
    public static let leaveSharesAlertMessage = Strings.tr("Localizable", "leaveSharesAlertMessage")
    /// Leaving…
    public static let leaving = Strings.tr("Localizable", "Leaving...")
    /// [A] left the group chat.
    public static let leftTheGroupChat = Strings.tr("Localizable", "leftTheGroupChat")
    /// Line up the QR code to scan it with your device’s camera
    public static let lineCodeWithCamera = Strings.tr("Localizable", "lineCodeWithCamera")
    /// LINK
    public static let link = Strings.tr("Localizable", "LINK")
    /// Link Copied to Clipboard
    public static let linkCopiedToClipboard = Strings.tr("Localizable", "Link Copied to Clipboard")
    /// Link Creation
    public static let linkCreation = Strings.tr("Localizable", "Link Creation")
    /// Link expires %@
    public static func linkExpires(_ p1: Any) -> String {
      return Strings.tr("Localizable", "Link expires %@", String(describing: p1))
    }
    /// Link Password
    public static let linkPassword = Strings.tr("Localizable", "Link Password")
    /// Link copied
    public static let linkCopied = Strings.tr("Localizable", "linkCopied")
    /// Invalid link
    public static let linkNotValid = Strings.tr("Localizable", "linkNotValid")
    /// Links
    public static let links = Strings.tr("Localizable", "Links")
    /// Links Copied to Clipboard
    public static let linksCopiedToClipboard = Strings.tr("Localizable", "Links Copied to Clipboard")
    /// Links copied
    public static let linksCopied = Strings.tr("Localizable", "linksCopied")
    /// Unavailable link
    public static let linkUnavailable = Strings.tr("Localizable", "linkUnavailable")
    /// Link with key
    public static let linkWithKey = Strings.tr("Localizable", "linkWithKey")
    /// Link without key
    public static let linkWithoutKey = Strings.tr("Localizable", "linkWithoutKey")
    /// List View
    public static let listView = Strings.tr("Localizable", "List View")
    /// Loading…
    public static let loading = Strings.tr("Localizable", "loading")
    /// Local
    public static let localLabel = Strings.tr("Localizable", "localLabel")
    /// Locked Accounts
    public static let lockedAccounts = Strings.tr("Localizable", "Locked Accounts")
    /// Logged out
    public static let loggedOutAlertTitle = Strings.tr("Localizable", "loggedOut_alertTitle")
    /// You have been logged out of this device from another location
    public static let loggedOutFromAnotherLocation = Strings.tr("Localizable", "loggedOutFromAnotherLocation")
    /// Logging out
    public static let loggingOut = Strings.tr("Localizable", "loggingOut")
    /// Log in
    public static let login = Strings.tr("Localizable", "login")
    /// Log out
    public static let logoutLabel = Strings.tr("Localizable", "logoutLabel")
    /// Lost your Authenticator device?
    public static let lostYourAuthenticatorDevice = Strings.tr("Localizable", "lostYourAuthenticatorDevice")
    /// Maintain my chosen status appearance even when I have no connected devices.
    public static let maintainMyChosenStatusAppearance = Strings.tr("Localizable", "maintainMyChosenStatusAppearance")
    /// Manage
    public static let manage = Strings.tr("Localizable", "Manage")
    /// Manage Account
    public static let manageAccount = Strings.tr("Localizable", "Manage Account")
    /// Manage Chat History
    public static let manageChatHistory = Strings.tr("Localizable", "Manage Chat History")
    /// Manage share
    public static let manageShare = Strings.tr("Localizable", "Manage Share")
    /// Map settings
    public static let mapSettings = Strings.tr("Localizable", "Map settings")
    /// Mark as Read
    public static let markAsRead = Strings.tr("Localizable", "Mark as Read")
    /// Recovery key exported
    public static let masterKeyExported = Strings.tr("Localizable", "masterKeyExported")
    /// The Recovery key has been exported into the Offline section as MEGA-RECOVERYKEY.txt. Note: It will be deleted if you log out, please store it in a safe place.
    public static let masterKeyExportedAlertMessage = Strings.tr("Localizable", "masterKeyExported_alertMessage")
    /// Me
    public static let me = Strings.tr("Localizable", "me")
    /// MEGA CAMERA UPLOADS FOLDER
    public static let megaCameraUploadsFolder = Strings.tr("Localizable", "MEGA CAMERA UPLOADS FOLDER")
    /// MEGA will not use this data for any other purpose and will never interact with your contacts without your consent.
    public static let megaWillNotUseThisDataForAnyOtherPurposeAndWillNeverInteractWithYourContactsWithoutYourConsent = Strings.tr("Localizable", "MEGA will not use this data for any other purpose and will never interact with your contacts without your consent.")
    /// MEGA Chat SDK Version
    public static let megachatSdkVersion = Strings.tr("Localizable", "megachatSdkVersion")
    /// Message
    public static let message = Strings.tr("Localizable", "Message")
    /// message sending cancelled
    public static let messageSendingCancelled = Strings.tr("Localizable", "message sending cancelled")
    /// message sent
    public static let messageSent = Strings.tr("Localizable", "message sent")
    /// You can save it for Offline and open it in a compatible app.
    public static let messageFileNotSupported = Strings.tr("Localizable", "message_fileNotSupported")
    /// Messages sent
    public static let messagesSent = Strings.tr("Localizable", "messagesSent")
    /// Please give MEGA permission to access your Microphone in Settings
    public static let microphonePermissions = Strings.tr("Localizable", "microphonePermissions")
    /// Minimal
    public static let minimal = Strings.tr("Localizable", "Minimal")
    /// Missed call
    public static let missedCall = Strings.tr("Localizable", "missedCall")
    /// If you have misspelled your email address, correct it and click “Resend”.
    public static let misspelledEmailAddress = Strings.tr("Localizable", "misspelledEmailAddress")
    /// Mobile Data is turned off
    public static let mobileDataIsTurnedOff = Strings.tr("Localizable", "Mobile Data is turned off")
    /// Host
    public static let moderator = Strings.tr("Localizable", "moderator")
    /// Modified
    public static let modified = Strings.tr("Localizable", "modified")
    /// Modify Phone Number
    public static let modifyPhoneNumber = Strings.tr("Localizable", "Modify Phone Number")
    /// Monthly
    public static let monthly = Strings.tr("Localizable", "monthly")
    /// months
    public static let months = Strings.tr("Localizable", "months")
    /// More
    public static let more = Strings.tr("Localizable", "more")
    /// %1$s [A]and more are typing…[/A]
    public static func moreThanTwoUsersAreTyping(_ p1: UnsafePointer<CChar>) -> String {
      return Strings.tr("Localizable", "moreThanTwoUsersAreTyping", p1)
    }
    /// Move
    public static let move = Strings.tr("Localizable", "move")
    /// 1 file and 1 folder moved
    public static let moveFileFolderMessage = Strings.tr("Localizable", "moveFileFolderMessage")
    /// 1 file and %d folders moved
    public static func moveFileFoldersMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "moveFileFoldersMessage", p1)
    }
    /// 1 file moved
    public static let moveFileMessage = Strings.tr("Localizable", "moveFileMessage")
    /// %d files and 1 folder moved
    public static func moveFilesFolderMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "moveFilesFolderMessage", p1)
    }
    /// [A] files and [B] folders moved
    public static let moveFilesFoldersMessage = Strings.tr("Localizable", "moveFilesFoldersMessage")
    /// %d files moved
    public static func moveFilesMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "moveFilesMessage", p1)
    }
    /// 1 folder moved
    public static let moveFolderMessage = Strings.tr("Localizable", "moveFolderMessage")
    /// %d folders moved
    public static func moveFoldersMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "moveFoldersMessage", p1)
    }
    /// Two-factor authentication required
    public static let multiFactorAuthenticationRequired = Strings.tr("Localizable", "Multi-factor authentication required")
    /// Mute
    public static let mute = Strings.tr("Localizable", "mute")
    /// Mute chat notifications for
    public static let muteChatNotificationsFor = Strings.tr("Localizable", "Mute chat Notifications for")
    /// My Account
    public static let myAccount = Strings.tr("Localizable", "My Account")
    /// My chat files
    public static let myChatFiles = Strings.tr("Localizable", "My chat files")
    /// My chats
    public static let myChats = Strings.tr("Localizable", "My chats")
    /// My credentials
    public static let myCredentials = Strings.tr("Localizable", "My credentials")
    /// My QR code
    public static let myQRCode = Strings.tr("Localizable", "My QR code")
    /// Name
    public static let name = Strings.tr("Localizable", "name")
    /// Name (ascending)
    public static let nameAscending = Strings.tr("Localizable", "nameAscending")
    /// Name (descending)
    public static let nameDescending = Strings.tr("Localizable", "nameDescending")
    /// Enter a valid name
    public static let nameInvalidFormat = Strings.tr("Localizable", "nameInvalidFormat")
    /// You need to be logged in to complete your email change. Please log in again with your current email address, then tap on your confirmation link again.
    public static let needToBeLoggedInToCompleteYourEmailChange = Strings.tr("Localizable", "needToBeLoggedInToCompleteYourEmailChange")
    /// Never
    public static let never = Strings.tr("Localizable", "never")
    /// New
    public static let new = Strings.tr("Localizable", "New")
    /// New Camera uploads options
    public static let newCameraUpload = Strings.tr("Localizable", "New Camera Upload!")
    /// New Chat Link
    public static let newChatLink = Strings.tr("Localizable", "New Chat Link")
    /// New Group Chat
    public static let newGroupChat = Strings.tr("Localizable", "New Group Chat")
    /// New Text File
    public static let newTextFile = Strings.tr("Localizable", "new_text_file")
    /// New email address
    public static let newEmail = Strings.tr("Localizable", "newEmail")
    /// Newest
    public static let newest = Strings.tr("Localizable", "newest")
    /// New Folder
    public static let newFolder = Strings.tr("Localizable", "newFolder")
    /// Name for the new folder
    public static let newFolderMessage = Strings.tr("Localizable", "newFolderMessage")
    /// New messages
    public static let newMessages = Strings.tr("Localizable", "newMessages")
    /// New password
    public static let newPassword = Strings.tr("Localizable", "newPassword")
    /// New Shared Folder
    public static let newSharedFolder = Strings.tr("Localizable", "newSharedFolder")
    /// Next
    public static let next = Strings.tr("Localizable", "next")
    /// Night
    public static let night = Strings.tr("Localizable", "Night")
    /// No
    public static let no = Strings.tr("Localizable", "no")
    /// No audio files found
    public static let noAudioFilesFound = Strings.tr("Localizable", "No audio files found")
    /// No chat link available.
    public static let noChatLinkAvailable = Strings.tr("Localizable", "No chat link available.")
    /// No documents found
    public static let noDocumentsFound = Strings.tr("Localizable", "No documents found")
    /// No error
    public static let noError = Strings.tr("Localizable", "No error")
    /// No Favourites
    public static let noFavourites = Strings.tr("Localizable", "No Favourites")
    /// No GIFs found
    public static let noGIFsFound = Strings.tr("Localizable", "No GIFs found")
    /// No notifications
    public static let noNotifications = Strings.tr("Localizable", "No notifications")
    /// No Photos or Videos
    public static let noPhotosOrVideos = Strings.tr("Localizable", "No Photos or Videos")
    /// No proxy
    public static let noProxy = Strings.tr("Localizable", "No proxy")
    /// No public links
    public static let noPublicLinks = Strings.tr("Localizable", "No Public Links")
    /// No Recent Activity
    public static let noRecentActivity = Strings.tr("Localizable", "No recent activity")
    /// No Shared Files
    public static let noSharedFiles = Strings.tr("Localizable", "No Shared Files")
    /// No videos found
    public static let noVideosFound = Strings.tr("Localizable", "No videos found")
    /// No Archived Chats
    public static let noArchivedChats = Strings.tr("Localizable", "noArchivedChats")
    /// No camera available
    public static let noCamera = Strings.tr("Localizable", "noCamera")
    /// No conversation history
    public static let noConversationHistory = Strings.tr("Localizable", "noConversationHistory")
    /// No Conversations
    public static let noConversations = Strings.tr("Localizable", "noConversations")
    /// You need to free some space on your device
    public static let nodeTooBig = Strings.tr("Localizable", "nodeTooBig")
    /// No email account set up on your device
    public static let noEmailAccountConfigured = Strings.tr("Localizable", "noEmailAccountConfigured")
    /// No incoming Shared Folders
    public static let noIncomingSharedItemsEmptyStateText = Strings.tr("Localizable", "noIncomingSharedItemsEmptyState_text")
    /// No Internet connection
    public static let noInternetConnection = Strings.tr("Localizable", "noInternetConnection")
    /// There’s no need to add your own email address
    public static let noNeedToAddYourOwnEmailAddress = Strings.tr("Localizable", "noNeedToAddYourOwnEmailAddress")
    /// No outgoing Shared Folders
    public static let noOutgoingSharedItemsEmptyStateText = Strings.tr("Localizable", "noOutgoingSharedItemsEmptyState_text")
    /// No pending requests
    public static let noRequestPending = Strings.tr("Localizable", "noRequestPending")
    /// No Results
    public static let noResults = Strings.tr("Localizable", "noResults")
    /// Not enough quota
    public static let notEnoughQuota = Strings.tr("Localizable", "Not enough quota")
    /// Not found
    public static let notFound = Strings.tr("Localizable", "Not found")
    /// Notifications
    public static let notifications = Strings.tr("Localizable", "notifications")
    /// Notifications muted
    public static let notificationsMuted = Strings.tr("Localizable", "Notifications muted")
    /// Notifications will be silenced until %@
    public static func notificationsWillBeSilencedUntil(_ p1: Any) -> String {
      return Strings.tr("Localizable", "Notifications will be silenced until %@", String(describing: p1))
    }
    /// Notifications will be muted until tomorrow, %@
    public static func notificationsWillBeSilencedUntilTomorrow(_ p1: Any) -> String {
      return Strings.tr("Localizable", "Notifications will be silenced until tomorrow, %@", String(describing: p1))
    }
    /// Not Now
    public static let notNow = Strings.tr("Localizable", "notNow")
    /// MEGA accesses your location when you share it with your contacts in chat.
    public static let nsLocationWhenInUseUsageDescription = Strings.tr("Localizable", "NSLocationWhenInUseUsageDescription")
    /// Observers
    public static let observers = Strings.tr("Localizable", "Observers")
    /// Off
    public static let off = Strings.tr("Localizable", "off")
    /// Offline
    public static let offline = Strings.tr("Localizable", "offline")
    /// No files Saved for Offline
    public static let offlineEmptyStateTitle = Strings.tr("Localizable", "offlineEmptyState_title")
    /// OK
    public static let ok = Strings.tr("Localizable", "ok")
    /// The new and the old email must not match
    public static let oldAndNewEmailMatch = Strings.tr("Localizable", "oldAndNewEmailMatch")
    /// Oldest
    public static let oldest = Strings.tr("Localizable", "oldest")
    /// On
    public static let on = Strings.tr("Localizable", "on")
    /// One Day
    public static let oneDay = Strings.tr("Localizable", "One Day")
    /// One Month
    public static let oneMonth = Strings.tr("Localizable", "One Month")
    /// One Week
    public static let oneWeek = Strings.tr("Localizable", "One Week")
    /// 1 contact
    public static let oneContact = Strings.tr("Localizable", "oneContact")
    /// %d file
    public static func oneFile(_ p1: Int) -> String {
      return Strings.tr("Localizable", "oneFile", p1)
    }
    /// 1 folder
    public static let oneFolderShared = Strings.tr("Localizable", "oneFolderShared")
    /// %lu item selected
    public static func oneItemSelected(_ p1: Int) -> String {
      return Strings.tr("Localizable", "oneItemSelected", p1)
    }
    /// Ongoing Call
    public static let ongoingCall = Strings.tr("Localizable", "Ongoing Call")
    /// Online
    public static let online = Strings.tr("Localizable", "online")
    /// Only the photo version of each Live Photo will be uploaded.
    public static let onlyThePhotoInEachLivePhotoWillBeUploaded = Strings.tr("Localizable", "Only the photo in each Live Photo will be uploaded.")
    /// Only favourite photos from your burst photo sequences will be uploaded.
    public static let onlyTheRepresentativePhotosFromYourBurstPhotoSequencesWillBeUploaded = Strings.tr("Localizable", "Only the representative photos from your burst photo sequences will be uploaded.")
    /// On MEGA
    public static let onMEGA = Strings.tr("Localizable", "onMEGA")
    /// On your device
    public static let onYourDevice = Strings.tr("Localizable", "onYourDevice")
    /// Open Settings
    public static let openSettings = Strings.tr("Localizable", "Open Settings")
    /// Open browser
    public static let openBrowser = Strings.tr("Localizable", "openBrowser")
    /// Open
    public static let openButton = Strings.tr("Localizable", "openButton")
    /// Open in…
    public static let openIn = Strings.tr("Localizable", "openIn")
    /// Open MEGA and sign in to continue
    public static let openMEGAAndSignInToContinue = Strings.tr("Localizable", "openMEGAAndSignInToContinue")
    /// Options
    public static let options = Strings.tr("Localizable", "options")
    /// Options such as Send Decryption Key Separately, Set Expiry Date or Passwords are only available for single items.
    public static let optionsSuchAsSendDecryptionKeySeparatelySetExpiryDateOrPasswordsAreOnlyAvailableForSingleItems = Strings.tr("Localizable", "Options such as Send Decryption Key Separately, Set Expiry Date or Passwords are only available for single items.")
    /// Orange
    public static let orange = Strings.tr("Localizable", "Orange")
    /// Out of range
    public static let outOfRange = Strings.tr("Localizable", "Out of range")
    /// Outgoing
    public static let outgoing = Strings.tr("Localizable", "outgoing")
    /// Over quota
    public static let overQuota = Strings.tr("Localizable", "Over quota")
    /// Page View
    public static let pageView = Strings.tr("Localizable", "Page View")
    /// Park account
    public static let parkAccount = Strings.tr("Localizable", "parkAccount")
    /// Participants
    public static let participants = Strings.tr("Localizable", "participants")
    /// Passcode
    public static let passcode = Strings.tr("Localizable", "passcode")
    /// Passcode Options
    public static let passcodeOptions = Strings.tr("Localizable", "Passcode Options")
    /// Password Copied to Clipboard
    public static let passwordCopiedToClipboard = Strings.tr("Localizable", "Password Copied to Clipboard")
    /// Password Protection
    public static let passwordProtection = Strings.tr("Localizable", "Password Protection")
    /// Password Reminder
    public static let passwordReminder = Strings.tr("Localizable", "Password Reminder")
    /// Password accepted
    public static let passwordAccepted = Strings.tr("Localizable", "passwordAccepted")
    /// Your password has been changed.
    public static let passwordChanged = Strings.tr("Localizable", "passwordChanged")
    /// This password will withstand most typical brute-force attacks. Please ensure that you will remember it.
    public static let passwordGood = Strings.tr("Localizable", "passwordGood")
    /// Enter a valid password
    public static let passwordInvalidFormat = Strings.tr("Localizable", "passwordInvalidFormat")
    /// Your password is good enough to proceed, but it is recommended to strengthen your password further.
    public static let passwordMedium = Strings.tr("Localizable", "passwordMedium")
    /// Password
    public static let passwordPlaceholder = Strings.tr("Localizable", "passwordPlaceholder")
    /// Password reset
    public static let passwordReset = Strings.tr("Localizable", "passwordReset")
    /// Passwords do not match
    public static let passwordsDoNotMatch = Strings.tr("Localizable", "passwordsDoNotMatch")
    /// Medium
    public static let passwordStrengthMedium = Strings.tr("Localizable", "PasswordStrengthMedium")
    /// This password will withstand most sophisticated brute-force attacks. Please ensure that you will remember it.
    public static let passwordStrong = Strings.tr("Localizable", "passwordStrong")
    /// Your password is easily guessed. Try making your password longer. Combine uppercase and lowercase letters. Add special characters. Do not use names or dictionary words.
    public static let passwordVeryWeakOrWeak = Strings.tr("Localizable", "passwordVeryWeakOrWeak")
    /// Wrong password
    public static let passwordWrong = Strings.tr("Localizable", "passwordWrong")
    /// Pause All
    public static let pauseAll = Strings.tr("Localizable", "Pause All")
    /// Paused
    public static let paused = Strings.tr("Localizable", "paused")
    /// Payment info
    public static let paymentInfo = Strings.tr("Localizable", "Payment info")
    /// Payment overdue
    public static let paymentOverdue = Strings.tr("Localizable", "Payment overdue")
    /// Pending
    public static let pending = Strings.tr("Localizable", "pending")
    /// People can join your group by using this link.
    public static let peopleCanJoinYourGroupByUsingThisLink = Strings.tr("Localizable", "People can join your group by using this link.")
    /// Per Folder
    public static let perFolder = Strings.tr("Localizable", "Per Folder")
    /// It will be permanently removed
    public static let permanentlyRemoved = Strings.tr("Localizable", "permanentlyRemoved")
    /// Check your permissions on this folder
    public static let permissionMessage = Strings.tr("Localizable", "permissionMessage")
    /// Permissions
    public static let permissions = Strings.tr("Localizable", "permissions")
    /// Permissions changed
    public static let permissionsChanged = Strings.tr("Localizable", "permissionsChanged")
    /// Permission error
    public static let permissionTitle = Strings.tr("Localizable", "permissionTitle")
    /// Phone Number
    public static let phoneNumber = Strings.tr("Localizable", "Phone Number")
    /// Please give MEGA permission to access your Photos in Settings
    public static let photoLibraryPermissions = Strings.tr("Localizable", "photoLibraryPermissions")
    /// Photos and videos will be uploaded to the Camera Uploads folder.
    public static let photosAndVideosWillBeUploadedToCameraUploadsFolder = Strings.tr("Localizable", "Photos and videos will be uploaded to Camera Uploads folder.")
    /// Photos uploaded, video uploads are off; %lu videos not uploaded
    public static func photosUploadedVideoUploadsAreOffLuVideosNotUploaded(_ p1: Int) -> String {
      return Strings.tr("Localizable", "Photos uploaded, video uploads are off, %lu videos not uploaded", p1)
    }
    /// Photos uploaded, video uploads are off; 1 video not uploaded
    public static let photosUploadedVideoUploadsAreOff1VideoNotUploaded = Strings.tr("Localizable", "Photos uploaded, video uploads are off, 1 video not uploaded")
    /// Photos will be uploaded to the Camera Uploads folder.
    public static let photosWillBeUploadedToCameraUploadsFolder = Strings.tr("Localizable", "Photos will be uploaded to Camera Uploads folder.")
    /// Pinned Location
    public static let pinnedLocation = Strings.tr("Localizable", "Pinned Location")
    /// Plan
    public static let plan = Strings.tr("Localizable", "Plan")
    /// Playing
    public static let playing = Strings.tr("Localizable", "Playing")
    /// Please allow access
    public static let pleaseAllowAccess = Strings.tr("Localizable", "Please allow access")
    /// Please supply a valid phone number.
    public static let pleaseEnterAValidPhoneNumber = Strings.tr("Localizable", "Please enter a valid phone number")
    /// Please give MEGA permission to access Photos to share photos and videos.
    public static let pleaseGiveTheMEGAAppPermissionToAccessPhotosToSharePhotosAndVideos = Strings.tr("Localizable", "Please give the MEGA App permission to access Photos to share photos and videos.")
    /// Please enter the verification code sent to
    public static let pleaseTypeTheVerificationCodeSentTo = Strings.tr("Localizable", "Please type the verification code sent to")
    /// Please enter the 6-digit code generated by your Authenticator App.
    public static let pleaseEnterTheSixDigitCode = Strings.tr("Localizable", "pleaseEnterTheSixDigitCode")
    /// Please enter your Recovery key
    public static let pleaseEnterYourRecoveryKey = Strings.tr("Localizable", "pleaseEnterYourRecoveryKey")
    /// Please log in to your account.
    public static let pleaseLogInToYourAccount = Strings.tr("Localizable", "pleaseLogInToYourAccount")
    /// Please save your Recovery key in a safe location
    public static let pleaseSaveYourRecoveryKey = Strings.tr("Localizable", "pleaseSaveYourRecoveryKey")
    /// Please strengthen your password.
    public static let pleaseStrengthenYourPassword = Strings.tr("Localizable", "pleaseStrengthenYourPassword")
    /// Please write your feedback here:
    public static let pleaseWriteYourFeedback = Strings.tr("Localizable", "pleaseWriteYourFeedback")
    /// Port
    public static let port = Strings.tr("Localizable", "Port")
    /// Preparing…
    public static let preparing = Strings.tr("Localizable", "preparing...")
    /// Preview Content
    public static let previewContent = Strings.tr("Localizable", "previewContent")
    /// Previous Versions
    public static let previousVersions = Strings.tr("Localizable", "previousVersions")
    /// Privacy Policy
    public static let privacyPolicyLabel = Strings.tr("Localizable", "privacyPolicyLabel")
    /// Pro Lite
    public static let proLite = Strings.tr("Localizable", "Pro Lite")
    /// Pro membership plan expiring soon
    public static let proMembershipPlanExpiringSoon = Strings.tr("Localizable", "PRO membership plan expiring soon")
    /// Proceed to log out
    public static let proceedToLogout = Strings.tr("Localizable", "proceedToLogout")
    /// Product %@ is not found, please contact ios@mega.nz
    public static func productNotFound(_ p1: Any) -> String {
      return Strings.tr("Localizable", "productNotFound", String(describing: p1))
    }
    /// %@ per month
    public static func productPricePerMonth(_ p1: Any) -> String {
      return Strings.tr("Localizable", "productPricePerMonth", String(describing: p1))
    }
    /// Profile
    public static let profile = Strings.tr("Localizable", "profile")
    /// (PRO ONLY)
    public static let proOnly = Strings.tr("Localizable", "proOnly")
    /// Proxy
    public static let proxy = Strings.tr("Localizable", "Proxy")
    /// Proxy server requires a password
    public static let proxyServerRequiresAPassword = Strings.tr("Localizable", "Proxy server requires a password")
    /// Proxy Settings
    public static let proxySettings = Strings.tr("Localizable", "Proxy Settings")
    /// Your purchase was restored
    public static let purchaseRestoreMessage = Strings.tr("Localizable", "purchaseRestore_message")
    /// Purple
    public static let purple = Strings.tr("Localizable", "Purple")
    /// QR Code
    public static let qrCode = Strings.tr("Localizable", "qrCode")
    /// Quality
    public static let quality = Strings.tr("Localizable", "Quality")
    /// Quality of videos uploaded to a chat
    public static let qualityOfVideosUploadedToAChat = Strings.tr("Localizable", "qualityOfVideosUploadedToAChat")
    /// Queued
    public static let queued = Strings.tr("Localizable", "queued")
    /// Quick Access
    public static let quickAccess = Strings.tr("Localizable", "Quick Access")
    /// Quickly access files from your Favourites section
    public static let quicklyAccessFilesOnFavouritesSection = Strings.tr("Localizable", "Quickly access files on Favourites section")
    /// Quickly access files from your Offline section
    public static let quicklyAccessFilesOnOfflineSection = Strings.tr("Localizable", "Quickly access files on Offline section")
    /// Quickly access files from your Recents section
    public static let quicklyAccessFilesOnRecentsSection = Strings.tr("Localizable", "Quickly access files on Recents section")
    /// Quickly access files on Recents, Favourites, or the Offline section
    public static let quicklyAccessFilesOnRecentsFavouritesOrOfflineSection = Strings.tr("Localizable", "Quickly access files on Recents, Favourites, or Offline section")
    /// Rate limit exceeded
    public static let rateLimitExceeded = Strings.tr("Localizable", "Rate limit exceeded")
    /// Rate us
    public static let rateUsLabel = Strings.tr("Localizable", "rateUsLabel")
    /// Read error
    public static let readError = Strings.tr("Localizable", "Read error")
    /// Read and Write
    public static let readAndWrite = Strings.tr("Localizable", "readAndWrite")
    /// Read-only
    public static let readOnly = Strings.tr("Localizable", "readOnly")
    /// Received
    public static let received = Strings.tr("Localizable", "received")
    /// Recently Added
    public static let recentlyAdded = Strings.tr("Localizable", "Recently Added")
    /// Recents
    public static let recents = Strings.tr("Localizable", "Recents")
    /// Reconnecting…
    public static let reconnecting = Strings.tr("Localizable", "Reconnecting...")
    /// Recording…
    public static let recording = Strings.tr("Localizable", "Recording...")
    /// Recovery key
    public static let recoveryKey = Strings.tr("Localizable", "recoveryKey")
    /// The Recovery key has been copied to the clipboard. Please store it in a safe place.
    public static let recoveryKeyCopiedToClipboard = Strings.tr("Localizable", "recoveryKeyCopiedToClipboard")
    /// This recovery link has expired, please try again.
    public static let recoveryLinkHasExpired = Strings.tr("Localizable", "recoveryLinkHasExpired")
    /// Red
    public static let red = Strings.tr("Localizable", "Red")
    /// Rejected by fraud protection
    public static let rejectedByFraudProtection = Strings.tr("Localizable", "Rejected by fraud protection")
    /// Reminder: You have a contact request
    public static let reminderYouHaveAContactRequest = Strings.tr("Localizable", "Reminder: You have a contact request")
    /// Before logging out we recommend you export your Recovery key to a safe place. Note that you’re not able to reset your password if you forget it.
    public static let remindPasswordLogoutText = Strings.tr("Localizable", "remindPasswordLogoutText")
    /// Due to MEGA’s encryption technology you are unable to reset your password without data loss. Please make sure you remember your password.
    public static let remindPasswordText = Strings.tr("Localizable", "remindPasswordText")
    /// Do you remember your password?
    public static let remindPasswordTitle = Strings.tr("Localizable", "remindPasswordTitle")
    /// Remove
    public static let remove = Strings.tr("Localizable", "remove")
    /// Remove Favourite
    public static let removeFavourite = Strings.tr("Localizable", "Remove Favourite")
    /// Remove files older than
    public static let removeFilesOlderThan = Strings.tr("Localizable", "Remove files older than")
    /// Remove Label
    public static let removeLabel = Strings.tr("Localizable", "Remove Label")
    /// Remove nickname
    public static let removeNickname = Strings.tr("Localizable", "Remove Nickname")
    /// Remove Password
    public static let removePassword = Strings.tr("Localizable", "Remove Password")
    /// Remove Phone Number
    public static let removePhoneNumber = Strings.tr("Localizable", "Remove Phone Number")
    /// Remove Photo
    public static let removePhoto = Strings.tr("Localizable", "Remove Photo")
    /// Remove Share
    public static let removeShare = Strings.tr("Localizable", "Remove Share")
    /// Removed [X] items from a share
    public static let removedXItemsFromAShare = Strings.tr("Localizable", "Removed [X] items from a share")
    /// Removed item from shared folder
    public static let removedItemFromSharedFolder = Strings.tr("Localizable", "Removed item from shared folder")
    /// Contact %@ removed
    public static func removedContact(_ p1: Any) -> String {
      return Strings.tr("Localizable", "removedContact", String(describing: p1))
    }
    /// You are about to permanently remove 1 file and %d folders. Would you like to proceed? (You cannot undo this action.)
    public static func removeFileFoldersToRubbishBinMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "removeFileFoldersToRubbishBinMessage", p1)
    }
    /// You are about to permanently remove 1 file and 1 folder. Would you like to proceed? (You cannot undo this action.)
    public static let removeFileFolderToRubbishBinMessage = Strings.tr("Localizable", "removeFileFolderToRubbishBinMessage")
    /// You are about to permanently remove [A] files and [B] folders. Would you like to proceed? (You cannot undo this action.)
    public static let removeFilesFoldersToRubbishBinMessage = Strings.tr("Localizable", "removeFilesFoldersToRubbishBinMessage")
    /// You are about to permanently remove %d files and 1 folder. Would you like to proceed? (You cannot undo this action.)
    public static func removeFilesFolderToRubbishBinMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "removeFilesFolderToRubbishBinMessage", p1)
    }
    /// You are about to permanently remove %d files. Would you like to proceed? (You cannot undo this action.)
    public static func removeFilesToRubbishBinMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "removeFilesToRubbishBinMessage", p1)
    }
    /// You are about to permanently remove 1 file. Would you like to proceed? (You cannot undo this action.)
    public static let removeFileToRubbishBinMessage = Strings.tr("Localizable", "removeFileToRubbishBinMessage")
    /// You are about to permanently remove %d folders. Would you like to proceed? (You cannot undo this action.)
    public static func removeFoldersToRubbishBinMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "removeFoldersToRubbishBinMessage", p1)
    }
    /// You are about to permanently remove 1 folder. Would you like to proceed? (You cannot undo this action.)
    public static let removeFolderToRubbishBinMessage = Strings.tr("Localizable", "removeFolderToRubbishBinMessage")
    /// Are you sure you want to delete this item from Offline?
    public static let removeItemFromOffline = Strings.tr("Localizable", "removeItemFromOffline")
    /// Are you sure you want to delete these items from Offline?
    public static let removeItemsFromOffline = Strings.tr("Localizable", "removeItemsFromOffline")
    /// Are you sure you want to remove these shares? (Shared with %d contacts)
    public static func removeMultipleSharesMultipleContactsMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "removeMultipleSharesMultipleContactsMessage", p1)
    }
    /// Are you sure you want to remove %d users from your contact list?
    public static func removeMultipleUsersMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "removeMultipleUsersMessage", p1)
    }
    /// Confirm removal
    public static let removeNodeFromRubbishBinTitle = Strings.tr("Localizable", "removeNodeFromRubbishBinTitle")
    /// Are you sure you want to remove this share? (Shared with %d contacts)
    public static func removeOneShareMultipleContactsMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "removeOneShareMultipleContactsMessage", p1)
    }
    /// Are you sure you want to remove this share? (Shared with 1 contact)
    public static let removeOneShareOneContactMessage = Strings.tr("Localizable", "removeOneShareOneContactMessage")
    /// Remove Participant
    public static let removeParticipant = Strings.tr("Localizable", "removeParticipant")
    /// Remove preview
    public static let removePreview = Strings.tr("Localizable", "removePreview")
    /// Remove sharing
    public static let removeSharing = Strings.tr("Localizable", "removeSharing")
    /// Remove contact
    public static let removeUserTitle = Strings.tr("Localizable", "removeUserTitle")
    /// Rename
    public static let rename = Strings.tr("Localizable", "rename")
    /// Rename file %@?
    public static func renameFileAlertTitle(_ p1: Any) -> String {
      return Strings.tr("Localizable", "rename_file_alert_title", String(describing: p1))
    }
    /// Rename Group
    public static let renameGroup = Strings.tr("Localizable", "renameGroup")
    /// Enter the new name
    public static let renameNodeMessage = Strings.tr("Localizable", "renameNodeMessage")
    /// Renews on
    public static let renewsOn = Strings.tr("Localizable", "Renews on")
    /// Replace
    public static let replace = Strings.tr("Localizable", "replace")
    /// Request failed, retrying
    public static let requestFailedRetrying = Strings.tr("Localizable", "Request failed, retrying")
    /// Request accepted
    public static let requestAccepted = Strings.tr("Localizable", "requestAccepted")
    /// Request a plan
    public static let requestAPlan = Strings.tr("Localizable", "requestAPlan")
    /// Request cancelled
    public static let requestCancelled = Strings.tr("Localizable", "requestCancelled")
    /// Request deleted
    public static let requestDeleted = Strings.tr("Localizable", "requestDeleted")
    /// Requests
    public static let requests = Strings.tr("Localizable", "Requests")
    /// Require Passcode
    public static let requirePasscode = Strings.tr("Localizable", "Require Passcode")
    /// Resend
    public static let resend = Strings.tr("Localizable", "resend")
    /// Reset
    public static let reset = Strings.tr("Localizable", "reset")
    /// Reset Password
    public static let resetPassword = Strings.tr("Localizable", "Reset Password")
    /// Reset QR Code
    public static let resetQrCode = Strings.tr("Localizable", "resetQrCode")
    /// Previous QR codes will no longer be valid.
    public static let resetQrCodeFooter = Strings.tr("Localizable", "resetQrCodeFooter")
    /// Restart
    public static let restart = Strings.tr("Localizable", "restart")
    /// Restore
    public static let restore = Strings.tr("Localizable", "restore")
    /// Resume
    public static let resume = Strings.tr("Localizable", "resume")
    /// Resume All
    public static let resumeAll = Strings.tr("Localizable", "Resume All")
    /// Resume Transfers?
    public static let resumeTransfers = Strings.tr("Localizable", "Resume Transfers?")
    /// Resume playback?
    public static let resumePlayback = Strings.tr("Localizable", "resumePlayback")
    /// Retry
    public static let retry = Strings.tr("Localizable", "retry")
    /// Retrying…
    public static let retrying = Strings.tr("Localizable", "Retrying...")
    /// Revert
    public static let revert = Strings.tr("Localizable", "revert")
    /// You are disabling rich URL previews permanently. You can re-enable rich URL previews in your settings. Do you want to proceed?
    public static let richPreviewsConfirmation = Strings.tr("Localizable", "richPreviewsConfirmation")
    /// Enhance the MEGA Chat experience. URL content will be retrieved without end-to-end encryption.
    public static let richPreviewsFooter = Strings.tr("Localizable", "richPreviewsFooter")
    /// Rich URL Previews
    public static let richUrlPreviews = Strings.tr("Localizable", "richUrlPreviews")
    /// Role:
    public static let role = Strings.tr("Localizable", "Role:")
    /// Rubbish bin emptying scheduler
    public static let rubbishBinCleaningScheduler = Strings.tr("Localizable", "Rubbish-Bin Cleaning Scheduler:")
    /// Rubbish Bin
    public static let rubbishBinLabel = Strings.tr("Localizable", "rubbishBinLabel")
    /// Same for All
    public static let sameForAll = Strings.tr("Localizable", "Same for All")
    /// Save
    public static let save = Strings.tr("Localizable", "save")
    /// Save a copy of the images and videos taken from the MEGA App in your device’s media library.
    public static let saveACopyOfTheImagesAndVideosTakenFromTheMEGAAppInYourDeviceSMediaLibrary = Strings.tr("Localizable", "Save a copy of the images and videos taken from the MEGA app in your device’s media library.")
    /// Save HEIC photos as
    public static let saveHeicPhotosAs = Strings.tr("Localizable", "SAVE HEIC PHOTOS AS")
    /// Save HEVC videos as
    public static let saveHevcVideosAs = Strings.tr("Localizable", "SAVE HEVC VIDEOS AS")
    /// Save Images in Photos
    public static let saveImagesInPhotos = Strings.tr("Localizable", "Save Images in Photos")
    /// Save in Photos
    public static let saveInPhotos = Strings.tr("Localizable", "Save in Photos")
    /// Save Settings
    public static let saveSettings = Strings.tr("Localizable", "Save Settings")
    /// Save to Photos
    public static let saveToPhotos = Strings.tr("Localizable", "Save to Photos")
    /// Save Videos in Photos
    public static let saveVideosInPhotos = Strings.tr("Localizable", "Save Videos in Photos")
    /// Save 16%
    public static let save17 = Strings.tr("Localizable", "save17")
    /// Saved
    public static let saved = Strings.tr("Localizable", "saved")
    /// Saved to Photos
    public static let savedToPhotos = Strings.tr("Localizable", "Saved to Photos")
    /// Save Image
    public static let saveImage = Strings.tr("Localizable", "saveImage")
    /// Saving to Photos…
    public static let savingToPhotos = Strings.tr("Localizable", "Saving to Photos…")
    /// Scan Document
    public static let scanDocument = Strings.tr("Localizable", "Scan Document")
    /// Scan Code
    public static let scanCode = Strings.tr("Localizable", "scanCode")
    /// Scan or copy the seed to your Authenticator App. Be sure to back up this seed to a safe place in case you lose your device.
    public static let scanOrCopyTheSeed = Strings.tr("Localizable", "scanOrCopyTheSeed")
    /// MEGA SDK Version
    public static let sdkVersion = Strings.tr("Localizable", "sdkVersion")
    /// Search
    public static let search = Strings.tr("Localizable", "Search")
    /// Search GIPHY
    public static let searchGIPHY = Strings.tr("Localizable", "Search GIPHY")
    /// Search Your Files
    public static let searchYourFiles = Strings.tr("Localizable", "Search Your Files")
    /// Security is why we exist, your files are safe with us behind a well oiled encryption machine where only you can access your files.
    public static let securityIsWhyWeExistYourFilesAreSafeWithUsBehindAWellOiledEncryptionMachineWhereOnlyYouCanAccessYourFiles = Strings.tr("Localizable", "Security is why we exist, your files are safe with us behind a well oiled encryption machine where only you can access your files.")
    /// Security Options
    public static let securityOptions = Strings.tr("Localizable", "securityOptions")
    /// Discover your contacts on MEGA
    public static let seeWhoSAlreadyOnMEGA = Strings.tr("Localizable", "See who's already on MEGA")
    /// See plans
    public static let seePlans = Strings.tr("Localizable", "seePlans")
    /// Select
    public static let select = Strings.tr("Localizable", "select")
    /// Select Folder
    public static let selectFolder = Strings.tr("Localizable", "Select Folder")
    /// Select from phone contacts or enter multiple email addresses
    public static let selectFromPhoneContactsOrEnterMultipleEmailAddresses = Strings.tr("Localizable", "Select from phone contacts or enter multiple email addresses")
    /// Select view mode (List or Thumbnail) on a per-folder basis, or use the same view mode for all folders.
    public static let selectViewModeListOrThumbnailOnAPerFolderBasisOrUseTheSameViewModeForAllFolders = Strings.tr("Localizable", "Select view mode (List or Thumbnail) on a per-folder basis, or use the same view mode for all folders.")
    /// Select All
    public static let selectAll = Strings.tr("Localizable", "selectAll")
    /// Select destination
    public static let selectDestination = Strings.tr("Localizable", "selectDestination")
    /// Select files
    public static let selectFiles = Strings.tr("Localizable", "selectFiles")
    /// Select membership:
    public static let selectMembership = Strings.tr("Localizable", "selectMembership")
    /// Select one account type:
    public static let selectOneAccountType = Strings.tr("Localizable", "selectOneAccountType")
    /// Select items
    public static let selectTitle = Strings.tr("Localizable", "selectTitle")
    /// Send
    public static let send = Strings.tr("Localizable", "send")
    /// Send (%d)
    public static func sendD(_ p1: Int) -> String {
      return Strings.tr("Localizable", "Send (%d)", p1)
    }
    /// Send Decryption Key Separately
    public static let sendDecryptionKeySeparately = Strings.tr("Localizable", "Send Decryption Key Separately")
    /// Send GIF
    public static let sendGIF = Strings.tr("Localizable", "Send GIF")
    /// Send Location
    public static let sendLocation = Strings.tr("Localizable", "Send Location")
    /// Always send original size images.
    public static let sendOriginalSizeIncreasedQualityImages = Strings.tr("Localizable", "Send original size, increased quality images")
    /// Always send optimised images.
    public static let sendSmallerSizeImagesOptimisedForLowerDataConsumption = Strings.tr("Localizable", "Send smaller size images optimised for lower data consumption")
    /// Send optimised images when on mobile data but original size images when on Wi-Fi.
    public static let sendSmallerSizeImagesThroughCellularNetworksAndOriginalSizeImagesThroughWifi = Strings.tr("Localizable", "Send smaller size images through cellular networks and original size images through wifi")
    /// Send this location
    public static let sendThisLocation = Strings.tr("Localizable", "Send This Location")
    /// Send contact
    public static let sendContact = Strings.tr("Localizable", "sendContact")
    /// Send Feedback
    public static let sendFeedbackLabel = Strings.tr("Localizable", "sendFeedbackLabel")
    /// Send Message
    public static let sendMessage = Strings.tr("Localizable", "sendMessage")
    /// Sent
    public static let sent = Strings.tr("Localizable", "sent")
    /// Sent you a contact request
    public static let sentYouAContactRequest = Strings.tr("Localizable", "Sent you a contact request")
    /// Sent Contact: %s
    public static func sentContact(_ p1: UnsafePointer<CChar>) -> String {
      return Strings.tr("Localizable", "sentContact", p1)
    }
    /// Sent %s Contacts.
    public static func sentXContacts(_ p1: UnsafePointer<CChar>) -> String {
      return Strings.tr("Localizable", "sentXContacts", p1)
    }
    /// Server:
    public static let server = Strings.tr("Localizable", "Server:")
    /// Servers are too busy. Please wait…
    public static let serversAreTooBusy = Strings.tr("Localizable", "serversAreTooBusy")
    /// Sessions closed
    public static let sessionsClosed = Strings.tr("Localizable", "sessionsClosed")
    /// Set nickname
    public static let setNickname = Strings.tr("Localizable", "Set Nickname")
    /// Set Password
    public static let setPassword = Strings.tr("Localizable", "Set Password")
    /// Set Expiry Date
    public static let setExpiryDate = Strings.tr("Localizable", "setExpiryDate")
    /// Set password protection
    public static let setPasswordProtection = Strings.tr("Localizable", "setPasswordProtection")
    /// Settings > General > %@ Storage
    public static func settingsGeneralStorage(_ p1: Any) -> String {
      return Strings.tr("Localizable", "Settings > General > %@ Storage", String(describing: p1))
    }
    /// Settings
    public static let settingsTitle = Strings.tr("Localizable", "settingsTitle")
    /// Set up MEGA
    public static let setupMEGA = Strings.tr("Localizable", "Setup MEGA")
    /// Share with
    public static let shareWith = Strings.tr("Localizable", "Share with")
    /// Shared
    public static let shared = Strings.tr("Localizable", "shared")
    /// Shared Albums from your device’s Photos app will be uploaded.
    public static let sharedAlbumsFromYourDeviceSPhotosAppWillBeUploaded = Strings.tr("Localizable", "Shared Albums from your device's Photos app will be uploaded.")
    /// Shared Albums from your device’s Photos app will not be uploaded.
    public static let sharedAlbumsFromYourDeviceSPhotosAppWillNotBeUploaded = Strings.tr("Localizable", "Shared Albums from your device's Photos app will not be uploaded.")
    /// Shared Files
    public static let sharedFiles = Strings.tr("Localizable", "Shared Files")
    /// Shared successfully
    public static let sharedSuccessfully = Strings.tr("Localizable", "Shared successfully")
    /// Folder shared
    public static let sharedFolderSuccess = Strings.tr("Localizable", "sharedFolder_success")
    /// Shared Folders
    public static let sharedFolders = Strings.tr("Localizable", "sharedFolders")
    /// %d folders shared successfully.
    public static func sharedFoldersSuccess(_ p1: Int) -> String {
      return Strings.tr("Localizable", "sharedFolders_success", p1)
    }
    /// Shared Items
    public static let sharedItems = Strings.tr("Localizable", "sharedItems")
    /// Shared with:
    public static let sharedWidth = Strings.tr("Localizable", "sharedWidth")
    /// Shared with
    public static let sharedWith = Strings.tr("Localizable", "sharedWith")
    /// Shared with %d contacts
    public static func sharedWithXContacts(_ p1: Int) -> String {
      return Strings.tr("Localizable", "sharedWithXContacts", p1)
    }
    /// Some items could not be shared with MEGA
    public static let shareExtensionUnsupportedAssets = Strings.tr("Localizable", "shareExtensionUnsupportedAssets")
    /// Share left
    public static let shareLeft = Strings.tr("Localizable", "shareLeft")
    /// Share removed
    public static let shareRemoved = Strings.tr("Localizable", "shareRemoved")
    /// Shares left
    public static let sharesLeft = Strings.tr("Localizable", "sharesLeft")
    /// Shares removed
    public static let sharesRemoved = Strings.tr("Localizable", "sharesRemoved")
    /// Sharing
    public static let sharing = Strings.tr("Localizable", "sharing")
    /// Shortcuts
    public static let shortcuts = Strings.tr("Localizable", "Shortcuts")
    /// Show
    public static let show = Strings.tr("Localizable", "Show")
    /// Simple Passcode
    public static let simplePasscodeLabel = Strings.tr("Localizable", "simplePasscodeLabel")
    /// Size
    public static let size = Strings.tr("Localizable", "size")
    /// Skip
    public static let skipButton = Strings.tr("Localizable", "skipButton")
    /// Smallest
    public static let smallest = Strings.tr("Localizable", "smallest")
    /// Something went wrong
    public static let somethingWentWrong = Strings.tr("Localizable", "Something went wrong")
    /// Sorting and View Mode
    public static let sortingAndViewMode = Strings.tr("Localizable", "Sorting And View Mode")
    /// Sorting preference
    public static let sortingPreference = Strings.tr("Localizable", "Sorting preference")
    /// Sort by
    public static let sortTitle = Strings.tr("Localizable", "sortTitle")
    /// SSL verification failed
    public static let sslVerificationFailed = Strings.tr("Localizable", "SSL verification failed")
    /// MEGA is unable to connect securely through SSL. You might be on public Wi-Fi with additional requirements.
    public static let sslUnverifiedAlertTitle = Strings.tr("Localizable", "sslUnverified_alertTitle")
    /// Standard
    public static let standard = Strings.tr("Localizable", "standard")
    /// Start chatting securely with your contacts using end-to-end encryption
    public static let startChattingSecurelyWithYourContactsUsingEndToEndEncryption = Strings.tr("Localizable", "Start chatting securely with your contacts using end-to-end encryption")
    /// Start Group
    public static let startGroup = Strings.tr("Localizable", "Start Group")
    /// Start Conversation
    public static let startConversation = Strings.tr("Localizable", "startConversation")
    /// I acknowledge that I am starting a fresh, empty account and that I will lose all data in my present account unless I recall my password or locate an exported Recovery key.
    public static let startingFreshAccount = Strings.tr("Localizable", "startingFreshAccount")
    /// Start new account
    public static let startNewAccount = Strings.tr("Localizable", "startNewAccount")
    /// Status
    public static let status = Strings.tr("Localizable", "status")
    /// Status Persistence
    public static let statusPersistence = Strings.tr("Localizable", "statusPersistence")
    /// Storage
    public static let storage = Strings.tr("Localizable", "Storage")
    /// Storage Full
    public static let storageFull = Strings.tr("Localizable", "Storage Full")
    /// Storage Quota
    public static let storageQuota = Strings.tr("Localizable", "storageQuota")
    /// Strong
    public static let strong = Strings.tr("Localizable", "strong")
    /// Subject to your participation in our achievements program.
    public static let subjectToYourParticipationInOurAchievementsProgram = Strings.tr("Localizable", "subjectToYourParticipationInOurAchievementsProgram")
    /// Synced albums are where you sync photos or videos to your device’s Photos app from iTunes.
    public static let syncedAlbumsAreWhereYouSyncPhotosOrVideosToYourDeviceSPhotosAppFromITunes = Strings.tr("Localizable", "Synced albums are where you sync photos or videos to your device's Photos app from iTunes.")
    /// Takedown notice
    public static let takedownNotice = Strings.tr("Localizable", "Takedown notice")
    /// Takedown reinstated
    public static let takedownReinstated = Strings.tr("Localizable", "Takedown reinstated")
    /// This folder or file was reported to contain objectionable content, such as Child Exploitation Material, Violent Extremism, or Bestiality. The link creator’s account has been closed and their full details, including IP address, have been provided to the authorities.
    public static let takenDownDueToSevereViolationOfOurTermsOfService = Strings.tr("Localizable", "Taken down due to severe violation of our terms of service")
    /// The process is taking longer than expected. Please wait…
    public static let takingLongerThanExpected = Strings.tr("Localizable", "takingLongerThanExpected")
    /// Tap and hold %@ to record, release to send
    public static func tapAndHoldToRecordReleaseToSend(_ p1: Any) -> String {
      return Strings.tr("Localizable", "Tap and hold %@ to record, release to send", String(describing: p1))
    }
    /// Tap here for info
    public static let tapHereForInfo = Strings.tr("Localizable", "Tap here for info")
    /// Tap space to enter multiple emails
    public static let tapSpaceToEnterMultipleEmails = Strings.tr("Localizable", "Tap space to enter multiple emails")
    /// Tap to Copy
    public static let tapToCopy = Strings.tr("Localizable", "Tap to Copy")
    /// Tap to return to call
    public static let tapToReturnToCall = Strings.tr("Localizable", "Tap to return to call")
    /// Tap file to rename
    public static let tapFileToRename = Strings.tr("Localizable", "tapFileToRename")
    /// Temporarily not available
    public static let temporarilyNotAvailable = Strings.tr("Localizable", "Temporarily not available")
    /// Terms of Service breached
    public static let termsOfServiceBreached = Strings.tr("Localizable", "Terms of Service breached")
    /// You need to agree with the Terms of Service to register an account on MEGA.
    public static let termsCheckboxUnselected = Strings.tr("Localizable", "termsCheckboxUnselected")
    /// You need to agree that you understand the danger of losing your password
    public static let termsForLosingPasswordCheckboxUnselected = Strings.tr("Localizable", "termsForLosingPasswordCheckboxUnselected")
    /// Terms of Service
    public static let termsOfServicesLabel = Strings.tr("Localizable", "termsOfServicesLabel")
    /// Test Password
    public static let testPassword = Strings.tr("Localizable", "testPassword")
    /// You are about to log out, please test your password to ensure you remember it. If you lose your password, you will lose access to your MEGA data.
    public static let testPasswordLogoutText = Strings.tr("Localizable", "testPasswordLogoutText")
    /// Please test your password below to ensure you remember it. If you lose your password, you will lose access to your MEGA data. [A]Learn more[/A]
    public static let testPasswordText = Strings.tr("Localizable", "testPasswordText")
    /// Thank you
    public static let thankYouTitle = Strings.tr("Localizable", "thankYou_title")
    /// The account that created this link has been terminated due to multiple violations of our [A]Terms of Service[/A].
    public static let theAccountThatCreatedThisLinkHasBeenTerminatedDueToMultipleViolationsOfOurATermsOfServiceA = Strings.tr("Localizable", "The account that created this link has been terminated due to multiple violations of our [A]Terms of Service[/A].")
    /// The device does not have enough space for MEGA to run properly.
    public static let theDeviceDoesNotHaveEnoughSpaceForMEGAToRunProperly = Strings.tr("Localizable", "The device does not have enough space for MEGA to run properly.")
    /// The Hidden Album is where you hide photos or videos in your device’s Photos app.
    public static let theHiddenAlbumIsWhereYouHidePhotosOrVideosInYourDevicePhotosApp = Strings.tr("Localizable", "The Hidden Album is where you hide photos or videos in your device Photos app.")
    /// The verification code doesn’t match.
    public static let theVerificationCodeDoesnTMatch = Strings.tr("Localizable", "The verification code doesn't match.")
    /// The photo and video versions of each Live Photo will be uploaded.
    public static let theVideoAndThePhotoInEachLivePhotoWillBeUploaded = Strings.tr("Localizable", "The video and the photo in each Live Photo will be uploaded.")
    /// The content you are trying to access is not available for this account. Please try to log in with same account as in the mobile web client.
    public static let theContentIsNotAvailableForThisAccount = Strings.tr("Localizable", "theContentIsNotAvailableForThisAccount")
    /// The email address format is invalid
    public static let theEmailAddressFormatIsInvalid = Strings.tr("Localizable", "theEmailAddressFormatIsInvalid")
    /// There is already a file with the same name
    public static let thereIsAlreadyAFileWithTheSameName = Strings.tr("Localizable", "There is already a file with the same name")
    /// There is already a folder with the same name
    public static let thereIsAlreadyAFolderWithTheSameName = Strings.tr("Localizable", "There is already a folder with the same name")
    /// The users have been invited and will appear in your contact list once accepted.
    public static let theUsersHaveBeenInvited = Strings.tr("Localizable", "theUsersHaveBeenInvited")
    /// This action cannot be completed as it would take you over your current storage limit
    public static let thisActionCanNotBeCompletedAsItWouldTakeYouOverYourCurrentStorageLimit = Strings.tr("Localizable", "This action can not be completed as it would take you over your current storage limit")
    /// This chat link is no longer available
    public static let thisChatLinkIsNoLongerAvailable = Strings.tr("Localizable", "This chat link is no longer available")
    /// This file has been the subject of a takedown notice.
    public static let thisFileHasBeenTheSubjectOfATakedownNotice = Strings.tr("Localizable", "This file has been the subject of a takedown notice.")
    /// This folder has been the subject of a takedown notice.
    public static let thisFolderHasBeenTheSubjectOfATakedownNotice = Strings.tr("Localizable", "This folder has been the subject of a takedown notice.")
    /// This link is unavailable as the user’s account has been closed for gross violation of MEGA’s [A]Terms of Service[/A].
    public static let thisLinkIsUnavailableAsTheUserSAccountHasBeenClosedForGrossViolationOfMEGASATermsOfServiceA = Strings.tr("Localizable", "This link is unavailable as the user’s account has been closed for gross violation of MEGA’s [A]Terms of Service[/A].")
    /// This location will be opened using a third party maps provider outside the end-to-end encrypted MEGA platform.
    public static let thisLocationWillBeOpenedUsingAThirdPartyMapsProviderOutsideTheEndToEndEncryptedMEGAPlatform = Strings.tr("Localizable", "This location will be opened using a third party maps provider outside the end-to-end encrypted MEGA platform.")
    /// This message has reached the maximum limit of %d reactions.
    public static func thisMessageHasReachedTheMaximumLimitOfDReactions(_ p1: Int) -> String {
      return Strings.tr("Localizable", "This message has reached the maximum limit of %d reactions.", p1)
    }
    /// This number is already associated with a MEGA account.
    public static let thisNumberIsAlreadyAssociatedWithAMegaAccount = Strings.tr("Localizable", "This number is already associated with a Mega account")
    /// This operation will remove your current phone number and start the process of associating a new phone number with your account.
    public static let thisOperationWillRemoveYourCurrentPhoneNumberAndStartTheProcessOfAssociatingANewPhoneNumberWithYourAccount = Strings.tr("Localizable", "This operation will remove your current phone number and start the process of associating a new phone number with your account.")
    /// This is best done in real life by meeting face to face. If you have another already-verified channel such as verified OTR or PGP, you may also use that.
    public static let thisIsBestDoneInRealLife = Strings.tr("Localizable", "thisIsBestDoneInRealLife")
    /// This message has been deleted
    public static let thisMessageHasBeenDeleted = Strings.tr("Localizable", "thisMessageHasBeenDeleted")
    /// Thumbnail View
    public static let thumbnailView = Strings.tr("Localizable", "Thumbnail View")
    /// To access this link, you will need its password.
    public static let toAccessThisLinkYouWillNeedItsPassword = Strings.tr("Localizable", "To access this link, you will need its password.")
    /// To create a chat link you must name the group.
    public static let toCreateAChatLinkYouMustNameTheGroup = Strings.tr("Localizable", "To create a chat link you must name the group.")
    /// To disable the Rubbish bin emptying scheduler or set a longer retention period, you need to subscribe to a Pro plan.
    public static let toDisableTheRubbishBinCleaningSchedulerOrSetALongerRetentionPeriodYouNeedToSubscribeToAPROPlan = Strings.tr("Localizable", "To disable the Rubbish-Bin Cleaning Scheduler or set a longer retention period, you need to subscribe to a PRO plan.")
    /// To fully take advantage of your MEGA account we need to ask you some permissions.
    public static let toFullyTakeAdvantageOfYourMEGAAccountWeNeedToAskYouSomePermissions = Strings.tr("Localizable", "To fully take advantage of your MEGA account we need to ask you some permissions.")
    /// To send voice messages and make encrypted voice and video calls, allow MEGA access to your Camera and Microphone
    public static let toMakeEncryptedVoiceAndVideoCallsAllowMEGAAccessToYourCameraAndMicrophone = Strings.tr("Localizable", "To make encrypted voice and video calls, allow MEGA access to your Camera and Microphone")
    /// To upgrade your current subscription, please contact support for a [A]custom plan[/A].
    public static let toUpgradeYourCurrentSubscriptionPleaseContactSupportForAACustomPlanA = Strings.tr("Localizable", "To upgrade your current subscription, please contact support for a [A]custom plan[/A].")
    /// Today
    public static let today = Strings.tr("Localizable", "Today")
    /// Too many concurrent connections or transfers
    public static let tooManyConcurrentConnectionsOrTransfers = Strings.tr("Localizable", "Too many concurrent connections or transfers")
    /// Too many requests
    public static let tooManyRequests = Strings.tr("Localizable", "Too many requests")
    /// You have attempted to log in too many times. Please wait until %@ and try again.
    public static func tooManyAttemptsLogin(_ p1: Any) -> String {
      return Strings.tr("Localizable", "tooManyAttemptsLogin", String(describing: p1))
    }
    /// Too many requests. Please wait.
    public static let tooManyRequest = Strings.tr("Localizable", "tooManyRequest")
    /// Total size taken up by file versions:
    public static let totalSizeTakenUpByFileVersions = Strings.tr("Localizable", "Total size taken up by file versions:")
    /// Total size
    public static let totalSize = Strings.tr("Localizable", "totalSize")
    /// Touch to return to call %@
    public static func touchToReturnToCall(_ p1: Any) -> String {
      return Strings.tr("Localizable", "Touch to return to call %@", String(describing: p1))
    }
    /// Transfer
    public static let transfer = Strings.tr("Localizable", "Transfer")
    /// Transfer failed:
    public static let transferFailed = Strings.tr("Localizable", "Transfer failed:")
    /// Transfer over quota
    public static let transferOverQuota = Strings.tr("Localizable", "Transfer over quota")
    /// Transfer
    public static let transferQuota = Strings.tr("Localizable", "Transfer Quota")
    /// Transfer cancelled
    public static let transferCancelled = Strings.tr("Localizable", "transferCancelled")
    /// Transfers
    public static let transfers = Strings.tr("Localizable", "transfers")
    /// Transfers cancelled
    public static let transfersCancelled = Strings.tr("Localizable", "transfersCancelled")
    /// No Transfers
    public static let transfersEmptyStateTitleAll = Strings.tr("Localizable", "transfersEmptyState_titleAll")
    /// No Downloads
    public static let transfersEmptyStateTitleDownload = Strings.tr("Localizable", "transfersEmptyState_titleDownload")
    /// Paused Transfers
    public static let transfersEmptyStateTitlePaused = Strings.tr("Localizable", "transfersEmptyState_titlePaused")
    /// No Uploads
    public static let transfersEmptyStateTitleUpload = Strings.tr("Localizable", "transfersEmptyState_titleUpload")
    /// Enable this option only if your transfers don’t start. In normal circumstances HTTP is satisfactory as all transfers are already encrypted.
    public static let transfersSectionFooter = Strings.tr("Localizable", "transfersSectionFooter")
    /// Turn Mobile Data on
    public static let turnMobileDataOn = Strings.tr("Localizable", "Turn Mobile Data on")
    /// Two-factor authentication
    public static let twoFactorAuthentication = Strings.tr("Localizable", "twoFactorAuthentication")
    /// Two-factor authentication disabled
    public static let twoFactorAuthenticationDisabled = Strings.tr("Localizable", "twoFactorAuthenticationDisabled")
    /// Two-factor authentication enabled
    public static let twoFactorAuthenticationEnabled = Strings.tr("Localizable", "twoFactorAuthenticationEnabled")
    /// Next time you log in to your account you will be asked to enter a 6-digit code provided by your Authenticator App.
    public static let twoFactorAuthenticationEnabledDescription = Strings.tr("Localizable", "twoFactorAuthenticationEnabledDescription")
    /// If you lose access to your account after enabling 2FA and you have not backed up your Recovery key, MEGA cannot help you gain access to it again.
    public static let twoFactorAuthenticationEnabledWarning = Strings.tr("Localizable", "twoFactorAuthenticationEnabledWarning")
    /// An annual subscription is 16% cheaper than 12 monthly payments
    public static func twoMonthsFree(_ p1: CChar) -> String {
      return Strings.tr("Localizable", "twoMonthsFree", p1)
    }
    /// %1$s [A]are typing…[/A]
    public static func twoUsersAreTyping(_ p1: UnsafePointer<CChar>) -> String {
      return Strings.tr("Localizable", "twoUsersAreTyping", p1)
    }
    /// Type
    public static let type = Strings.tr("Localizable", "type")
    /// Unable to start a call due to the participant limit having been exceeded.
    public static let unableToStartACallBecauseTheParticipantsLimitWasExceeded = Strings.tr("Localizable", "Unable to start a call because the participants limit was exceeded.")
    /// Unable to reach MEGA. Please check your connectivity or try again later.
    public static let unableToReachMega = Strings.tr("Localizable", "unableToReachMega")
    /// Unarchive Chat
    public static let unarchiveChat = Strings.tr("Localizable", "unarchiveChat")
    /// Are you sure you want to unarchive this conversation?
    public static let unarchiveChatMessage = Strings.tr("Localizable", "unarchiveChatMessage")
    /// Unavailable
    public static let unavailable = Strings.tr("Localizable", "Unavailable")
    /// Unknown error
    public static let unknownError = Strings.tr("Localizable", "Unknown error")
    /// Unlocked bonuses:
    public static let unlockedBonuses = Strings.tr("Localizable", "unlockedBonuses")
    /// Unmute
    public static let unmute = Strings.tr("Localizable", "unmute")
    /// %lu unread message
    public static func unreadMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "unreadMessage", p1)
    }
    /// %lu unread messages
    public static func unreadMessages(_ p1: Int) -> String {
      return Strings.tr("Localizable", "unreadMessages", p1)
    }
    /// Unselect
    public static let unselect = Strings.tr("Localizable", "Unselect")
    /// Until I turn them back on
    public static let untilITurnItBackOn = Strings.tr("Localizable", "Until I turn it back on")
    /// Until this morning
    public static let untilThisMorning = Strings.tr("Localizable", "Until this morning")
    /// Until tomorrow morning
    public static let untilTomorrowMorning = Strings.tr("Localizable", "Until tomorrow morning")
    /// Upgrade
    public static let upgrade = Strings.tr("Localizable", "upgrade")
    /// Upgrade to a custom plan
    public static let upgradeToACustomPlan = Strings.tr("Localizable", "Upgrade to a custom plan")
    /// Upgrade to Pro
    public static let upgradeToPro = Strings.tr("Localizable", "Upgrade to Pro")
    /// Upgrade Account
    public static let upgradeAccount = Strings.tr("Localizable", "upgradeAccount")
    /// Upload
    public static let upload = Strings.tr("Localizable", "upload")
    /// Upload (%d)
    public static func uploadD(_ p1: Int) -> String {
      return Strings.tr("Localizable", "Upload (%d)", p1)
    }
    /// Upload Albums Synced from iTunes
    public static let uploadAlbumsSyncedFromITunes = Strings.tr("Localizable", "Upload Albums Synced from iTunes")
    /// Upload All Burst Photos
    public static let uploadAllBurstPhotos = Strings.tr("Localizable", "Upload All Burst Photos")
    /// Upload File
    public static let uploadFile = Strings.tr("Localizable", "Upload File")
    /// Upload Hidden Album
    public static let uploadHiddenAlbum = Strings.tr("Localizable", "Upload Hidden Album")
    /// Upload paused due to no Wi-Fi connection, %lu files pending
    public static func uploadPausedBecauseOfNoWiFiLuFilesPending(_ p1: Int) -> String {
      return Strings.tr("Localizable", "Upload paused because of no WiFi, %lu files pending", p1)
    }
    /// Upload paused due to no Wi-Fi connection, 1 file pending
    public static let uploadPausedBecauseOfNoWiFi1FilePending = Strings.tr("Localizable", "Upload paused because of no WiFi, 1 file pending")
    /// Transfer failed due to a recursive directory structure
    public static let uploadProducesRecursivity = Strings.tr("Localizable", "Upload produces recursivity")
    /// Upload Shared Albums
    public static let uploadSharedAlbums = Strings.tr("Localizable", "Upload Shared Albums")
    /// Upload Videos for Live Photos
    public static let uploadVideosForLivePhotos = Strings.tr("Localizable", "Upload Videos for Live Photos")
    /// UPLOAD transfers
    public static let uploadInUppercaseTransfers = Strings.tr("Localizable", "uploadInUppercaseTransfers")
    /// Uploads
    public static let uploads = Strings.tr("Localizable", "uploads")
    /// Upload started
    public static let uploadStartedMessage = Strings.tr("Localizable", "uploadStarted_Message")
    /// Upload to MEGA
    public static let uploadToMega = Strings.tr("Localizable", "uploadToMega")
    /// Upload Videos
    public static let uploadVideosLabel = Strings.tr("Localizable", "uploadVideosLabel")
    /// Use Mobile Data for Videos
    public static let useMobileDataForVideos = Strings.tr("Localizable", "Use Mobile Data for Videos")
    /// Use Most Compatible Formats
    public static let useMostCompatibleFormats = Strings.tr("Localizable", "Use Most Compatible Formats")
    /// Use Mobile Data
    public static let useMobileData = Strings.tr("Localizable", "useMobileData")
    /// user
    public static let user = Strings.tr("Localizable", "user")
    /// User management is only available from a desktop web browser.
    public static let userManagementIsOnlyAvailableFromADesktopWebBrowser = Strings.tr("Localizable", "User management is only available from a desktop web browser.")
    /// Username:
    public static let username = Strings.tr("Localizable", "Username:")
    /// users
    public static let users = Strings.tr("Localizable", "users")
    /// Verified
    public static let verified = Strings.tr("Localizable", "verified")
    /// Verify
    public static let verify = Strings.tr("Localizable", "verify")
    /// Verify Your Account
    public static let verifyYourAccount = Strings.tr("Localizable", "Verify Your Account")
    /// Verify Credentials
    public static let verifyCredentials = Strings.tr("Localizable", "verifyCredentials")
    /// Please enter your password to verify your email address
    public static let verifyYourEmailAddressDescription = Strings.tr("Localizable", "verifyYourEmailAddress_description")
    /// Version was created as a new file successfully.
    public static let versionCreatedAsANewFileSuccessfully = Strings.tr("Localizable", "Version created as a new file successfully.")
    /// Versions
    public static let versions = Strings.tr("Localizable", "versions")
    /// Very weak
    public static let veryWeak = Strings.tr("Localizable", "veryWeak")
    /// Video
    public static let video = Strings.tr("Localizable", "Video")
    /// Video Quality
    public static let videoQuality = Strings.tr("Localizable", "videoQuality")
    /// Videos
    public static let videos = Strings.tr("Localizable", "Videos")
    /// Videos will be uploaded to the Camera Uploads folder.
    public static let videosWillBeUploadedToTheCameraUploadsFolder = Strings.tr("Localizable", "Videos will be uploaded to the Camera Uploads folder.")
    /// View in Folder
    public static let viewInFolder = Strings.tr("Localizable", "View in Folder")
    /// View mode preference
    public static let viewModePreference = Strings.tr("Localizable", "View mode preference")
    /// VIEW MORE
    public static let viewMore = Strings.tr("Localizable", "VIEW MORE")
    /// View Source Code
    public static let viewSourceCode = Strings.tr("Localizable", "View Source Code")
    /// View and edit profile
    public static let viewAndEditProfile = Strings.tr("Localizable", "viewAndEditProfile")
    /// Voice
    public static let voice = Strings.tr("Localizable", "Voice")
    /// Voice Clip
    public static let voiceClip = Strings.tr("Localizable", "Voice Clip")
    /// Voice message
    public static let voiceMessage = Strings.tr("Localizable", "Voice message")
    /// Voice and Video Calls
    public static let voiceAndVideoCalls = Strings.tr("Localizable", "voiceAndVideoCalls")
    /// Warning
    public static let warning = Strings.tr("Localizable", "warning")
    /// [A] was removed from the group chat by [B].
    public static let wasRemovedFromTheGroupChatBy = Strings.tr("Localizable", "wasRemovedFromTheGroupChatBy")
    /// We recommend JPG, as it is the most compatible format for photos.
    public static let weRecommendJPGAsItsTheMostCompatibleFormatForPhotos = Strings.tr("Localizable", "We recommend JPG, as its the most compatible format for photos.")
    /// We would like to send you notifications so you receive new messages on your device instantly.
    public static let weWouldLikeToSendYouNotificationsSoYouReceiveNewMessagesOnYourDeviceInstantly = Strings.tr("Localizable", "We would like to send you notifications so you receive new messages on your device instantly.")
    /// Weak
    public static let `weak` = Strings.tr("Localizable", "weak")
    /// Two-factor authentication is a second layer of security for your account.
    public static let whatIsTwoFactorAuthentication = Strings.tr("Localizable", "whatIsTwoFactorAuthentication")
    /// When enabled, photos will be uploaded.
    public static let whenEnabledPhotosWillBeUploaded = Strings.tr("Localizable", "When enabled, photos will be uploaded.")
    /// When enabled, videos will be uploaded.
    public static let whenEnabledVideosWillBeUploaded = Strings.tr("Localizable", "When enabled, videos will be uploaded.")
    /// When you log out, files from your Offline section will be deleted from your device and ongoing transfers will be cancelled.
    public static let whenYouLogoutFilesFromYourOfflineSectionWillBeDeletedFromYourDeviceAndOngoingTransfersWillBeCancelled = Strings.tr("Localizable", "When you logout, files from your Offline section will be deleted from your device and ongoing transfers will be cancelled.")
    /// When you log out, files from your Offline section will be deleted from your device.
    public static let whenYouLogoutFilesFromYourOfflineSectionWillBeDeletedFromYourDevice = Strings.tr("Localizable", "When you logout, files from your Offline section will be deleted from your device.")
    /// When you log out, ongoing transfers will be cancelled.
    public static let whenYouLogoutOngoingTransfersWillBeCancelled = Strings.tr("Localizable", "When you logout, ongoing transfers will be cancelled.")
    /// MEGA cannot access your data. However, your business account administrator can access your Camera Uploads.
    public static let whileMEGADoesNotHaveAccessToYourDataYourOrganizationAdministratorsDoHaveTheAbilityToControlAndViewTheCameraUploadsInYourUserAccount = Strings.tr("Localizable", "While MEGA does not have access to your data, your organization administrators do have the ability to control and view the Camera Uploads in your user account")
    /// Why am I seeing this?
    public static let whyAmISeeingThis = Strings.tr("Localizable", "Why am I seeing this?")
    /// Why do I need a Recovery key?
    public static let whyDoINeedARecoveryKey = Strings.tr("Localizable", "whyDoINeedARecoveryKey")
    /// Why do you need two-factor authentication?
    public static let whyYouDoNeedTwoFactorAuthentication = Strings.tr("Localizable", "whyYouDoNeedTwoFactorAuthentication")
    /// Two-factor authentication is a second layer of security for your account. Which means that even if someone knows your password they cannot access it, without also having access to the six digit code only you have access to.
    public static let whyYouDoNeedTwoFactorAuthenticationDescription = Strings.tr("Localizable", "whyYouDoNeedTwoFactorAuthenticationDescription")
    /// Write error
    public static let writeError = Strings.tr("Localizable", "Write error")
    /// Write a message to %s…
    public static func writeAMessage(_ p1: UnsafePointer<CChar>) -> String {
      return Strings.tr("Localizable", "writeAMessage", p1)
    }
    /// WRONG PURCHASE %@ (%ld)
    public static func wrongPurchase(_ p1: Any, _ p2: Int) -> String {
      return Strings.tr("Localizable", "wrongPurchase", String(describing: p1), p2)
    }
    /// [X] contacts
    public static let xContactsSelected = Strings.tr("Localizable", "XContactsSelected")
    /// %d files sent successfully
    public static func xfilesSentSuccesfully(_ p1: Int) -> String {
      return Strings.tr("Localizable", "xfilesSentSuccesfully", p1)
    }
    /// %d selected
    public static func xSelected(_ p1: Int) -> String {
      return Strings.tr("Localizable", "xSelected", p1)
    }
    /// [X] versions
    public static let xVersions = Strings.tr("Localizable", "xVersions")
    /// Yearly
    public static let yearly = Strings.tr("Localizable", "yearly")
    /// Yellow
    public static let yellow = Strings.tr("Localizable", "Yellow")
    /// Yes
    public static let yes = Strings.tr("Localizable", "yes")
    /// Yesterday
    public static let yesterday = Strings.tr("Localizable", "Yesterday")
    /// You accepted a contact request
    public static let youAcceptedAContactRequest = Strings.tr("Localizable", "You accepted a contact request")
    /// You are back.
    public static let youAreBack = Strings.tr("Localizable", "You are back!")
    /// You can turn on mobile data for this App in the device’s Settings.
    public static let youCanTurnOnMobileDataForThisAppInSettings = Strings.tr("Localizable", "You can turn on mobile data for this app in Settings.")
    /// You cannot remove %1$s as a contact because they are part of your Business account.
    public static func youCannotRemove1SAsAContactBecauseTheyArePartOfYourBusinessAccount(_ p1: UnsafePointer<CChar>) -> String {
      return Strings.tr("Localizable", "You cannot remove %1$s as a contact because they are part of your Business account.", p1)
    }
    /// You denied a contact request
    public static let youDeniedAContactRequest = Strings.tr("Localizable", "You denied a contact request")
    /// You didn’t receive a code?
    public static let youDidnTReceiveACode = Strings.tr("Localizable", "You didn't receive a code?")
    /// You have joined %@
    public static func youHaveJoined(_ p1: Any) -> String {
      return Strings.tr("Localizable", "You have joined %@", String(describing: p1))
    }
    /// You have reached the daily limit
    public static let youHaveReachedTheDailyLimit = Strings.tr("Localizable", "You have reached the daily limit")
    /// You have reached the maximum limit of %d reactions.
    public static func youHaveReachedTheMaximumLimitOfDReactions(_ p1: Int) -> String {
      return Strings.tr("Localizable", "You have reached the maximum limit of %d reactions.", p1)
    }
    /// You hold the keys
    public static let youHoldTheKeys = Strings.tr("Localizable", "You hold the keys")
    /// You ignored a contact request
    public static let youIgnoredAContactRequest = Strings.tr("Localizable", "You ignored a contact request")
    /// You have new messages
    public static let youMayHaveNewMessages = Strings.tr("Localizable", "You may have new messages")
    /// You have successfully changed your profile.
    public static let youHaveSuccessfullyChangedYourProfile = Strings.tr("Localizable", "youHaveSuccessfullyChangedYourProfile")
    /// We’re sorry, two-factor authentication cannot be enabled on your device. Please open the App Store to install an Authenticator app.
    public static let youNeedATwoFactorAuthenticationApp = Strings.tr("Localizable", "youNeedATwoFactorAuthenticationApp")
    /// You no longer have access to this file
    public static let youNoLongerHaveAccessToThisFileAlertTitle = Strings.tr("Localizable", "youNoLongerHaveAccessToThisFile_alertTitle")
    /// You no longer have access to this folder
    public static let youNoLongerHaveAccessToThisFolderAlertTitle = Strings.tr("Localizable", "youNoLongerHaveAccessToThisFolder_alertTitle")
    /// Your account has been temporarily locked for your safety.
    public static let yourAccountHasBeenTemporarilySuspendedForYourSafety = Strings.tr("Localizable", "Your account has been temporarily suspended for your safety.")
    /// Your account is already verified
    public static let yourAccountIsAlreadyVerified = Strings.tr("Localizable", "Your account is already verified")
    /// Account deactivated
    public static let yourBusinessAccountIsExpired = Strings.tr("Localizable", "Your business account is expired")
    /// Your Data is at Risk!
    public static let yourDataIsAtRisk = Strings.tr("Localizable", "Your Data is at Risk!")
    /// Your password leaked and is now being used by bad actors to log in to your accounts, including, but not limited to, your MEGA account.
    public static let yourPasswordLeakedAndIsNowBeingUsedByBadActorsToLogIntoYourAccountsIncludingButNotLimitedToYourMEGAAccount = Strings.tr("Localizable", "Your password leaked and is now being used by bad actors to log into your accounts, including, but not limited to, your MEGA account.")
    /// Your payment for the %1 plan was received.
    public static let yourPaymentForThe1PlanWasReceived = Strings.tr("Localizable", "Your payment for the %1 plan was received.")
    /// Your payment for the %1 plan was unsuccessful.
    public static let yourPaymentForThe1PlanWasUnsuccessful = Strings.tr("Localizable", "Your payment for the %1 plan was unsuccessful.")
    /// Your phone number
    public static let yourPhoneNumber = Strings.tr("Localizable", "Your phone number")
    /// Your phone number has been removed successfully.
    public static let yourPhoneNumberHasBeenRemovedSuccessfully = Strings.tr("Localizable", "Your phone number has been removed successfully.")
    /// Your phone number has been verified successfully
    public static let yourPhoneNumberHasBeenVerifiedSuccessfully = Strings.tr("Localizable", "Your phone number has been verified successfully")
    /// Your Photos in the Cloud
    public static let yourPhotosInTheCloud = Strings.tr("Localizable", "Your Photos in the Cloud")
    /// Your Pro plan expired %1 days ago
    public static let yourPROMembershipPlanExpired1DaysAgo = Strings.tr("Localizable", "Your PRO membership plan expired %1 days ago")
    /// Your Pro plan expired 1 day ago
    public static let yourPROMembershipPlanExpired1DayAgo = Strings.tr("Localizable", "Your PRO membership plan expired 1 day ago")
    /// Your Pro membership plan will expire in %1 days.
    public static let yourPROMembershipPlanWillExpireIn1Days = Strings.tr("Localizable", "Your PRO membership plan will expire in %1 days.")
    /// Your Pro membership plan will expire tomorrow.
    public static let yourPROMembershipPlanWillExpireIn1Day = Strings.tr("Localizable", "Your PRO membership plan will expire in 1 day.")
    /// Your upload(s) cannot proceed because your account is full
    public static let yourUploadSCannotProceedBecauseYourAccountIsFull = Strings.tr("Localizable", "Your upload(s) cannot proceed because your account is full")
    /// Your old account has been parked successfully. You can now log in to your new account.
    public static let yourAccounHasBeenParked = Strings.tr("Localizable", "yourAccounHasBeenParked")
    /// Your Recovery key is going to be used to reset your password. Please enter your new password.
    public static let youRecoveryKeyIsGoingTo = Strings.tr("Localizable", "youRecoveryKeyIsGoingTo")
    /// Your password has been reset successfully. Please log in to your account now.
    public static let yourPasswordHasBeenReset = Strings.tr("Localizable", "yourPasswordHasBeenReset")
    /// You will lose all data associated with this account. Are you sure you want to proceed?
    public static let youWillLooseAllData = Strings.tr("Localizable", "youWillLooseAllData")
    /// You will no longer have access to this conversation
    public static let youWillNoLongerHaveAccessToThisConversation = Strings.tr("Localizable", "youWillNoLongerHaveAccessToThisConversation")
    public enum BodyWarnYouMustActImmediatelyToSaveYourData {
      /// <body><warn>You must act immediately to save your data.</warn><body>
      public static let warnBody = Strings.tr("Localizable", "<body><warn>You must act immediately to save your data.</warn><body>")
    }
    public enum BodyYouHaveWarnWarnLeftToUpgrade {
      /// <body>You have <warn>%@</warn> left to upgrade.</body>
      public static func body(_ p1: Any) -> String {
        return Strings.tr("Localizable", "<body>You have <warn>%@</warn> left to upgrade.</body>", String(describing: p1))
      }
    }
    public enum ParagraphWeHaveContactedYouByEmailToBBOnBBButYouStillHaveFilesTakingUpBBInYourMEGAAccountWhichRequiresYouToContactSupportForACustomPlan {
      /// <paragraph>We have contacted you by email to <b>%@</b> on <b>%@</b> but you still have %@ files taking up <b>%@</b> in your MEGA account, which requires you to contact support for a custom plan.</paragraph>
      public static func paragraph(_ p1: Any, _ p2: Any, _ p3: Any, _ p4: Any) -> String {
        return Strings.tr("Localizable", "<paragraph>We have contacted you by email to <b>%@</b> on <b>%@</b> but you still have %@ files taking up <b>%@</b> in your MEGA account, which requires you to contact support for a custom plan.</paragraph>", String(describing: p1), String(describing: p2), String(describing: p3), String(describing: p4))
      }
    }
    public enum ParagraphWeHaveContactedYouByEmailToBBOnBBButYouStillHaveFilesTakingUpBBInYourMEGAAccountWhichRequiresYouToUpgradeToBB {
      /// <paragraph>We have contacted you by email to <b>%@</b> on <b>%@</b> but you still have %@ files taking up <b>%@</b> in your MEGA account, which requires you to upgrade to <b>%@</b>.</paragraph>
      public static func paragraph(_ p1: Any, _ p2: Any, _ p3: Any, _ p4: Any, _ p5: Any) -> String {
        return Strings.tr("Localizable", "<paragraph>We have contacted you by email to <b>%@</b> on <b>%@</b> but you still have %@ files taking up <b>%@</b> in your MEGA account, which requires you to upgrade to <b>%@</b>.</paragraph>", String(describing: p1), String(describing: p2), String(describing: p3), String(describing: p4), String(describing: p5))
      }
    }
    public enum AddYourPhoneNumberToMEGA {
      /// Add your phone number to MEGA. This makes it easier for your contacts to find you on MEGA.
      public static let thisMakesItEasierForYourContactsToFindYouOnMEGA = Strings.tr("Localizable", "Add your phone number to MEGA. This makes it easier for your contacts to find you on MEGA.")
    }
    public enum AllCurrentFilesWillRemain {
      /// All current files will remain. Only historic versions of your files will be deleted.
      public static let onlyHistoricVersionsOfYourFilesWillBeDeleted = Strings.tr("Localizable", "All current files will remain. Only historic versions of your files will be deleted.")
    }
    public enum AnErrorHasOccurred {
      /// An error has occurred. The chat history has not been successfully cleared
      public static let theChatHistoryHasNotBeenSuccessfullyCleared = Strings.tr("Localizable", "An error has occurred. The chat history has not been successfully cleared")
    }
    public enum CameraUploadsIsAnEssentialFeatureForAnyMobileDeviceAndWeHaveGotYouCovered {
      /// Camera Uploads is an essential feature for any mobile device and we have got you covered. Create your account now.
      public static let createYourAccountNow = Strings.tr("Localizable", "Camera Uploads is an essential feature for any mobile device and we have got you covered. Create your account now.")
    }
    public enum CompressionQualityWhenToTranscodeHEVCVideosToH {
      /// Compression quality when HEVC videos are transcoded to H.264 format.
      public static let _264Format = Strings.tr("Localizable", "Compression quality when to transcode HEVC videos to H.264 format.")
    }
    public enum CouldnTLoad {
      /// Couldn’t load. [RED]Tap to retry[/RED]
      public static let redTapToRetryRED = Strings.tr("Localizable", "Couldn't load. [RED]Tap to retry[/RED]")
    }
    public enum DeleteAllMessagesAndFilesSharedInThisConversationFromBothParties {
      /// Delete all messages and files shared in this conversation. This action is irreversible.
      public static let thisActionIsIrreversible = Strings.tr("Localizable", "Delete all messages and files shared in this conversation from both parties. This action is irreversible")
    }
    public enum EmailAlreadySent {
      /// Email already sent. Please wait a few minutes before trying again.
      public static let pleaseWaitAFewMinutesBeforeTryingAgain = Strings.tr("Localizable", "Email already sent. Please wait a few minutes before trying again.")
    }
    public enum EnableOrDisableFileVersioningForYourEntireAccount {
      /// Enable or disable file versioning for your entire account.
      /// Disabling file versioning does not prevent your contacts from creating new versions in shared folders.
      public static let brYouMayStillReceiveFileVersionsFromSharedFoldersIfYourContactsHaveThisEnabled = Strings.tr("Localizable", "Enable or disable file versioning for your entire account.[Br]You may still receive file versions from shared folders if your contacts have this enabled.")
    }
    public enum Error {
      /// You are not allowed to join this call as it has reached the maximum number of participants.
      public static let noMoreParticipantsAreAllowedInThisGroupCall = Strings.tr("Localizable", "Error. No more participants are allowed in this group call.")
      /// You are not allowed to enable video as this call has reached the maximum number of participants using video.
      public static let noMoreVideoAreAllowedInThisGroupCall = Strings.tr("Localizable", "Error. No more video are allowed in this group call.")
    }
    public enum FreeUpSomeSpaceByDeletingAppsYouNoLongerUseOrLargeVideoFilesInYourGallery {
      /// Free up some space by deleting apps you no longer use or large video files in your gallery. You can manage your storage in %@
      public static func youCanManageYourStorageIn(_ p1: Any) -> String {
        return Strings.tr("Localizable", "Free up some space by deleting apps you no longer use or large video files in your gallery. You can manage your storage in %@", String(describing: p1))
      }
    }
    public enum GetFreeWhenYouAddYourPhoneNumber {
      /// Get %@ free when you add your phone number. This makes it easier for your contacts to find you on MEGA.
      public static func thisMakesItEasierForYourContactsToFindYouOnMEGA(_ p1: Any) -> String {
        return Strings.tr("Localizable", "Get free %@ when you add your phone number. This makes it easier for your contacts to find you on MEGA.", String(describing: p1))
      }
    }
    public enum MEGANeedsAMinimumOf {
      public enum FreeUpSomeSpaceByDeletingAppsYouNoLongerUseOrLargeVideoFilesInYourGallery {
        /// MEGA needs a minimum of %@. Free up some space by deleting apps you no longer use or large video files in your gallery. You can also manage what MEGA stores on your device.
        public static func youCanAlsoManageWhatMEGAStoresOnYourDevice(_ p1: Any) -> String {
          return Strings.tr("Localizable", "MEGA needs a minimum of %@. Free up some space by deleting apps you no longer use or large video files in your gallery. You can also manage what MEGA stores on your device.", String(describing: p1))
        }
      }
    }
    public enum NowYouCanChooseToConvertTheHEIFHEVCPhotosAndVideosToTheMostCompatibleJPEGH {
      /// Now you can choose to convert HEIC/HEVC photos and videos to the more widely compatible JPEG/H.264 formats.
      public static let _264Formats = Strings.tr("Localizable", "Now you can choose to convert the HEIF/HEVC photos and videos to the most compatible JPEG/H.264 formats.")
    }
    public enum OurEndToEndEncryptionSystemRequiresAUniqueKeyAutomaticallyGeneratedForThisFile {
      /// Our end-to-end encryption system requires a unique key automatically generated for this file. A link with this key is created by default, but you can export the decryption key separately for an added layer of security.
      public static let aLinkWithThisKeyIsCreatedByDefaultButYouCanExportTheDecryptionKeySeparatelyForAnAddedLayerOfSecurity = Strings.tr("Localizable", "Our end-to-end encryption system requires a unique key automatically generated for this file. A link with this key is created by default, but you can export the decryption key separately for an added layer of security.")
    }
    public enum PleaseGoToThePrivacySectionInYourDeviceSSetting {
      /// Please go to the Privacy section in your device’s Settings. Enable Location Services and set MEGA to While Using the App or Always.
      public static let enableLocationServicesAndSetMEGAToWhileUsingTheAppOrAlways = Strings.tr("Localizable", "Please go to the Privacy section in your device’s Setting. Enable Location Services and set MEGA to While Using the App or Always.")
    }
    public enum TheMEGAAppMayNotWorkAsExpectedWithoutTheRequiredPermissions {
      /// The MEGA App may not work as expected without the required permissions. Are you sure?
      public static let areYouSure = Strings.tr("Localizable", "The MEGA app may not work as expected without the required permissions. Are you sure?")
    }
    public enum TheRubbishBinCanBeCleanedForYouAutomatically {
      /// The Rubbish bin can be emptied for you automatically. The minimum period is 7 days.
      public static let theMinimumPeriodIs7Days = Strings.tr("Localizable", "The Rubbish Bin can be cleaned for you automatically. The minimum period is 7 days.")
    }
    public enum TheRubbishBinIsCleanedForYouAutomatically {
      /// The Rubbish bin is emptied for you automatically. The minimum period is 7 days and the maximum period is 30 days.
      public static let theMinimumPeriodIs7DaysAndYourMaximumPeriodIs30Days = Strings.tr("Localizable", "The Rubbish Bin is cleaned for you automatically. The minimum period is 7 days and your maximum period is 30 days.")
    }
    public enum ThereHasBeenAProblemProcessingYourPayment {
      /// Your Business account has been deactivated due to payment failure. You won’t be able to access the data stored in your account. To make a payment and reactivate your subscription, log in to MEGA through a browser.
      public static let megaIsLimitedToViewOnlyUntilThisIssueHasBeenFixedInADesktopWebBrowser = Strings.tr("Localizable", "There has been a problem processing your payment. MEGA is limited to view only until this issue has been fixed in a desktop web browser.")
    }
    public enum ThereHasBeenAProblemWithYourLastPayment {
      /// There has been a problem with your last payment. Please access MEGA using a desktop browser for more information.
      public static let pleaseAccessMEGAUsingADesktopBrowserForMoreInformation = Strings.tr("Localizable", "There has been a problem with your last payment. Please access MEGA using a desktop browser for more information.")
    }
    public enum ThereIsAnActiveCall {
      /// There is an active call. Tap to join.
      public static let tapToJoin = Strings.tr("Localizable", "There is an active call. Tap to join.")
    }
    public enum ThereIsAnActiveGroupCall {
      /// There is an active group call. Tap to join.
      public static let tapToJoin = Strings.tr("Localizable", "There is an active group call. Tap to join.")
    }
    public enum ThisLinkIsNotRelatedToThisAccount {
      /// This link is not related to this account. Please log in with the correct account.
      public static let pleaseLogInWithTheCorrectAccount = Strings.tr("Localizable", "This link is not related to this account. Please log in with the correct account.")
    }
    public enum ThisLinkWasSharedWithoutADecryptionKey {
      /// This link was shared without a decryption key. Do you want to share its key?
      public static let doYouWantToShareItsKey = Strings.tr("Localizable", "This link was shared without a decryption key. Do you want to share its key?")
    }
    public enum ThisWillRemoveYourAssociatedPhoneNumberFromYourAccount {
      /// This will remove your associated phone number from your account. If you later choose to add a phone number you will be required to verify it.
      public static let ifYouLaterChooseToAddAPhoneNumberYouWillBeRequiredToVerifyIt = Strings.tr("Localizable", "This will remove your associated phone number from your account. If you later choose to add a phone number you will be required to verify it.")
    }
    public enum WeRecommendH {
      /// We recommend H.264, as it is the most compatible format for videos.
      public static let _264AsItsTheMostCompatibleFormatForVideos = Strings.tr("Localizable", "We recommend H.264, as its the most compatible format for videos.")
    }
    public enum WhenFileVersioningIsDisabledTheCurrentVersionWillBeReplacedWithTheNewVersionOnceAFileIsUpdatedAndYourChangesToTheFileWillNoLongerBeRecorded {
      /// When file versioning is disabled, the current version will be replaced with the new version once a file is updated (and your changes to the file will no longer be recorded). Are you sure you want to disable file versioning?
      public static let areYouSureYouWantToDisableFileVersioning = Strings.tr("Localizable", "When file versioning is disabled, the current version will be replaced with the new version once a file is updated (and your changes to the file will no longer be recorded). Are you sure you want to disable file versioning?")
    }
    public enum WrongCode {
      /// Wrong code. Please try again or resend.
      public static let pleaseTryAgainOrResend = Strings.tr("Localizable", "Wrong code. Please try again or resend.")
    }
    public enum YouAreAboutToDeleteTheVersionHistoriesOfAllFiles {
      public enum AnyFileVersionSharedToYouFromAContactWillNeedToBeDeletedByThem {
        /// You are about to delete the version histories of all files. Any file version shared to you from a contact will need to be deleted by them.
        /// 
        /// Please note that the current files will not be deleted.
        public static let brBrPleaseNoteThatTheCurrentFilesWillNotBeDeleted = Strings.tr("Localizable", "You are about to delete the version histories of all files. Any file version shared to you from a contact will need to be deleted by them.[Br][Br]Please note that the current files will not be deleted.")
      }
    }
    public enum YouCanNowSelectWhichSectionTheAppOpensAtLaunch {
      /// You can now select which section the app opens at launch. Choose the one that better suits your needs, whether it’s Chat, Cloud Drive, or Home.
      public static let chooseTheOneThatBetterSuitsYourNeedsWhetherItSChatCloudDriveOrHome = Strings.tr("Localizable", "You can now select which section the app opens at launch. Choose the one that better suits your needs, whether it’s Chat, Cloud Drive, or Home.")
    }
    public enum YouDoNotHaveEnoughStorageToUploadCamera {
      public enum FreeUpSpaceByDeletingUnneededAppsVideosOrMusic {
        /// You do not have enough storage for further camera uploads. Free up space by deleting unneeded apps, videos or music. You can manage your storage in %@
        public static func youCanManageYourStorageIn(_ p1: Any) -> String {
          return Strings.tr("Localizable", "You do not have enough storage to upload camera. Free up space by deleting unneeded apps, videos or music. You can manage your storage in %@", String(describing: p1))
        }
      }
    }
    public enum YouDoNotHaveThePermissionsRequiredToRevertThisFile {
      public enum InOrderToContinueWeCanCreateANewFileWithTheRevertedData {
        /// You do not have the permissions required to revert this file. In order to continue, we can create a new file with the reverted data. Would you like to proceed?
        public static let wouldYouLikeToProceed = Strings.tr("Localizable", "You do not have the permissions required to revert this file. In order to continue, we can create a new file with the reverted data. Would you like to proceed?")
      }
    }
    public enum YouNeedAnAuthenticatorAppToEnable2FAOnMEGA {
      /// You need an authenticator app to enable 2FA on MEGA. You can download and install the Google Authenticator, Duo Mobile, Authy or Microsoft Authenticator app for your phone or tablet.
      public static let youCanDownloadAndInstallTheGoogleAuthenticatorDuoMobileAuthyOrMicrosoftAuthenticatorAppForYourPhoneOrTablet = Strings.tr("Localizable", "You need an authenticator app to enable 2FA on MEGA. You can download and install the Google Authenticator, Duo Mobile, Authy or Microsoft Authenticator app for your phone or tablet.")
    }
    public enum YourAccountHasBeenDisabledByYourAdministrator {
      /// Your account has been deactivated by your administrator. Please contact your business account administrator for further details.
      public static let pleaseContactYourBusinessAccountAdministratorForFurtherDetails = Strings.tr("Localizable", "Your account has been disabled by your administrator. Please contact your business account administrator for further details.")
    }
    public enum YourAccountHasBeenRemovedByYourAdministrator {
      /// Your account has been removed by your administrator. Please contact your business account administrator for further details.
      public static let pleaseContactYourBusinessAccountAdministratorForFurtherDetails = Strings.tr("Localizable", "Your account has been removed by your administrator. Please contact your business account administrator for further details.")
    }
    public enum YourAccountHasBeenSuspendedTemporarilyDueToPotentialAbuse {
      /// Your account has been locked temporarily due to potential abuse. Please verify your phone number to unlock your account.
      public static let pleaseVerifyYourPhoneNumberToUnlockYourAccount = Strings.tr("Localizable", "Your account has been suspended temporarily due to potential abuse. Please verify your phone number to unlock your account.")
    }
    public enum YourAccountIsCurrentlyBSuspendedB {
      /// Your account is currently [B]suspended[/B]. You can only browse your data.
      public static let youCanOnlyBrowseYourData = Strings.tr("Localizable", "Your account is currently [B]suspended[/B]. You can only browse your data.")
    }
    public enum YourConfirmationLinkIsNoLongerValid {
      /// Your confirmation link is no longer valid. Your account may already be activated or you may have cancelled your registration.
      public static let yourAccountMayAlreadyBeActivatedOrYouMayHaveCancelledYourRegistration = Strings.tr("Localizable", "Your confirmation link is no longer valid. Your account may already be activated or you may have cancelled your registration.")
    }
    public enum A1SABChangedTheMessageClearingTimeToBA2SAB {
      /// [A]%1$s[/A][B] changed the message clearing time to[/B][A] %2$s[/A][B].[/B]
      public static func b(_ p1: UnsafePointer<CChar>, _ p2: UnsafePointer<CChar>) -> String {
        return Strings.tr("Localizable", "[A]%1$s[/A][B] changed the message clearing time to[/B][A] %2$s[/A][B].[/B]", p1, p2)
      }
    }
    public enum A1SABDisabledMessageClearing {
      /// [A]%1$s[/A][B] disabled message clearing.[/B]
      public static func b(_ p1: UnsafePointer<CChar>) -> String {
        return Strings.tr("Localizable", "[A]%1$s[/A][B] disabled message clearing.[/B]", p1)
      }
    }
    public enum AGroupCallEndedAC {
      /// [A]Group call ended[/A][C]. Duration: [/C]
      public static let durationC = Strings.tr("Localizable", "[A]Group call ended[/A][C]. Duration: [/C]")
    }
    public enum Account {
      /// %@ Storage
      public static func storageQuota(_ p1: Any) -> String {
        return Strings.tr("Localizable", "account.storageQuota", String(describing: p1))
      }
      public enum Achievement {
        public enum Complete {
          public enum Valid {
            public enum Cell {
              /// %@ days left
              public static func subtitle(_ p1: Any) -> String {
                return Strings.tr("Localizable", "account.achievement.complete.valid.cell.subtitle", String(describing: p1))
              }
            }
            public enum Detail {
              /// Bonus expires in %@ days.
              public static func subtitle(_ p1: Any) -> String {
                return Strings.tr("Localizable", "account.achievement.complete.valid.detail.subtitle", String(describing: p1))
              }
            }
          }
        }
        public enum DesktopApp {
          /// Install the MEGA Desktop App
          public static let title = Strings.tr("Localizable", "account.achievement.desktopApp.title")
          public enum Complete {
            public enum Explaination {
              /// You have received %@ storage space for installing the MEGA Desktop App.
              public static func label(_ p1: Any) -> String {
                return Strings.tr("Localizable", "account.achievement.desktopApp.complete.explaination.label", String(describing: p1))
              }
            }
          }
          public enum Incomplete {
            public enum Explaination {
              /// When you install the MEGA Desktop App you get %@ of complimentary storage space, valid for 365 days. The MEGA Desktop App is available for Windows, macOS and most Linux distributions.
              public static func label(_ p1: Any) -> String {
                return Strings.tr("Localizable", "account.achievement.desktopApp.incomplete.explaination.label", String(describing: p1))
              }
            }
          }
        }
        public enum Incomplete {
          /// %@ of storage. Valid for 365 days.
          public static func subtitle(_ p1: Any) -> String {
            return Strings.tr("Localizable", "account.achievement.incomplete.subtitle", String(describing: p1))
          }
        }
        public enum MobileApp {
          /// Install the MEGA Mobile App
          public static let title = Strings.tr("Localizable", "account.achievement.mobileApp.title")
          public enum Complete {
            public enum Explaination {
              /// You have received %@ storage space for installing the MEGA mobile app.
              public static func label(_ p1: Any) -> String {
                return Strings.tr("Localizable", "account.achievement.mobileApp.complete.explaination.label", String(describing: p1))
              }
            }
          }
          public enum Incomplete {
            public enum Explaination {
              /// When you install the MEGA Mobile App you get %@ of complimentary storage space, valid for 365 days. The MEGA Mobile App is available for iOS and Android. 
              public static func label(_ p1: Any) -> String {
                return Strings.tr("Localizable", "account.achievement.mobileApp.incomplete.explaination.label", String(describing: p1))
              }
            }
          }
        }
        public enum PhoneNumber {
          public enum Complete {
            public enum Explaination {
              /// You have received %@ storage space for adding your phone number.
              public static func label(_ p1: Any) -> String {
                return Strings.tr("Localizable", "account.achievement.phoneNumber.complete.explaination.label", String(describing: p1))
              }
            }
          }
          public enum Incomplete {
            public enum Explaination {
              /// When you add your phone number you get %@ of complimentary storage space, valid for 365 days.
              public static func label(_ p1: Any) -> String {
                return Strings.tr("Localizable", "account.achievement.phoneNumber.incomplete.explaination.label", String(describing: p1))
              }
            }
          }
        }
        public enum Referral {
          /// %@ of storage for each referral. 
          /// Valid for 365 days.
          public static func subtitle(_ p1: Any) -> String {
            return Strings.tr("Localizable", "account.achievement.referral.subtitle", String(describing: p1))
          }
          /// Invite your friends
          public static let title = Strings.tr("Localizable", "account.achievement.referral.title")
        }
        public enum ReferralBonus {
          /// Referral bonuses
          public static let title = Strings.tr("Localizable", "account.achievement.referralBonus.title")
        }
        public enum Registration {
          /// Registration Bonus
          public static let title = Strings.tr("Localizable", "account.achievement.registration.title")
          public enum Explanation {
            /// You have received %@ storage space as your free registration bonus.
            public static func label(_ p1: Any) -> String {
              return Strings.tr("Localizable", "account.achievement.registration.explanation.label", String(describing: p1))
            }
          }
        }
      }
      public enum ChangeEmail {
        /// Current email address
        public static let currentEmail = Strings.tr("Localizable", "account.changeEmail.currentEmail")
      }
      public enum ChangePassword {
        public enum Error {
          /// You have entered your current password.
          public static let currentPassword = Strings.tr("Localizable", "account.changePassword.error.currentPassword")
        }
      }
      public enum CreateAccount {
        /// Already have an account?
        public static let alreadyHaveAnAccount = Strings.tr("Localizable", "account.createAccount.alreadyHaveAnAccount")
      }
      public enum Delete {
        public enum Subscription {
          /// You have an active MEGA subscription with Google. You must cancel it separately in Google Play, as MEGA is not able to cancel it for you. Visit our Help Centre for more information.
          public static let googlePlay = Strings.tr("Localizable", "account.delete.subscription.googlePlay")
          /// You have an active MEGA subscription with Huawei. You must cancel it separately at Huawei AppGallery, as MEGA is not able to cancel it for you. Visit our Help Centre for more information.
          public static let huaweiAppGallery = Strings.tr("Localizable", "account.delete.subscription.huaweiAppGallery")
          /// You have an active MEGA subscription with Apple. You must cancel it separately at Subscriptions, as MEGA is not able to cancel it for you. Visit our Help Centre for more information.
          public static let itunes = Strings.tr("Localizable", "account.delete.subscription.itunes")
          /// Active Subscription
          public static let title = Strings.tr("Localizable", "account.delete.subscription.title")
          /// This is the last step to delete your account. Both your account and subscription will be deleted and you will permanently lose all the data stored in the cloud. Please enter your password below.
          public static let webClient = Strings.tr("Localizable", "account.delete.subscription.webClient")
          public enum GooglePlay {
            /// Visit Google Play
            public static let visit = Strings.tr("Localizable", "account.delete.subscription.googlePlay.visit")
          }
          public enum HuaweiAppGallery {
            /// Visit AppGallery
            public static let visit = Strings.tr("Localizable", "account.delete.subscription.huaweiAppGallery.visit")
          }
          public enum Itunes {
            /// Manage Subscriptions
            public static let manage = Strings.tr("Localizable", "account.delete.subscription.itunes.manage")
          }
        }
      }
      public enum Expired {
        public enum ProFlexi {
          /// Your Pro Flexi account has been deactivated due to payment failure or you’ve cancelled your subscription. You won’t be able to access the data stored in your account. To make a payment and reactivate your subscription, log in to MEGA through a browser.
          public static let message = Strings.tr("Localizable", "account.expired.proFlexi.message")
          /// Account deactivated
          public static let title = Strings.tr("Localizable", "account.expired.proFlexi.title")
        }
      }
      public enum Login {
        /// New to MEGA?
        public static let newToMega = Strings.tr("Localizable", "account.login.newToMega")
      }
      public enum Storage {
        /// [B]20 GB+[/B] Storage
        public static let freePlan = Strings.tr("Localizable", "account.storage.freePlan")
        public enum StorageUsed {
          /// Storage used
          public static let title = Strings.tr("Localizable", "account.storage.storageUsed.title")
        }
        public enum TransferUsed {
          /// Transfer used
          public static let title = Strings.tr("Localizable", "account.storage.transferUsed.title")
        }
      }
      public enum Suspension {
        public enum Message {
          /// Account suspended due to copyright violations. We sent you an email with more information about this.
          public static let copyright = Strings.tr("Localizable", "account.suspension.message.copyright")
          /// Account terminated due to a breach of MEGA’s Terms of Service, such as abuse of others’ rights, sharing and importing illegal data, or system abuse.
          public static let nonCopyright = Strings.tr("Localizable", "account.suspension.message.nonCopyright")
        }
      }
      public enum TransferQuota {
        /// [B]Limited[/B] Transfer
        public static let freePlan = Strings.tr("Localizable", "account.transferQuota.freePlan")
        /// %@ Transfer
        public static func perMonth(_ p1: Any) -> String {
          return Strings.tr("Localizable", "account.transferQuota.perMonth", String(describing: p1))
        }
      }
      public enum Upgrade {
        public enum AlreadyHaveACancellableSubscription {
          /// Do you want to cancel your current subscription and continue with the purchase?
          public static let message = Strings.tr("Localizable", "account.upgrade.alreadyHaveACancellableSubscription.message")
        }
        public enum AlreadyHaveASubscription {
          /// You have previously subscribed to a Pro plan with Google Play or AppGallery. Please manually cancel your subscription with them inside Google Play or the Huawei AppGallery on your device and then retry.
          public static let message = Strings.tr("Localizable", "account.upgrade.alreadyHaveASubscription.message")
          /// You already have an active subscription
          public static let title = Strings.tr("Localizable", "account.upgrade.alreadyHaveASubscription.title")
        }
      }
    }
    public enum AutoAway {
      /// Set status as Away after [X] of inactivity.
      public static let footerDescription = Strings.tr("Localizable", "autoAway.footerDescription")
    }
    public enum Backups {
      /// Backups
      public static let title = Strings.tr("Localizable", "backups.title")
      public enum Empty {
        public enum State {
          /// This is where your backed up files and folders are stored. Your backed up items are “read-only” to protect them from being accidentally modified in your Cloud drive.
          /// You can back up items from your computer to MEGA using our desktop app.
          public static let description = Strings.tr("Localizable", "backups.empty.state.description")
          /// No items in backups
          public static let message = Strings.tr("Localizable", "backups.empty.state.message")
        }
      }
    }
    public enum Call {
      public enum Duration {
        /// Plural format key: "%#@hour@"
        public static func hour(_ p1: Int) -> String {
          return Strings.tr("Localizable", "call.duration.hour", p1)
        }
        /// Plural format key: "%#@minute@"
        public static func minute(_ p1: Int) -> String {
          return Strings.tr("Localizable", "call.duration.minute", p1)
        }
        /// Plural format key: "%#@second@"
        public static func second(_ p1: Int) -> String {
          return Strings.tr("Localizable", "call.duration.second", p1)
        }
        public enum HourAndMinute {
          /// Plural format key: "%#@hour@"
          public static func hour(_ p1: Int) -> String {
            return Strings.tr("Localizable", "call.duration.hourAndMinute.hour", p1)
          }
          /// Plural format key: "%#@minute@"
          public static func minute(_ p1: Int) -> String {
            return Strings.tr("Localizable", "call.duration.hourAndMinute.minute", p1)
          }
        }
      }
    }
    public enum CameraUploads {
      public enum Albums {
        /// Albums
        public static let title = Strings.tr("Localizable", "cameraUploads.albums.title")
        public enum Create {
          /// Add items to
          public static let location = Strings.tr("Localizable", "cameraUploads.albums.create.location")
          public enum Alert {
            /// New album
            public static let placeholder = Strings.tr("Localizable", "cameraUploads.albums.create.alert.placeholder")
            /// This album name is not allowed
            public static let systemAlbumExists = Strings.tr("Localizable", "cameraUploads.albums.create.alert.systemAlbumExists")
            /// Enter album name
            public static let title = Strings.tr("Localizable", "cameraUploads.albums.create.alert.title")
            /// An album with that name already exists
            public static let userAlbumExists = Strings.tr("Localizable", "cameraUploads.albums.create.alert.userAlbumExists")
          }
        }
        public enum CreateAlbum {
          /// Create album
          public static let title = Strings.tr("Localizable", "cameraUploads.albums.createAlbum.title")
        }
        public enum Empty {
          /// Empty album
          public static let title = Strings.tr("Localizable", "cameraUploads.albums.empty.title")
        }
        public enum Favourites {
          /// Favourites
          public static let title = Strings.tr("Localizable", "cameraUploads.albums.favourites.title")
        }
        public enum Gif {
          /// GIFs
          public static let title = Strings.tr("Localizable", "cameraUploads.albums.gif.title")
        }
        public enum Raw {
          /// RAW
          public static let title = Strings.tr("Localizable", "cameraUploads.albums.raw.title")
        }
      }
      public enum Timeline {
        /// Timeline
        public static let title = Strings.tr("Localizable", "cameraUploads.timeline.title")
        public enum AllMedia {
          public enum Empty {
            /// No media found
            public static let title = Strings.tr("Localizable", "cameraUploads.timeline.allMedia.empty.title")
          }
        }
        public enum Filter {
          /// Choose type
          public static let chooseType = Strings.tr("Localizable", "cameraUploads.timeline.filter.chooseType")
          /// Show items from:
          public static let showItemsFrom = Strings.tr("Localizable", "cameraUploads.timeline.filter.showItemsFrom")
          public enum Location {
            /// All locations
            public static let allLocations = Strings.tr("Localizable", "cameraUploads.timeline.filter.location.allLocations")
            /// Camera uploads
            public static let cameraUploads = Strings.tr("Localizable", "cameraUploads.timeline.filter.location.cameraUploads")
            /// Cloud drive
            public static let cloudDrive = Strings.tr("Localizable", "cameraUploads.timeline.filter.location.cloudDrive")
          }
          public enum MediaType {
            /// All media
            public static let allMedia = Strings.tr("Localizable", "cameraUploads.timeline.filter.mediaType.allMedia")
            /// Images
            public static let images = Strings.tr("Localizable", "cameraUploads.timeline.filter.mediaType.images")
            /// Videos
            public static let videos = Strings.tr("Localizable", "cameraUploads.timeline.filter.mediaType.videos")
          }
        }
      }
      public enum Warning {
        /// ⚠ MEGA has limited access to your photo library and cannot backup all of your photos. Tap to change permissions.
        public static let limitedAccessToPhotoMessage = Strings.tr("Localizable", "cameraUploads.warning.limitedAccessToPhotoMessage")
      }
    }
    public enum Chat {
      /// Join Call
      public static let joinCall = Strings.tr("Localizable", "chat.joinCall")
      /// Chat
      public static let title = Strings.tr("Localizable", "chat.title")
      public enum AddToChatMenu {
        /// Files
        public static let filesApp = Strings.tr("Localizable", "chat.addToChatMenu.filesApp")
        /// Scan
        public static let scan = Strings.tr("Localizable", "chat.addToChatMenu.scan")
      }
      public enum AutoAway {
        /// Plural format key: "%#@hour@"
        public static func hour(_ p1: Int) -> String {
          return Strings.tr("Localizable", "chat.autoAway.hour", p1)
        }
        /// Plural format key: "%#@minute@"
        public static func minute(_ p1: Int) -> String {
          return Strings.tr("Localizable", "chat.autoAway.minute", p1)
        }
        public enum Label {
          /// Plural format key: "%#@hour@"
          public static func hour(_ p1: Int) -> String {
            return Strings.tr("Localizable", "chat.autoAway.label.hour", p1)
          }
          /// Plural format key: "%#@minute@"
          public static func minute(_ p1: Int) -> String {
            return Strings.tr("Localizable", "chat.autoAway.label.minute", p1)
          }
        }
      }
      public enum Chats {
        public enum EmptyState {
          /// Chat securely and privately, with anyone and on any device, knowing that no one can read your chats, not even MEGA.
          public static let description = Strings.tr("Localizable", "chat.chats.emptyState.description")
          /// Start chatting now
          public static let title = Strings.tr("Localizable", "chat.chats.emptyState.title")
          public enum Button {
            /// New chat
            public static let title = Strings.tr("Localizable", "chat.chats.emptyState.button.title")
          }
        }
      }
      public enum Link {
        /// Link removed
        public static let linkRemoved = Strings.tr("Localizable", "chat.link.linkRemoved")
      }
      public enum Listing {
        public enum Description {
          public enum MeetingCreated {
            /// %@: Created a meeting
            public static func message(_ p1: Any) -> String {
              return Strings.tr("Localizable", "chat.listing.description.meetingCreated.message", String(describing: p1))
            }
          }
        }
        public enum SectionHeader {
          public enum PastMeetings {
            /// Past meetings
            public static let title = Strings.tr("Localizable", "chat.listing.sectionHeader.pastMeetings.title")
          }
        }
      }
      public enum ManageHistory {
        public enum Clearing {
          public enum Custom {
            public enum Option {
              /// Plural format key: "%#@day@"
              public static func day(_ p1: Int) -> String {
                return Strings.tr("Localizable", "chat.manageHistory.clearing.custom.option.day", p1)
              }
              /// Plural format key: "%#@hour@"
              public static func hour(_ p1: Int) -> String {
                return Strings.tr("Localizable", "chat.manageHistory.clearing.custom.option.hour", p1)
              }
              /// Plural format key: "%#@month@"
              public static func month(_ p1: Int) -> String {
                return Strings.tr("Localizable", "chat.manageHistory.clearing.custom.option.month", p1)
              }
              /// Plural format key: "%#@week@"
              public static func week(_ p1: Int) -> String {
                return Strings.tr("Localizable", "chat.manageHistory.clearing.custom.option.week", p1)
              }
              /// Plural format key: "%#@year@"
              public static func year(_ p1: Int) -> String {
                return Strings.tr("Localizable", "chat.manageHistory.clearing.custom.option.year", p1)
              }
            }
          }
        }
        public enum Message {
          /// Automatically delete messages older than %@
          public static func deleteMessageOlderThanCustomValue(_ p1: Any) -> String {
            return Strings.tr("Localizable", "chat.manageHistory.message.deleteMessageOlderThanCustomValue", String(describing: p1))
          }
        }
      }
      public enum Map {
        /// Location
        public static let location = Strings.tr("Localizable", "chat.map.location")
        public enum Location {
          /// Enable geolocation failed. Error: %@
          public static func enableGeolocationFailedError(_ p1: Any) -> String {
            return Strings.tr("Localizable", "chat.map.location.enableGeolocationFailedError", String(describing: p1))
          }
        }
      }
      public enum Match {
        /// File
        public static let file = Strings.tr("Localizable", "chat.match.file")
      }
      public enum Meetings {
        public enum EmptyState {
          /// Talk securely and privately on audio or video calls with friends and colleagues around the world.
          public static let description = Strings.tr("Localizable", "chat.meetings.emptyState.description")
          /// Start a meeting
          public static let title = Strings.tr("Localizable", "chat.meetings.emptyState.title")
          public enum Button {
            /// New meeting
            public static let title = Strings.tr("Localizable", "chat.meetings.emptyState.button.title")
          }
        }
      }
      public enum Message {
        /// Message…
        public static let placeholder = Strings.tr("Localizable", "chat.message.placeholder")
        public enum ChangedRole {
          /// [A] was changed to [S]host role[/S] by [B]
          public static let host = Strings.tr("Localizable", "chat.message.changedRole.host")
          /// [A] was changed to [S]read-only[/S] by [B]
          public static let readOnly = Strings.tr("Localizable", "chat.message.changedRole.readOnly")
          /// [A] was changed to [S]standard role[/S] by [B]
          public static let standard = Strings.tr("Localizable", "chat.message.changedRole.standard")
        }
      }
      public enum Photos {
        /// To share photos and videos, grant MEGA access to your gallery
        public static let allowPhotoAccessMessage = Strings.tr("Localizable", "chat.photos.allowPhotoAccessMessage")
      }
      public enum Selector {
        /// Chats
        public static let chat = Strings.tr("Localizable", "chat.selector.chat")
        /// Meetings
        public static let meeting = Strings.tr("Localizable", "chat.selector.meeting")
      }
      public enum SendLocation {
        public enum Map {
          /// Hybrid
          public static let hybrid = Strings.tr("Localizable", "chat.sendLocation.map.hybrid")
          /// Satellite
          public static let satellite = Strings.tr("Localizable", "chat.sendLocation.map.satellite")
          /// Standard
          public static let standard = Strings.tr("Localizable", "chat.sendLocation.map.standard")
        }
      }
      public enum Status {
        public enum Duration {
          /// Plural format key: "%#@minute@"
          public static func minute(_ p1: Int) -> String {
            return Strings.tr("Localizable", "chat.status.duration.minute", p1)
          }
        }
      }
    }
    public enum CloudDrive {
      public enum Info {
        public enum Node {
          /// Location
          public static let location = Strings.tr("Localizable", "cloudDrive.info.node.location")
        }
      }
      public enum MediaDiscovery {
        /// Exit
        public static let exit = Strings.tr("Localizable", "cloudDrive.mediaDiscovery.exit")
      }
      public enum Menu {
        public enum MediaDiscovery {
          /// Media Discovery
          public static let title = Strings.tr("Localizable", "cloudDrive.menu.mediaDiscovery.title")
        }
      }
      public enum NodeInfo {
        /// %@ (Owner)
        public static func owner(_ p1: Any) -> String {
          return Strings.tr("Localizable", "cloudDrive.nodeInfo.owner", String(describing: p1))
        }
      }
      public enum ScanDocument {
        /// Scan %@
        public static func defaultName(_ p1: Any) -> String {
          return Strings.tr("Localizable", "cloudDrive.scanDocument.defaultName", String(describing: p1))
        }
      }
      public enum Sort {
        /// Label
        public static let label = Strings.tr("Localizable", "cloudDrive.sort.label")
      }
      public enum Upload {
        /// Import from Files
        public static let importFromFiles = Strings.tr("Localizable", "cloudDrive.upload.importFromFiles")
      }
    }
    public enum Contact {
      public enum Invite {
        /// You have a MEGA Secure Chat request waiting. Register an account on MEGA and get 20 GB free lifetime storage.
        public static let message = Strings.tr("Localizable", "contact.invite.message")
      }
    }
    public enum Dialog {
      public enum Add {
        public enum Items {
          public enum Backup {
            public enum Action {
              /// Add
              public static let title = Strings.tr("Localizable", "dialog.add.items.backup.action.title")
            }
            public enum Folder {
              public enum Warning {
                /// Adding items to this folder changes the backup destination. The backup will be turned off for safety. Is this what you want to do? Backups can be re-enabled with the MEGA Desktop App.
                public static let message = Strings.tr("Localizable", "dialog.add.items.backup.folder.warning.message")
                /// Add Item to “%@”
                public static func title(_ p1: Any) -> String {
                  return Strings.tr("Localizable", "dialog.add.items.backup.folder.warning.title", String(describing: p1))
                }
              }
            }
          }
        }
      }
      public enum Backup {
        public enum Folder {
          public enum Location {
            public enum Warning {
              /// Moving this folder changes the backup destination. The backup will be turned off for safety. Is this what you want to do? Backups can be re-enabled with the MEGA Desktop App.
              public static let message = Strings.tr("Localizable", "dialog.backup.folder.location.warning.message")
              /// Move “%@”
              public static func title(_ p1: Any) -> String {
                return Strings.tr("Localizable", "dialog.backup.folder.location.warning.title", String(describing: p1))
              }
            }
          }
        }
        public enum Setup {
          /// Use our Desktop App to ensure your backup folder is synchronised with your MEGA Cloud.
          public static let message = Strings.tr("Localizable", "dialog.backup.setup.message")
          /// Set up Backup
          public static let title = Strings.tr("Localizable", "dialog.backup.setup.title")
        }
        public enum Warning {
          public enum Confirm {
            /// Please type “%@” to confirm this action
            public static func message(_ p1: Any) -> String {
              return Strings.tr("Localizable", "dialog.backup.warning.confirm.message", String(describing: p1))
            }
          }
        }
      }
      public enum CallAttempt {
        /// Your contact [X] is not on MEGA. In order to call through MEGA’s encrypted chat you need to invite your contact
        public static let contactNotInMEGA = Strings.tr("Localizable", "dialog.callAttempt.contactNotInMEGA")
      }
      public enum Confirmation {
        public enum Error {
          /// Text entered does not match
          public static let message = Strings.tr("Localizable", "dialog.confirmation.error.message")
        }
      }
      public enum Cookies {
        /// Accept Cookies
        public static let accept = Strings.tr("Localizable", "dialog.cookies.accept")
        /// We use Cookies and similar technologies (“Cookies”) to provide and enhance your experience with our services. Accept our use of Cookies from the beginning of your visit or customise Cookies in Cookie Settings. Read more in our [A]Cookie Policy[/A].
        public static let description = Strings.tr("Localizable", "dialog.cookies.description")
        public enum Title {
          /// Your privacy
          public static let yourPrivacy = Strings.tr("Localizable", "dialog.cookies.title.yourPrivacy")
        }
      }
      public enum Delete {
        public enum Backup {
          /// delete backup
          public static let placeholder = Strings.tr("Localizable", "dialog.delete.backup.placeholder")
          public enum Action {
            /// Move to Rubbish Bin
            public static let title = Strings.tr("Localizable", "dialog.delete.backup.action.title")
          }
          public enum Folder {
            public enum Warning {
              /// Are you sure you want to delete your backup folder and disable backup you set?
              public static let message = Strings.tr("Localizable", "dialog.delete.backup.folder.warning.message")
              /// Move “%@” to Rubbish Bin
              public static func title(_ p1: Any) -> String {
                return Strings.tr("Localizable", "dialog.delete.backup.folder.warning.title", String(describing: p1))
              }
            }
          }
        }
        public enum Root {
          public enum Backup {
            public enum Folder {
              public enum Warning {
                /// You are deleting your backups folder. This will remove all the backups you have set. Are you sure you want to do this?
                public static let message = Strings.tr("Localizable", "dialog.delete.root.backup.folder.warning.message")
              }
            }
          }
        }
      }
      public enum Disable {
        public enum Backup {
          /// disable backup
          public static let placeholder = Strings.tr("Localizable", "dialog.disable.backup.placeholder")
        }
      }
      public enum InviteContact {
        /// The user [X] has been invited and will appear in your contact list once accepted.
        public static let outgoingContactRequest = Strings.tr("Localizable", "dialog.inviteContact.outgoingContactRequest")
      }
      public enum Move {
        public enum Backup {
          /// move backup
          public static let placeholder = Strings.tr("Localizable", "dialog.move.backup.placeholder")
        }
      }
      public enum Root {
        public enum Backup {
          public enum Folder {
            public enum Location {
              public enum Warning {
                /// You are changing a default backup folder location. This may affect your ability to find your backup folder in the future. Please remember where it is located so that you can find it in the future.
                public static let message = Strings.tr("Localizable", "dialog.root.backup.folder.location.warning.message")
              }
            }
          }
        }
      }
      public enum Share {
        public enum Backup {
          public enum Non {
            public enum Backup {
              public enum Folders {
                public enum Warning {
                  /// Some folders shared are backup folders and read-only. Do you wish to continue?
                  public static let message = Strings.tr("Localizable", "dialog.share.backup.non.backup.folders.warning.message")
                }
              }
            }
          }
        }
      }
      public enum ShareOwnerStorageQuota {
        /// The file cannot be sent as the target user is over their storage quota.
        public static let message = Strings.tr("Localizable", "dialog.shareOwnerStorageQuota.message")
      }
      public enum Storage {
        public enum AlmostFull {
          /// Your Cloud drive is almost full. Upgrade now to a Pro account and get up to %@ TB (%@ GB) of cloud storage space.
          public static func detail(_ p1: Any, _ p2: Any) -> String {
            return Strings.tr("Localizable", "dialog.storage.almostFull.detail", String(describing: p1), String(describing: p2))
          }
        }
        public enum Odq {
          /// Your Cloud storage is full. Please upgrade to a MEGA Pro plan to increase your storage space and enjoy additional benefits. If you remain over your storage limit and do not upgrade or delete some data your account may get locked. Please see the emails we sent you for more information.
          public static let detail = Strings.tr("Localizable", "dialog.storage.odq.detail")
          /// Please Upgrade
          public static let title = Strings.tr("Localizable", "dialog.storage.odq.title")
        }
        public enum Paywall {
          public enum Final {
            /// <paragraph>Unfortunately you have not upgraded your account yet. If you do not upgrade now, your data will be deleted tomorrow. See your email for more information on what you need to do.</paragraph>
            public static let detail = Strings.tr("Localizable", "dialog.storage.paywall.final.detail")
            /// Your Data is at Risk!
            public static let title = Strings.tr("Localizable", "dialog.storage.paywall.final.title")
            /// <body><warn>Please upgrade today if you wish to keep your data.</warn><body>
            public static let warning = Strings.tr("Localizable", "dialog.storage.paywall.final.warning")
          }
          public enum NotFinal {
            /// <paragraph>Unfortunately you have not taken action in the <b>%@</b> since our emails were sent to <b>%@</b>, on <b>%@</b>. You are still using <b>%@</b> storage, which is over your free limit. Please see the emails we have sent you for more information on what you need to do.</paragraph>
            public static func detail(_ p1: Any, _ p2: Any, _ p3: Any, _ p4: Any) -> String {
              return Strings.tr("Localizable", "dialog.storage.paywall.notFinal.detail", String(describing: p1), String(describing: p2), String(describing: p3), String(describing: p4))
            }
            /// Account Locked
            public static let title = Strings.tr("Localizable", "dialog.storage.paywall.notFinal.title")
            /// <body>Please upgrade within <warn>%@</warn> to avoid your data getting deleted.</body>
            public static func warning(_ p1: Any) -> String {
              return Strings.tr("Localizable", "dialog.storage.paywall.notFinal.warning", String(describing: p1))
            }
          }
        }
      }
      public enum TurnOnNotifications {
        public enum Button {
          /// Open Settings
          public static let primary = Strings.tr("Localizable", "dialog.turnOnNotifications.button.primary")
        }
        public enum Label {
          /// This way, you will see new messages on your device instantly.
          public static let description = Strings.tr("Localizable", "dialog.turnOnNotifications.label.description")
          /// <b>1.</b> Open <b>Settings</b>
          public static let stepOne = Strings.tr("Localizable", "dialog.turnOnNotifications.label.stepOne")
          /// <b>3.</b> Turn on <b>Allow Notifications</b>
          public static let stepThree = Strings.tr("Localizable", "dialog.turnOnNotifications.label.stepThree")
          /// <b>2.</b> Tap <b>Notifications</b>
          public static let stepTwo = Strings.tr("Localizable", "dialog.turnOnNotifications.label.stepTwo")
          /// Turn on Notifications
          public static let title = Strings.tr("Localizable", "dialog.turnOnNotifications.label.title")
        }
      }
    }
    public enum Dnd {
      public enum Duration {
        /// Plural format key: "%#@hour@"
        public static func hour(_ p1: Int) -> String {
          return Strings.tr("Localizable", "dnd.duration.hour", p1)
        }
        /// Plural format key: "%#@minute@"
        public static func minute(_ p1: Int) -> String {
          return Strings.tr("Localizable", "dnd.duration.minute", p1)
        }
      }
    }
    public enum Extensions {
      public enum OpenApp {
        /// Open the MEGA app and log in to continue.
        public static let message = Strings.tr("Localizable", "extensions.OpenApp.Message")
      }
      public enum Share {
        public enum Destination {
          public enum Section {
            /// Plural format key: "%#@file@"
            public static func files(_ p1: Int) -> String {
              return Strings.tr("Localizable", "extensions.share.destination.section.files", p1)
            }
          }
        }
      }
    }
    public enum General {
      /// Select
      public static let choose = Strings.tr("Localizable", "general.choose")
      /// Cookie Policy
      public static let cookiePolicy = Strings.tr("Localizable", "general.cookiePolicy")
      /// Cookie Settings
      public static let cookieSettings = Strings.tr("Localizable", "general.cookieSettings")
      /// Make available offline
      public static let downloadToOffline = Strings.tr("Localizable", "general.downloadToOffline")
      /// Export
      public static let export = Strings.tr("Localizable", "general.export")
      /// Join meeting as guest
      public static let joinMeetingAsGuest = Strings.tr("Localizable", "general.joinMeetingAsGuest")
      /// Unable to connect to the Internet. Please check your connection and try again.
      public static let noIntenerConnection = Strings.tr("Localizable", "general.NoIntenerConnection")
      /// Send to Chat
      public static let sendToChat = Strings.tr("Localizable", "general.sendToChat")
      /// Share
      public static let share = Strings.tr("Localizable", "general.share")
      public enum Button {
        /// Get Bonus
        public static let getBonus = Strings.tr("Localizable", "general.button.getBonus")
      }
      public enum ChooseLabel {
        /// Label…
        public static let title = Strings.tr("Localizable", "general.chooseLabel.title")
      }
      public enum Error {
        /// The following characters are not allowed: %@
        public static func charactersNotAllowed(_ p1: Any) -> String {
          return Strings.tr("Localizable", "general.error.charactersNotAllowed", String(describing: p1))
        }
      }
      public enum Filetype {
        /// 3D Model
        public static let _3DModel = Strings.tr("Localizable", "general.filetype.3DModel")
        /// 3D Scene
        public static let _3ds = Strings.tr("Localizable", "general.filetype.3ds")
        /// Multimedia
        public static let _3g2 = Strings.tr("Localizable", "general.filetype.3g2")
        /// 7-Zip Compressed
        public static let _7z = Strings.tr("Localizable", "general.filetype.7z")
        /// ANSI Text File
        public static let ans = Strings.tr("Localizable", "general.filetype.ans")
        /// Android App
        public static let apk = Strings.tr("Localizable", "general.filetype.apk")
        /// Mac OS X App
        public static let app = Strings.tr("Localizable", "general.filetype.app")
        /// ASCII Text
        public static let ascii = Strings.tr("Localizable", "general.filetype.ascii")
        /// Streaming Video
        public static let asf = Strings.tr("Localizable", "general.filetype.asf")
        /// Advanced Stream
        public static let asx = Strings.tr("Localizable", "general.filetype.asx")
        /// Audio Interchange
        public static let audioInterchange = Strings.tr("Localizable", "general.filetype.audioInterchange")
        /// A/V Interleave
        public static let avi = Strings.tr("Localizable", "general.filetype.avi")
        /// DOS Batch
        public static let bat = Strings.tr("Localizable", "general.filetype.bat")
        /// Casio RAW Image
        public static let bay = Strings.tr("Localizable", "general.filetype.bay")
        /// Bitmap Image
        public static let bmp = Strings.tr("Localizable", "general.filetype.bmp")
        /// UNIX Compressed
        public static let bz2 = Strings.tr("Localizable", "general.filetype.bz2")
        /// C/C++ Source Code
        public static let c = Strings.tr("Localizable", "general.filetype.c")
        /// CorelDRAW Image
        public static let cdr = Strings.tr("Localizable", "general.filetype.cdr")
        /// CGI Script
        public static let cgi = Strings.tr("Localizable", "general.filetype.cgi")
        /// Java Class
        public static let `class` = Strings.tr("Localizable", "general.filetype.class")
        /// DOS Command
        public static let com = Strings.tr("Localizable", "general.filetype.com")
        /// Compressed
        public static let compressed = Strings.tr("Localizable", "general.filetype.compressed")
        /// C++ Source Code
        public static let cpp = Strings.tr("Localizable", "general.filetype.cpp")
        /// CSS Style Sheet
        public static let css = Strings.tr("Localizable", "general.filetype.css")
        /// Database
        public static let database = Strings.tr("Localizable", "general.filetype.database")
        /// Dynamic HTML
        public static let dhtml = Strings.tr("Localizable", "general.filetype.dhtml")
        /// Dynamic Link Library
        public static let dll = Strings.tr("Localizable", "general.filetype.dll")
        /// DXF Image
        public static let dxf = Strings.tr("Localizable", "general.filetype.dxf")
        /// EPS Image
        public static let eps = Strings.tr("Localizable", "general.filetype.eps")
        /// Executable
        public static let exe = Strings.tr("Localizable", "general.filetype.exe")
        /// Lossless Audio
        public static let flac = Strings.tr("Localizable", "general.filetype.flac")
        /// Flash Video
        public static let flv = Strings.tr("Localizable", "general.filetype.flv")
        /// Windows Font
        public static let fnt = Strings.tr("Localizable", "general.filetype.fnt")
        /// Font
        public static let fon = Strings.tr("Localizable", "general.filetype.fon")
        /// Windows Gadget
        public static let gadget = Strings.tr("Localizable", "general.filetype.gadget")
        /// GIF Image
        public static let gif = Strings.tr("Localizable", "general.filetype.gif")
        /// GPS Exchange
        public static let gpx = Strings.tr("Localizable", "general.filetype.gpx")
        /// GNU Compressed
        public static let gz = Strings.tr("Localizable", "general.filetype.gz")
        /// Header
        public static let header = Strings.tr("Localizable", "general.filetype.header")
        /// HTML Document
        public static let htmlDocument = Strings.tr("Localizable", "general.filetype.htmlDocument")
        /// Interchange File Format
        public static let iff = Strings.tr("Localizable", "general.filetype.iff")
        /// ISO Image
        public static let iso = Strings.tr("Localizable", "general.filetype.iso")
        /// Java Archive
        public static let jar = Strings.tr("Localizable", "general.filetype.jar")
        /// Java Code
        public static let java = Strings.tr("Localizable", "general.filetype.java")
        /// JPEG Image
        public static let jpeg = Strings.tr("Localizable", "general.filetype.jpeg")
        /// Log
        public static let log = Strings.tr("Localizable", "general.filetype.log")
        /// Media Playlist
        public static let m3u = Strings.tr("Localizable", "general.filetype.m3u")
        /// MPEG-4 Audio
        public static let m4a = Strings.tr("Localizable", "general.filetype.m4a")
        /// 3ds Max Scene
        public static let max = Strings.tr("Localizable", "general.filetype.max")
        /// MS Access
        public static let mdb = Strings.tr("Localizable", "general.filetype.mdb")
        /// MIDI Audio
        public static let mid = Strings.tr("Localizable", "general.filetype.mid")
        /// MKV Video
        public static let mkv = Strings.tr("Localizable", "general.filetype.mkv")
        /// QuickTime Movie
        public static let mov = Strings.tr("Localizable", "general.filetype.mov")
        /// MP3 Audio
        public static let mp3 = Strings.tr("Localizable", "general.filetype.mp3")
        /// MP4 Video
        public static let mp4 = Strings.tr("Localizable", "general.filetype.mp4")
        /// MPEG Movie
        public static let mpeg = Strings.tr("Localizable", "general.filetype.mpeg")
        /// MS Installer
        public static let msi = Strings.tr("Localizable", "general.filetype.msi")
        /// OpenType Font
        public static let otf = Strings.tr("Localizable", "general.filetype.otf")
        /// Pages
        public static let pages = Strings.tr("Localizable", "general.filetype.pages")
        /// PDF Document
        public static let pdf = Strings.tr("Localizable", "general.filetype.pdf")
        /// PHP Code
        public static let php = Strings.tr("Localizable", "general.filetype.php")
        /// Perl Script
        public static let pl = Strings.tr("Localizable", "general.filetype.pl")
        /// Audio Playlist
        public static let pls = Strings.tr("Localizable", "general.filetype.pls")
        /// PNG Image
        public static let png = Strings.tr("Localizable", "general.filetype.png")
        /// Podcast
        public static let podcast = Strings.tr("Localizable", "general.filetype.podcast")
        /// Python Script
        public static let py = Strings.tr("Localizable", "general.filetype.py")
        /// RAR Compressed
        public static let rar = Strings.tr("Localizable", "general.filetype.rar")
        /// RAW Image
        public static let rawImage = Strings.tr("Localizable", "general.filetype.rawImage")
        /// Rich Text
        public static let rtf = Strings.tr("Localizable", "general.filetype.rtf")
        /// Panasonic RAW Image
        public static let rw2 = Strings.tr("Localizable", "general.filetype.rw2")
        /// Bash Shell
        public static let sh = Strings.tr("Localizable", "general.filetype.sh")
        /// Server HTML
        public static let shtml = Strings.tr("Localizable", "general.filetype.shtml")
        /// X Compressed
        public static let sitx = Strings.tr("Localizable", "general.filetype.sitx")
        /// Spreadsheet
        public static let spreadsheet = Strings.tr("Localizable", "general.filetype.spreadsheet")
        /// SQL Database
        public static let sql = Strings.tr("Localizable", "general.filetype.sql")
        /// Sony RAW Image
        public static let srf = Strings.tr("Localizable", "general.filetype.srf")
        /// Subtitle
        public static let subtitle = Strings.tr("Localizable", "general.filetype.subtitle")
        /// Flash Movie
        public static let swf = Strings.tr("Localizable", "general.filetype.swf")
        /// Archive
        public static let tar = Strings.tr("Localizable", "general.filetype.tar")
        /// Text Document
        public static let textDocument = Strings.tr("Localizable", "general.filetype.textDocument")
        /// Targa Graphic
        public static let tga = Strings.tr("Localizable", "general.filetype.tga")
        /// TIF Image
        public static let tif = Strings.tr("Localizable", "general.filetype.tif")
        /// TIFF Image
        public static let tiff = Strings.tr("Localizable", "general.filetype.tiff")
        /// TrueType Font
        public static let ttf = Strings.tr("Localizable", "general.filetype.ttf")
        /// Vector Image
        public static let vectorImage = Strings.tr("Localizable", "general.filetype.vectorImage")
        /// Wave Audio
        public static let wav = Strings.tr("Localizable", "general.filetype.wav")
        /// WebM Video
        public static let webm = Strings.tr("Localizable", "general.filetype.webm")
        /// WM Audio
        public static let wma = Strings.tr("Localizable", "general.filetype.wma")
        /// WM Video
        public static let wmv = Strings.tr("Localizable", "general.filetype.wmv")
        /// MS Word Template
        public static let wordTemplate = Strings.tr("Localizable", "general.filetype.wordTemplate")
        /// XML Document
        public static let xml = Strings.tr("Localizable", "general.filetype.xml")
        /// ZIP Archive
        public static let zip = Strings.tr("Localizable", "general.filetype.zip")
      }
      public enum Format {
        public enum Count {
          /// Plural format key: "%#@file@"
          public static func file(_ p1: Int) -> String {
            return Strings.tr("Localizable", "general.format.count.file", p1)
          }
          /// Plural format key: "%#@folder@"
          public static func folder(_ p1: Int) -> String {
            return Strings.tr("Localizable", "general.format.count.folder", p1)
          }
          public enum FolderAndFile {
            /// Plural format key: "%#@file@"
            public static func file(_ p1: Int) -> String {
              return Strings.tr("Localizable", "general.format.count.folderAndFile.file", p1)
            }
            /// Plural format key: "%#@folder@"
            public static func folder(_ p1: Int) -> String {
              return Strings.tr("Localizable", "general.format.count.folderAndFile.folder", p1)
            }
          }
        }
        public enum RetentionPeriod {
          /// Plural format key: "%#@day@"
          public static func day(_ p1: Int) -> String {
            return Strings.tr("Localizable", "general.format.retentionPeriod.day", p1)
          }
          /// Plural format key: "%#@hour@"
          public static func hour(_ p1: Int) -> String {
            return Strings.tr("Localizable", "general.format.retentionPeriod.hour", p1)
          }
          /// Plural format key: "%#@month@"
          public static func month(_ p1: Int) -> String {
            return Strings.tr("Localizable", "general.format.retentionPeriod.month", p1)
          }
          /// Plural format key: "%#@week@"
          public static func week(_ p1: Int) -> String {
            return Strings.tr("Localizable", "general.format.retentionPeriod.week", p1)
          }
          /// Plural format key: "%#@year@"
          public static func year(_ p1: Int) -> String {
            return Strings.tr("Localizable", "general.format.retentionPeriod.year", p1)
          }
        }
        public enum RubbishBin {
          /// Plural format key: "%#@days@"
          public static func days(_ p1: Int) -> String {
            return Strings.tr("Localizable", "general.format.rubbishBin.days", p1)
          }
        }
      }
      public enum MenuAction {
        /// Delete permanently
        public static let deletePermanently = Strings.tr("Localizable", "general.menuAction.deletePermanently")
        /// Move to rubbish bin
        public static let moveToRubbishBin = Strings.tr("Localizable", "general.menuAction.moveToRubbishBin")
        public enum ExportFile {
          /// Plural format key: "%#@file@"
          public static func title(_ p1: Int) -> String {
            return Strings.tr("Localizable", "general.menuAction.exportFile.title", p1)
          }
        }
        public enum ManageLink {
          /// Plural format key: "%#@link@"
          public static func title(_ p1: Int) -> String {
            return Strings.tr("Localizable", "general.menuAction.manageLink.title", p1)
          }
        }
        public enum RemoveLink {
          /// Plural format key: "%#@link@"
          public static func title(_ p1: Int) -> String {
            return Strings.tr("Localizable", "general.menuAction.removeLink.title", p1)
          }
          public enum Message {
            /// Plural format key: "%#@link@"
            public static func success(_ p1: Int) -> String {
              return Strings.tr("Localizable", "general.menuAction.removeLink.message.success", p1)
            }
          }
        }
        public enum ShareFolder {
          /// Plural format key: "%#@folder@"
          public static func title(_ p1: Int) -> String {
            return Strings.tr("Localizable", "general.menuAction.shareFolder.title", p1)
          }
        }
        public enum ShareLink {
          /// Plural format key: "%#@link@"
          public static func title(_ p1: Int) -> String {
            return Strings.tr("Localizable", "general.menuAction.shareLink.title", p1)
          }
        }
        public enum VerifyContact {
          /// Verify %@
          public static func title(_ p1: Any) -> String {
            return Strings.tr("Localizable", "general.menuAction.verifyContact.title", String(describing: p1))
          }
        }
      }
      public enum Security {
        /// MEGA-RECOVERYKEY
        public static let recoveryKeyFile = Strings.tr("Localizable", "general.security.recoveryKeyFile")
      }
      public enum TextEditor {
        public enum Hud {
          /// File is too large and cannot be edited.
          public static let uneditableLargeFile = Strings.tr("Localizable", "general.textEditor.hud.uneditableLargeFile")
          /// File could not be edited due to unknown content encoding.
          public static let unknownEncode = Strings.tr("Localizable", "general.textEditor.hud.unknownEncode")
        }
      }
    }
    public enum Help {
      public enum ReportIssue {
        /// Please clearly describe the issue you encountered. The more details you provide, the easier it will be for us to resolve. Your submission will be reviewed by our development team.
        public static let describe = Strings.tr("Localizable", "help.reportIssue.describe")
        /// Discard Report
        public static let discardReport = Strings.tr("Localizable", "help.reportIssue.discardReport")
        /// Send Log File
        public static let sendLogFile = Strings.tr("Localizable", "help.reportIssue.sendLogFile")
        /// Report Issue
        public static let title = Strings.tr("Localizable", "help.reportIssue.title")
        /// Uploading Log File
        public static let uploadingLogFile = Strings.tr("Localizable", "help.reportIssue.uploadingLogFile")
        public enum AttachLogFiles {
          /// Do you want to attach diagnostic log files to assist with debug?
          public static let message = Strings.tr("Localizable", "help.reportIssue.attachLogFiles.message")
          /// Attach log files
          public static let title = Strings.tr("Localizable", "help.reportIssue.attachLogFiles.title")
        }
        public enum Creating {
          public enum Cancel {
            /// This issue will not be reported if you cancel uploading it.
            public static let message = Strings.tr("Localizable", "help.reportIssue.creating.cancel.message")
            /// Are you sure you want to cancel uploading your reported issue?
            public static let title = Strings.tr("Localizable", "help.reportIssue.creating.cancel.title")
          }
        }
        public enum DescribeIssue {
          /// Describe the issue
          public static let placeholder = Strings.tr("Localizable", "help.reportIssue.describeIssue.placeholder")
        }
        public enum Fail {
          /// Unable to submit your report. Please try again.
          public static let message = Strings.tr("Localizable", "help.reportIssue.fail.message")
        }
        public enum Success {
          /// Thanks. We’ll look into this issue and a member of our team will get back to you.
          public static let message = Strings.tr("Localizable", "help.reportIssue.success.message")
          /// Thanks for your feedback
          public static let title = Strings.tr("Localizable", "help.reportIssue.success.title")
        }
      }
    }
    public enum Home {
      public enum Favourites {
        /// Favourites
        public static let title = Strings.tr("Localizable", "home.favourites.title")
      }
      public enum Images {
        /// No Images Found
        public static let empty = Strings.tr("Localizable", "home.images.empty")
        /// Images
        public static let title = Strings.tr("Localizable", "home.images.title")
      }
      public enum Recent {
        /// Created by %@
        public static func createdByLabel(_ p1: Any) -> String {
          return Strings.tr("Localizable", "home.recent.createdByLabel", String(describing: p1))
        }
        /// Modified by %@
        public static func modifiedByLabel(_ p1: Any) -> String {
          return Strings.tr("Localizable", "home.recent.modifiedByLabel", String(describing: p1))
        }
      }
    }
    public enum InAppPurchase {
      public enum Error {
        public enum Alert {
          /// App Store Settings
          public static let primaryButtonTitle = Strings.tr("Localizable", "inAppPurchase.error.alert.primaryButtonTitle")
          public enum Title {
            /// This In-App Purchase item is not available in the App Store at this time. Please verify payment settings for your Apple ID.
            public static let notAvailable = Strings.tr("Localizable", "inAppPurchase.error.alert.title.notAvailable")
          }
        }
      }
      public enum ProductDetail {
        public enum Navigation {
          /// Current plan
          public static let currentPlan = Strings.tr("Localizable", "inAppPurchase.productDetail.navigation.currentPlan")
        }
      }
      public enum Upgrade {
        public enum Label {
          /// Current Plan:
          public static let currentPlan = Strings.tr("Localizable", "inAppPurchase.upgrade.label.currentPlan")
        }
      }
    }
    public enum Invite {
      public enum ContactLink {
        public enum Share {
          /// Send invitation
          public static let title = Strings.tr("Localizable", "invite.contactLink.share.title")
        }
      }
    }
    public enum Media {
      public enum Audio {
        public enum Playlist {
          public enum Section {
            public enum Next {
              /// Next
              public static let title = Strings.tr("Localizable", "media.audio.playlist.section.next.title")
            }
          }
        }
      }
      public enum Photo {
        public enum Browser {
          /// Plural format key: "%#@total@"
          public static func indexOfTotalFiles(_ p1: Int) -> String {
            return Strings.tr("Localizable", "media.photo.browser.indexOfTotalFiles", p1)
          }
        }
      }
      public enum PhotoLibrary {
        public enum Category {
          public enum All {
            /// All
            public static let title = Strings.tr("Localizable", "media.photoLibrary.category.all.title")
          }
          public enum Days {
            /// Days
            public static let title = Strings.tr("Localizable", "media.photoLibrary.category.days.title")
          }
          public enum Months {
            /// Months
            public static let title = Strings.tr("Localizable", "media.photoLibrary.category.months.title")
          }
          public enum Years {
            /// Years
            public static let title = Strings.tr("Localizable", "media.photoLibrary.category.years.title")
          }
        }
      }
      public enum Quality {
        /// Automatic
        public static let automatic = Strings.tr("Localizable", "media.quality.automatic")
        /// Best
        public static let best = Strings.tr("Localizable", "media.quality.best")
        /// High
        public static let high = Strings.tr("Localizable", "media.quality.high")
        /// Low
        public static let low = Strings.tr("Localizable", "media.quality.low")
        /// Medium
        public static let medium = Strings.tr("Localizable", "media.quality.medium")
        /// Optimised
        public static let optimised = Strings.tr("Localizable", "media.quality.optimised")
        /// Original
        public static let original = Strings.tr("Localizable", "media.quality.original")
      }
    }
    public enum Meetings {
      /// Bad connection
      public static let poorConnection = Strings.tr("Localizable", "meetings.poorConnection")
      public enum Action {
        /// Rename Meeting
        public static let rename = Strings.tr("Localizable", "meetings.action.rename")
        /// Share Meeting Link
        public static let shareLink = Strings.tr("Localizable", "meetings.action.shareLink")
      }
      public enum AddContacts {
        public enum AllContactsAdded {
          /// Invite
          public static let confirmationButtonTitle = Strings.tr("Localizable", "meetings.addContacts.allContactsAdded.confirmationButtonTitle")
          /// You’ve already added all your contacts to this chat.
          /// If you want to add more participants, first invite them to your contact list.
          public static let description = Strings.tr("Localizable", "meetings.addContacts.allContactsAdded.description")
          /// All contacts added
          public static let title = Strings.tr("Localizable", "meetings.addContacts.allContactsAdded.title")
        }
        public enum AllowNonHost {
          /// Allow non-hosts to add participants
          public static let message = Strings.tr("Localizable", "meetings.addContacts.allowNonHost.message")
        }
        public enum ZeroContactsAvailable {
          /// You have no contacts to add to this chat. If you want to add participants, first invite them to your contact list.
          public static let description = Strings.tr("Localizable", "meetings.addContacts.zeroContactsAvailable.description")
          /// No contacts
          public static let title = Strings.tr("Localizable", "meetings.addContacts.zeroContactsAvailable.title")
        }
      }
      public enum Alert {
        /// Meeting Ended
        public static let end = Strings.tr("Localizable", "meetings.alert.end")
        /// View Meeting Chat
        public static let meetingchat = Strings.tr("Localizable", "meetings.alert.meetingchat")
        public enum End {
          /// The meeting you’re trying to join has already ended. You can still view the meeting chat history.
          public static let description = Strings.tr("Localizable", "meetings.alert.end.description")
        }
      }
      public enum Create {
        /// New Meeting
        public static let newMeeting = Strings.tr("Localizable", "meetings.create.newMeeting")
      }
      public enum CreateMeeting {
        /// %@ Meeting
        public static func defaultMeetingName(_ p1: Any) -> String {
          return Strings.tr("Localizable", "meetings.createMeeting.defaultMeetingName", String(describing: p1))
        }
        /// Start meeting
        public static let startMeeting = Strings.tr("Localizable", "meetings.createMeeting.startMeeting")
      }
      public enum DisplayInMainView {
        /// Display in Main View
        public static let title = Strings.tr("Localizable", "meetings.displayInMainView.title")
      }
      public enum EndCall {
        /// End call for all
        public static let endForAllButtonTitle = Strings.tr("Localizable", "meetings.endCall.endForAllButtonTitle")
        public enum EndForAllAlert {
          /// No
          public static let cancel = Strings.tr("Localizable", "meetings.endCall.endForAllAlert.cancel")
          /// Yes
          public static let confirm = Strings.tr("Localizable", "meetings.endCall.endForAllAlert.confirm")
          /// This will end the call for all participants.
          public static let description = Strings.tr("Localizable", "meetings.endCall.endForAllAlert.description")
          /// End call for all?
          public static let title = Strings.tr("Localizable", "meetings.endCall.endForAllAlert.title")
        }
      }
      public enum EndCallDialog {
        /// Call will automatically end in 2 mins unless you want to stay on it.
        public static let description = Strings.tr("Localizable", "meetings.endCallDialog.description")
        /// End call now
        public static let endCallNowButtonTitle = Strings.tr("Localizable", "meetings.endCallDialog.endCallNowButtonTitle")
        /// Stay on call
        public static let stayOnCallButtonTitle = Strings.tr("Localizable", "meetings.endCallDialog.stayOnCallButtonTitle")
        /// You’re the only one here
        public static let title = Strings.tr("Localizable", "meetings.endCallDialog.title")
      }
      public enum EndForAll {
        /// End for all
        public static let buttonTitle = Strings.tr("Localizable", "meetings.endForAll.buttonTitle")
      }
      public enum EnterMeetingLink {
        /// Enter Meeting Link
        public static let title = Strings.tr("Localizable", "meetings.enterMeetingLink.title")
      }
      public enum Incompatibility {
        /// We are upgrading MEGA Chat. Your calls might not be connected due to version incompatibility unless all parties update their MEGA Apps to the latest version.
        public static let warningMessage = Strings.tr("Localizable", "meetings.incompatibility.warningMessage")
      }
      public enum Info {
        /// Chat notifications
        public static let chatNotifications = Strings.tr("Localizable", "meetings.info.chatNotifications")
        /// Leave meeting
        public static let leaveMeeting = Strings.tr("Localizable", "meetings.info.leaveMeeting")
        /// Manage chat history
        public static let manageChatHistory = Strings.tr("Localizable", "meetings.info.manageChatHistory")
        /// Meeting link
        public static let meetingLink = Strings.tr("Localizable", "meetings.info.meetingLink")
        /// Share chat link
        public static let shareChatLink = Strings.tr("Localizable", "meetings.info.shareChatLink")
        /// Shared files
        public static let sharedFiles = Strings.tr("Localizable", "meetings.info.sharedFiles")
        public enum KeyRotation {
          /// Key rotation is slightly more secure, but doesn't allow you to create a chat link and hides past messages from new participants.
          public static let description = Strings.tr("Localizable", "meetings.info.keyRotation.description")
          /// Enable encryption key rotation
          public static let title = Strings.tr("Localizable", "meetings.info.keyRotation.title")
        }
        public enum Participants {
          /// See all
          public static let seeAll = Strings.tr("Localizable", "meetings.info.participants.seeAll")
          /// See less
          public static let seeLess = Strings.tr("Localizable", "meetings.info.participants.seeLess")
          /// See more
          public static let seeMore = Strings.tr("Localizable", "meetings.info.participants.seeMore")
        }
        public enum ShareOptions {
          /// Send to chat
          public static let sendToChat = Strings.tr("Localizable", "meetings.info.shareOptions.sendToChat")
          /// Anyone with this link can join the meeting and view the meeting chat.
          public static let title = Strings.tr("Localizable", "meetings.info.shareOptions.title")
          public enum ShareLink {
            /// Copied link to clipboard
            public static let linkCopied = Strings.tr("Localizable", "meetings.info.shareOptions.shareLink.linkCopied")
          }
        }
      }
      public enum JoinMeeting {
        /// Unable to join the meeting. Please check the link is valid.
        public static let description = Strings.tr("Localizable", "meetings.joinMeeting.description")
        /// Invalid Meeting URL
        public static let header = Strings.tr("Localizable", "meetings.joinMeeting.header")
      }
      public enum JoinMega {
        /// Join MEGA
        public static let title = Strings.tr("Localizable", "meetings.joinMega.title")
        public enum Paragraph1 {
          /// Join the largest secure cloud storage and collaboration platform in the world.
          public static let description = Strings.tr("Localizable", "meetings.joinMega.paragraph1.description")
          /// Your privacy matters
          public static let title = Strings.tr("Localizable", "meetings.joinMega.paragraph1.title")
        }
        public enum Paragraph2 {
          /// Sign up now and enjoy advanced collaboration features for free.
          public static let description = Strings.tr("Localizable", "meetings.joinMega.paragraph2.description")
          /// Get 20 GB for free
          public static let title = Strings.tr("Localizable", "meetings.joinMega.paragraph2.title")
        }
      }
      public enum LeaveCall {
        /// Leave
        public static let buttonTitle = Strings.tr("Localizable", "meetings.leaveCall.buttonTitle")
      }
      public enum Link {
        public enum Guest {
          /// Join as guest
          public static let joinButtonText = Strings.tr("Localizable", "meetings.link.guest.joinButtonText")
        }
        public enum LoggedInUser {
          /// Join meeting
          public static let joinButtonText = Strings.tr("Localizable", "meetings.link.loggedInUser.joinButtonText")
        }
      }
      public enum Message {
        /// %@ joined the call
        public static func joinedCall(_ p1: Any) -> String {
          return Strings.tr("Localizable", "meetings.message.joinedCall", String(describing: p1))
        }
        /// %@ left the call
        public static func leftCall(_ p1: Any) -> String {
          return Strings.tr("Localizable", "meetings.message.leftCall", String(describing: p1))
        }
        /// You are the only one here…
        public static let noOtherParticipants = Strings.tr("Localizable", "meetings.message.noOtherParticipants")
        /// Waiting for others to join…
        public static let waitingOthers = Strings.tr("Localizable", "meetings.message.waitingOthers")
      }
      public enum New {
        /// Another call in progress. Please end your current call before making another.
        public static let anotherAlreadyExistsError = Strings.tr("Localizable", "meetings.new.anotherAlreadyExistsError")
        public enum AnotherAlreadyExistsError {
          /// End and join
          public static let endAndJoin = Strings.tr("Localizable", "meetings.new.anotherAlreadyExistsError.endAndJoin")
        }
      }
      public enum Notification {
        /// Call will end in %@
        public static func endCallTimerDuration(_ p1: Any) -> String {
          return Strings.tr("Localizable", "meetings.notification.EndCallTimerDuration", String(describing: p1))
        }
        /// %@ and %@ others joined
        public static func moreThanTwoUsersJoined(_ p1: Any, _ p2: Any) -> String {
          return Strings.tr("Localizable", "meetings.notification.moreThanTwoUsersJoined", String(describing: p1), String(describing: p2))
        }
        /// %@ and %@ others left
        public static func moreThanTwoUsersLeft(_ p1: Any, _ p2: Any) -> String {
          return Strings.tr("Localizable", "meetings.notification.moreThanTwoUsersLeft", String(describing: p1), String(describing: p2))
        }
        /// %@ joined
        public static func singleUserJoined(_ p1: Any) -> String {
          return Strings.tr("Localizable", "meetings.notification.singleUserJoined", String(describing: p1))
        }
        /// %@ left
        public static func singleUserLeft(_ p1: Any) -> String {
          return Strings.tr("Localizable", "meetings.notification.singleUserLeft", String(describing: p1))
        }
        /// %@ and %@ joined
        public static func twoUsersJoined(_ p1: Any, _ p2: Any) -> String {
          return Strings.tr("Localizable", "meetings.notification.twoUsersJoined", String(describing: p1), String(describing: p2))
        }
        /// %@ and %@ left
        public static func twoUsersLeft(_ p1: Any, _ p2: Any) -> String {
          return Strings.tr("Localizable", "meetings.notification.twoUsersLeft", String(describing: p1), String(describing: p2))
        }
      }
      public enum Notifications {
        /// You are the new host
        public static let moderatorPrivilege = Strings.tr("Localizable", "meetings.notifications.moderatorPrivilege")
      }
      public enum Panel {
        /// Invite Participants
        public static let inviteParticipants = Strings.tr("Localizable", "meetings.panel.InviteParticipants")
        /// Participants (%d)
        public static func participantsCount(_ p1: Int) -> String {
          return Strings.tr("Localizable", "meetings.panel.ParticipantsCount", p1)
        }
        /// Share Link
        public static let shareLink = Strings.tr("Localizable", "meetings.panel.shareLink")
      }
      public enum Participant {
        /// Make host
        public static let makeModerator = Strings.tr("Localizable", "meetings.participant.makeModerator")
        /// Host
        public static let moderator = Strings.tr("Localizable", "meetings.participant.moderator")
        /// Remove as host
        public static let removeModerator = Strings.tr("Localizable", "meetings.participant.removeModerator")
      }
      public enum QuickAction {
        /// Switch
        public static let flip = Strings.tr("Localizable", "meetings.quickAction.flip")
        /// Speaker
        public static let speaker = Strings.tr("Localizable", "meetings.quickAction.speaker")
      }
      public enum Reconnecting {
        /// Unable to reconnect
        public static let failed = Strings.tr("Localizable", "meetings.reconnecting.failed")
        /// Reconnecting
        public static let title = Strings.tr("Localizable", "meetings.reconnecting.title")
      }
      public enum Sharelink {
        /// Meeting link could not be generated. Please try again.
        public static let error = Strings.tr("Localizable", "meetings.sharelink.Error")
      }
      public enum StartConversation {
        public enum ContextMenu {
          /// Join meeting
          public static let joinMeeting = Strings.tr("Localizable", "meetings.startConversation.contextMenu.joinMeeting")
          /// Schedule meeting
          public static let scheduleMeeting = Strings.tr("Localizable", "meetings.startConversation.contextMenu.scheduleMeeting")
          /// Start meeting now
          public static let startMeeting = Strings.tr("Localizable", "meetings.startConversation.contextMenu.startMeeting")
        }
      }
    }
    public enum Mybackups {
      public enum Share {
        public enum Folder {
          public enum Warning {
            /// Plural format key: "%#@share@"
            public static func message(_ p1: Int) -> String {
              return Strings.tr("Localizable", "mybackups.share.folder.warning.message", p1)
            }
          }
        }
      }
    }
    public enum NameCollision {
      /// Plural format key: "%#@count@"
      public static func applyToAll(_ p1: Int) -> String {
        return Strings.tr("Localizable", "nameCollision.applyToAll", p1)
      }
      public enum Files {
        /// A file named %@ already exists at this destination.
        public static func alreadyExists(_ p1: Any) -> String {
          return Strings.tr("Localizable", "nameCollision.files.alreadyExists", String(describing: p1))
        }
        public enum Action {
          public enum Rename {
            /// The file will be renamed as:
            public static let description = Strings.tr("Localizable", "nameCollision.files.action.rename.description")
            /// Rename
            public static let title = Strings.tr("Localizable", "nameCollision.files.action.rename.title")
          }
          public enum Replace {
            /// The file at this destination will be replaced with the new file.
            public static let description = Strings.tr("Localizable", "nameCollision.files.action.replace.description")
            /// Replace
            public static let title = Strings.tr("Localizable", "nameCollision.files.action.replace.title")
          }
          public enum Skip {
            /// Skip this file
            public static let title = Strings.tr("Localizable", "nameCollision.files.action.skip.title")
          }
          public enum Update {
            /// The file will be updated with a new version.
            public static let description = Strings.tr("Localizable", "nameCollision.files.action.update.description")
            /// Update
            public static let title = Strings.tr("Localizable", "nameCollision.files.action.update.title")
          }
        }
      }
      public enum Folders {
        /// A folder named %@ already exists at this destination.
        public static func alreadyExists(_ p1: Any) -> String {
          return Strings.tr("Localizable", "nameCollision.folders.alreadyExists", String(describing: p1))
        }
        public enum Action {
          public enum Merge {
            /// The new folder will be merged with the folder at this destination.
            public static let description = Strings.tr("Localizable", "nameCollision.folders.action.merge.description")
            /// Merge
            public static let title = Strings.tr("Localizable", "nameCollision.folders.action.merge.title")
          }
          public enum Skip {
            /// Skip this folder
            public static let title = Strings.tr("Localizable", "nameCollision.folders.action.skip.title")
          }
        }
      }
      public enum Title {
        /// File already exists
        public static let file = Strings.tr("Localizable", "nameCollision.title.file")
        /// Folder already exists
        public static let folder = Strings.tr("Localizable", "nameCollision.title.folder")
      }
    }
    public enum Notifications {
      public enum Message {
        public enum TakenDownPubliclyShared {
          /// Your publicly shared file “%@” has been taken down.
          public static func file(_ p1: Any) -> String {
            return Strings.tr("Localizable", "notifications.message.takenDownPubliclyShared.file", String(describing: p1))
          }
          /// Your publicly shared folder “%@” has been taken down.
          public static func folder(_ p1: Any) -> String {
            return Strings.tr("Localizable", "notifications.message.takenDownPubliclyShared.folder", String(describing: p1))
          }
        }
        public enum TakenDownReinstated {
          /// Your taken-down file “%@” has been reinstated.
          public static func file(_ p1: Any) -> String {
            return Strings.tr("Localizable", "notifications.message.takenDownReinstated.file", String(describing: p1))
          }
          /// Your taken-down folder “%@” has been reinstated.
          public static func folder(_ p1: Any) -> String {
            return Strings.tr("Localizable", "notifications.message.takenDownReinstated.folder", String(describing: p1))
          }
        }
      }
    }
    public enum Offline {
      public enum LogOut {
        public enum Warning {
          /// Logging out deletes your offline content.
          public static let message = Strings.tr("Localizable", "offline.logOut.warning.message")
        }
      }
    }
    public enum Photo {
      public enum Empty {
        /// No Photos Found
        public static let title = Strings.tr("Localizable", "photo.empty.title")
      }
      public enum Navigation {
        /// Photos
        public static let title = Strings.tr("Localizable", "photo.navigation.title")
      }
    }
    public enum Recents {
      public enum EmptyState {
        public enum ActivityHidden {
          /// Show Activity
          public static let button = Strings.tr("Localizable", "recents.emptyState.activityHidden.button")
          /// Recent Activity Hidden
          public static let title = Strings.tr("Localizable", "recents.emptyState.activityHidden.title")
        }
      }
      public enum Section {
        public enum Thumbnail {
          public enum Count {
            /// Plural format key: "%#@image@"
            public static func image(_ p1: Int) -> String {
              return Strings.tr("Localizable", "recents.section.thumbnail.count.image", p1)
            }
            /// Plural format key: "%#@video@"
            public static func video(_ p1: Int) -> String {
              return Strings.tr("Localizable", "recents.section.thumbnail.count.video", p1)
            }
            public enum ImageAndVideo {
              /// Plural format key: "%#@image@"
              public static func image(_ p1: Int) -> String {
                return Strings.tr("Localizable", "recents.section.thumbnail.count.imageAndVideo.image", p1)
              }
              /// Plural format key: "%#@video@"
              public static func video(_ p1: Int) -> String {
                return Strings.tr("Localizable", "recents.section.thumbnail.count.imageAndVideo.video", p1)
              }
            }
          }
        }
      }
    }
    public enum Settings {
      public enum Cookies {
        /// Essential Cookies
        public static let essential = Strings.tr("Localizable", "settings.cookies.essential")
        /// Performance and Analytics Cookies
        public static let performanceAndAnalytics = Strings.tr("Localizable", "settings.cookies.performanceAndAnalytics")
        public enum Essential {
          /// Always On
          public static let alwaysOn = Strings.tr("Localizable", "settings.cookies.essential.alwaysOn")
          /// Essential for providing you important functionality and secure access to our services. For this reason, they do not require consent.
          public static let footer = Strings.tr("Localizable", "settings.cookies.essential.footer")
        }
        public enum PerformanceAndAnalytics {
          /// Help us to understand how you use our services and provide us data that we can use to make improvements. Not accepting these Cookies will mean we will have less data available to us to help design improvements.
          public static let footer = Strings.tr("Localizable", "settings.cookies.performanceAndAnalytics.footer")
        }
      }
      public enum FileManagement {
        public enum Alert {
          /// Clear all offline files?
          public static let clearAllOfflineFiles = Strings.tr("Localizable", "settings.fileManagement.alert.clearAllOfflineFiles")
        }
        public enum RubbishBin {
          /// For a longer retention period [S]Upgrade to Pro[/S]
          public static let longerRetentionUpgrade = Strings.tr("Localizable", "settings.fileManagement.rubbishBin.longerRetentionUpgrade")
        }
        public enum UseMobileData {
          /// Use mobile data to load high resolution images when previewing. If disabled, the high resolution image will only be loaded when you zoom in.
          public static let footer = Strings.tr("Localizable", "settings.fileManagement.useMobileData.footer")
          /// Preview high resolution images
          public static let header = Strings.tr("Localizable", "settings.fileManagement.useMobileData.header")
        }
      }
      public enum Section {
        /// Security
        public static let security = Strings.tr("Localizable", "settings.section.security")
        /// Terms and Policies
        public static let termsAndPolicies = Strings.tr("Localizable", "settings.section.termsAndPolicies")
        /// User Interface
        public static let userInterface = Strings.tr("Localizable", "settings.section.userInterface")
        public enum Calls {
          /// Calls
          public static let title = Strings.tr("Localizable", "settings.section.calls.title")
          public enum SoundNotifications {
            /// Hear a sound when someone joins or leaves a call.
            public static let description = Strings.tr("Localizable", "settings.section.calls.soundNotifications.description")
            /// Sound notifications
            public static let title = Strings.tr("Localizable", "settings.section.calls.soundNotifications.title")
          }
        }
      }
      public enum UserInterface {
        /// Hide Recent Activity
        public static let hideRecentActivity = Strings.tr("Localizable", "settings.userInterface.hideRecentActivity")
        public enum HideRecentActivity {
          /// Hide recent activity in Home section.
          public static let footer = Strings.tr("Localizable", "settings.userInterface.hideRecentActivity.footer")
        }
      }
    }
    public enum SharedItems {
      public enum ContactVerification {
        /// Contact verification
        public static let title = Strings.tr("Localizable", "sharedItems.contactVerification.title")
        public enum Section {
          public enum MyCredentials {
            /// To verify your contact, ensure the credentials you see above match their account credentials. You can ask them to share their credentials with you.
            public static let message = Strings.tr("Localizable", "sharedItems.contactVerification.section.myCredentials.message")
          }
          public enum VerifyContact {
            /// To access the shared folder, the person who shared it with you should verify you, too.
            public static let bannerMessage = Strings.tr("Localizable", "sharedItems.contactVerification.section.verifyContact.bannerMessage")
            public enum Owner {
              /// We protect your data with zero-knowledge encryption. To ensure extra security, we ask you to verify the contacts you share information with before they can access the shared folders.
              public static let message = Strings.tr("Localizable", "sharedItems.contactVerification.section.verifyContact.owner.message")
            }
            public enum Receiver {
              /// We protect your data with zero-knowledge encryption. To ensure extra security, we ask you to verify the contacts you receive information from before you can access the shared folders.
              public static let message = Strings.tr("Localizable", "sharedItems.contactVerification.section.verifyContact.receiver.message")
            }
          }
        }
      }
      public enum Menu {
        public enum Slideshow {
          /// Slideshow
          public static let title = Strings.tr("Localizable", "sharedItems.menu.slideshow.title")
        }
      }
      public enum Tab {
        public enum Incoming {
          /// [Undecrypted folder]
          public static let undecryptedFolderName = Strings.tr("Localizable", "sharedItems.tab.incoming.undecryptedFolderName")
        }
      }
    }
    public enum Slideshow {
      public enum PreferenceSetting {
        /// Include images from sub-folders in the slideshow
        public static let mediaInSubFolders = Strings.tr("Localizable", "slideshow.preferenceSetting.mediaInSubFolders")
        /// Options
        public static let options = Strings.tr("Localizable", "slideshow.preferenceSetting.options")
        /// Slideshow order
        public static let order = Strings.tr("Localizable", "slideshow.preferenceSetting.order")
        /// Slideshow options
        public static let slideshowOptions = Strings.tr("Localizable", "slideshow.preferenceSetting.slideshowOptions")
        /// Slideshow speed
        public static let speed = Strings.tr("Localizable", "slideshow.preferenceSetting.speed")
        public enum Order {
          /// Shuffle
          public static let shuffle = Strings.tr("Localizable", "slideshow.preferenceSetting.order.shuffle")
        }
        public enum SlideshowOptions {
          /// Repeat
          public static let `repeat` = Strings.tr("Localizable", "slideshow.preferenceSetting.slideshowOptions.repeat")
          /// Include sub-folders
          public static let subFolders = Strings.tr("Localizable", "slideshow.preferenceSetting.slideshowOptions.subFolders")
        }
        public enum Speed {
          /// Fast (2s)
          public static let fast = Strings.tr("Localizable", "slideshow.preferenceSetting.speed.fast")
          /// Normal (4s)
          public static let normal = Strings.tr("Localizable", "slideshow.preferenceSetting.speed.normal")
          /// Slow (8s)
          public static let slow = Strings.tr("Localizable", "slideshow.preferenceSetting.speed.slow")
        }
      }
    }
    public enum Transfer {
      public enum Cell {
        public enum ShareOwnerStorageQuota {
          /// Share owner is over storage quota.
          public static let infoLabel = Strings.tr("Localizable", "transfer.cell.shareOwnerStorageQuota.infoLabel")
        }
      }
      public enum Error {
        /// Violated Terms of Service
        public static let termsOfServiceViolation = Strings.tr("Localizable", "transfer.error.termsOfServiceViolation")
      }
      public enum Storage {
        /// Storage quota exceeded
        public static let quotaExceeded = Strings.tr("Localizable", "transfer.storage.quotaExceeded")
      }
    }
    public enum Transfers {
      public enum Cancellable {
        /// Cancel transfer
        public static let cancel = Strings.tr("Localizable", "transfers.cancellable.cancel")
        /// Cancelling transfers…
        public static let cancellingTransfers = Strings.tr("Localizable", "transfers.cancellable.cancellingTransfers")
        /// Interrupting the transfer process may render some of the items incomplete.
        public static let confirmCancel = Strings.tr("Localizable", "transfers.cancellable.confirmCancel")
        /// Creating folders…
        public static let creatingFolders = Strings.tr("Localizable", "transfers.cancellable.creatingFolders")
        /// No, continue
        public static let dismiss = Strings.tr("Localizable", "transfers.cancellable.dismiss")
        /// Don’t close the app. If you close, transfers not yet queued will be lost.
        public static let donotclose = Strings.tr("Localizable", "transfers.cancellable.donotclose")
        /// Yes, cancel
        public static let proceed = Strings.tr("Localizable", "transfers.cancellable.proceed")
        /// Scanning…
        public static let scanning = Strings.tr("Localizable", "transfers.cancellable.scanning")
        /// Cancel transfers?
        public static let title = Strings.tr("Localizable", "transfers.cancellable.title")
        /// Transferring…
        public static let transferring = Strings.tr("Localizable", "transfers.cancellable.transferring")
        /// Transfer cancelled
        public static let trasnferCancelled = Strings.tr("Localizable", "transfers.cancellable.trasnferCancelled")
        public enum CreatingFolders {
          /// %@/%@
          public static func count(_ p1: Any, _ p2: Any) -> String {
            return Strings.tr("Localizable", "transfers.cancellable.creatingFolders.count", String(describing: p1), String(describing: p2))
          }
        }
        public enum Scanning {
          /// Found %@ and %@
          public static func count(_ p1: Any, _ p2: Any) -> String {
            return Strings.tr("Localizable", "transfers.cancellable.scanning.count", String(describing: p1), String(describing: p2))
          }
        }
      }
    }
    public enum VerifyCredentials {
      public enum YourCredentials {
        /// Your credentials
        public static let title = Strings.tr("Localizable", "verifyCredentials.yourCredentials.title")
      }
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension Strings {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: nil, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
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
