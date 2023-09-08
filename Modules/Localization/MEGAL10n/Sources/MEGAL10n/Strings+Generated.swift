// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum Strings {
  public enum Localizable {
    /// Shows number of the current page. '%1' will be replaced by current page number. '%2' will be replaced by number of all pages.
    public static let _1Of2 = Strings.tr("Localizable", "%1 of %2", fallback: "%1 of %2")
    /// Management message shown in a chat when the user %@ creates a public link for the chat
    public static func createdAPublicLinkForTheChat(_ p1: Any) -> String {
      return Strings.tr("Localizable", "%@ created a public link for the chat.", String(describing: p1), fallback: "%@ created a chat link")
    }
    /// Management message shown in a chat when the user %@ enables the 'Encrypted Key Rotation'
    public static func enabledEncryptedKeyRotation(_ p1: Any) -> String {
      return Strings.tr("Localizable", "%@ enabled Encrypted Key Rotation", String(describing: p1), fallback: "%@ enabled encryption key rotation.")
    }
    /// Message to inform the local user that someone has joined the current group call
    public static func joinedTheCall(_ p1: Any) -> String {
      return Strings.tr("Localizable", "%@ joined the call.", String(describing: p1), fallback: "%@ joined the call.")
    }
    /// Management message shown in a chat when the user %@ joined it from a public chat link
    public static func joinedTheGroupChat(_ p1: Any) -> String {
      return Strings.tr("Localizable", "%@ joined the group chat.", String(describing: p1), fallback: "%@ joined the group chat.")
    }
    /// Message to inform the local user that someone has left the current group call
    public static func leftTheCall(_ p1: Any) -> String {
      return Strings.tr("Localizable", "%@ left the call.", String(describing: p1), fallback: "%@ left the call")
    }
    /// Management message shown in a chat when the user %@ removes a public link for the chat
    public static func removedAPublicLinkForTheChat(_ p1: Any) -> String {
      return Strings.tr("Localizable", "%@ removed a public link for the chat.", String(describing: p1), fallback: "%@ removed the chat link")
    }
    /// Over Disk Quota of number of days
    public static func dDays(_ p1: Int) -> String {
      return Strings.tr("Localizable", "%d days", p1, fallback: "%d days")
    }
    /// Singular of participant. 1 participant
    public static func dParticipant(_ p1: Int) -> String {
      return Strings.tr("Localizable", "%d participant", p1, fallback: "%d participant")
    }
    /// Plural of participant. 2 participants
    public static func dParticipants(_ p1: Int) -> String {
      return Strings.tr("Localizable", "%d participants", p1, fallback: "%d participants")
    }
    /// A hint to show one option is recommended by MEGA
    public static let recommended = Strings.tr("Localizable", "(Recommended)", fallback: "(Recommended)")
    /// String shown when multi selection is enabled and only one item has been selected.
    public static let _1Selected = Strings.tr("Localizable", "1 selected", fallback: "1 selected")
    /// Chat Notifications DND: Option that deactivates DND after 24 hours
    public static let _24Hours = Strings.tr("Localizable", "24 hours", fallback: "24 hours")
    /// Chat Notifications DND: Option that deactivates DND after 30 minutes
    public static let _30Minutes = Strings.tr("Localizable", "30 minutes", fallback: "30 minutes")
    /// Action text to change to 4-Digit Numeric passcode type.
    public static let _4DigitNumericCode = Strings.tr("Localizable", "4-Digit Numeric Code", fallback: "4-digit numeric code")
    /// Chat Notifications DND: Option that deactivates DND after 6 hours
    public static let _6Hours = Strings.tr("Localizable", "6 hours", fallback: "6 hours")
    /// Action text to change to 6-Digit Numeric passcode type.
    public static let _6DigitNumericCode = Strings.tr("Localizable", "6-Digit Numeric Code", fallback: "6-digit numeric code")
    /// Text shown in the chat toolbar while the user is recording a voice clip. The < character should be > in RTL languages.
    public static let slideToCancel = Strings.tr("Localizable", "< Slide to cancel", fallback: "< Slide to cancel")
    /// Text indicating the user next step to unlock suspended account. Please leave [S], [/S] as it is which is used to bolden the text.
    public static let sPleaseVerifyYourEmailSAndFollowItsStepsToUnlockYourAccount = Strings.tr("Localizable", "[S]Please verify your email[/S] and follow its steps to unlock your account.", fallback: "Please follow the steps in the [S]verification email[/S] to unlock your account.")
    /// notification text
    public static let aUserHasLeftTheSharedFolder0 = Strings.tr("Localizable", "A user has left the shared folder {0}", fallback: "A user has left the shared folder {0}")
    /// Title of one of the Settings sections where you can see things 'About' the app
    public static let about = Strings.tr("Localizable", "about", fallback: "About")
    /// When somebody accepted your contact request
    public static let acceptedYourContactRequest = Strings.tr("Localizable", "Accepted your contact request", fallback: "Accepted your contact request")
    /// Label to show that an error related with an denied access occurs during a SDK operation.
    public static let accessDenied = Strings.tr("Localizable", "Access denied", fallback: "Access denied")
    /// SDK error returned for operations only allowed for business master users
    public static let accessDeniedForUsers = Strings.tr("Localizable", "Access denied for users", fallback: "Access denied for non-admin users")
    /// A description of MEGA features available only with a Pro plan.
    public static let accessProOnlyFeaturesLikeSettingPasswordProtectionAndExpiryDatesForPublicFiles = Strings.tr("Localizable", "Access Pro only features like setting password protection and expiry dates for public files.", fallback: "Access Pro only features like setting password protection and expiry dates for public links.")
    /// This is shown in the Notification dialog when the email address of a contact is not found and access to the share is lost for some reason (e.g. share removal or contact removal).
    public static let accessToFoldersWasRemoved = Strings.tr("Localizable", "Access to folders was removed.", fallback: "Access to folders was removed.")
    /// A notification telling the user that one of their contact’s accounts has been deleted or deactivated.
    public static let accountHasBeenDeletedDeactivated = Strings.tr("Localizable", "Account has been deleted/deactivated", fallback: "Account has been deleted or deactivated")
    /// Message shown when the user clicks on a confirm account link that has already been used
    public static let accountAlreadyConfirmed = Strings.tr("Localizable", "accountAlreadyConfirmed", fallback: "Your account has been activated. Please log in.")
    /// Error message when trying to login and the account is blocked
    public static let accountBlocked = Strings.tr("Localizable", "accountBlocked", fallback: "Your account was terminated due to a breach of MEGA’s Terms of Service including, but not limited to, clause 15.")
    /// During account cancellation (deletion)
    public static let accountCanceledSuccessfully = Strings.tr("Localizable", "accountCanceledSuccessfully", fallback: "Your account has been deleted")
    /// Text shown just after creating an account to remenber the user what to do to complete the account creation proccess
    public static let accountNotConfirmed = Strings.tr("Localizable", "accountNotConfirmed", fallback: "Please check your email and follow the link to confirm your account.")
    /// title of the My Account screen
    public static let accountType = Strings.tr("Localizable", "accountType", fallback: "Account type:")
    /// Label to give feedback to the user when he is going to share his location, indicating that it may not be the exact location.
    public static func accurateToDMeters(_ p1: Int) -> String {
      return Strings.tr("Localizable", "Accurate to %d meters", p1, fallback: "Accurate to %d meters")
    }
    /// Title of the Achievements section
    public static let achievementsTitle = Strings.tr("Localizable", "achievementsTitle", fallback: "Achievements")
    /// Title for the section "Acknowledgements" of the app
    public static let acknowledgements = Strings.tr("Localizable", "acknowledgements", fallback: "Acknowledgements")
    /// Business account status
    public static let active = Strings.tr("Localizable", "Active", fallback: "Active")
    /// Description shown in a page of the onboarding screens explaining contacts
    public static let addContactsCreateANetworkColaborateMakeVoiceAndVideoCallsWithoutEverLeavingMEGA = Strings.tr("Localizable", "Add contacts, create a network, colaborate, make voice and video calls without ever leaving MEGA", fallback: "Add contacts, create a network, collaborate, and make voice and video calls without ever leaving MEGA")
    /// Add Phone Number title
    public static let addPhoneNumber = Strings.tr("Localizable", "Add Phone Number", fallback: "Add phone number")
    /// Add your phone number title
    public static let addYourPhoneNumber = Strings.tr("Localizable", "Add Your Phone Number", fallback: "Add your phone number")
    /// Alert title shown when you select to add a contact inserting his/her email
    public static let addContact = Strings.tr("Localizable", "addContact", fallback: "Add contact")
    /// Button title to 'Add' the contact to your contacts list
    public static let addContactButton = Strings.tr("Localizable", "addContactButton", fallback: "Add")
    /// Button title shown in empty views when you can 'Add contacts'
    public static let addContacts = Strings.tr("Localizable", "addContacts", fallback: "Add contacts")
    /// A label for any ‘Added’ text or title. For example to show the upload date of a file/folder.
    public static let added = Strings.tr("Localizable", "Added", fallback: "Added")
    /// Content of a notification that informs how many files and folders have been added to a shared folder
    public static func addedLldFiles(_ p1: Int) -> String {
      return Strings.tr("Localizable", "Added %lld files", p1, fallback: "Added %lld files")
    }
    /// Content of a notification that informs how many files and folders have been added to a shared folder
    public static func addedLldFilesAnd1Folder(_ p1: Int) -> String {
      return Strings.tr("Localizable", "Added %lld files and 1 folder", p1, fallback: "Added %lld files and 1 folder")
    }
    /// Content of a notification that informs how many files and folders have been added to a shared folder
    public static func addedLldFolders(_ p1: Int) -> String {
      return Strings.tr("Localizable", "Added %lld folders", p1, fallback: "Added %lld folders")
    }
    /// Content of a notification that informs how many files and folders have been added to a shared folder
    public static let added1File = Strings.tr("Localizable", "Added 1 file", fallback: "Added 1 file")
    /// Content of a notification that informs how many files and folders have been added to a shared folder
    public static func added1FileAndLldFolders(_ p1: Int) -> String {
      return Strings.tr("Localizable", "Added 1 file and %lld folders", p1, fallback: "Added 1 file and %lld folders")
    }
    /// Content of a notification that informs how many files and folders have been added to a shared folder
    public static let added1FileAnd1Folder = Strings.tr("Localizable", "Added 1 file and 1 folder", fallback: "Added 1 file and 1 folder")
    /// Content of a notification that informs how many files and folders have been added to a shared folder
    public static let added1Folder = Strings.tr("Localizable", "Added 1 folder", fallback: "Added 1 folder")
    /// Content of a notification that informs how many files and folders have been added to a shared folder
    public static let addedAFilesAndBFolders = Strings.tr("Localizable", "Added [A] files and [B] folders", fallback: "Added [A] files and [B] folders")
    /// Button title shown in empty views when you can 'Add files'
    public static let addFiles = Strings.tr("Localizable", "addFiles", fallback: "Add files")
    /// Item menu option to add a contact through your device app Contacts
    public static let addFromContacts = Strings.tr("Localizable", "addFromContacts", fallback: "Add from contacts")
    /// Item menu option to add a contact writting his/her email
    public static let addFromEmail = Strings.tr("Localizable", "addFromEmail", fallback: "Enter an email address")
    /// Button label. Allows to add contacts in current chat conversation.
    public static let addParticipant = Strings.tr("Localizable", "addParticipant", fallback: "Add participant…")
    /// Menu item to add participants to a chat
    public static let addParticipants = Strings.tr("Localizable", "addParticipants", fallback: "Add participants")
    /// 
    public static let administrator = Strings.tr("Localizable", "Administrator", fallback: "Administrator")
    /// Title of one of the Settings sections where you can configure 'Advanced' options
    public static let advanced = Strings.tr("Localizable", "advanced", fallback: "Advanced")
    /// Over Disk Quota warnig message to tell user your data is subject to deletion.
    public static let afterThatYourDataIsSubjectToDeletion = Strings.tr("Localizable", "After that, your data is subject to deletion.", fallback: "After that, your data is subject to deletion.")
    /// button caption text that the user clicks when he agrees
    public static let agree = Strings.tr("Localizable", "agree", fallback: "Agree")
    /// This text is displayed in the account creation screen with a checkbox. User will have to tick the checkbox before proceeding on to create an account
    public static let agreeWithLosingPasswordYouLoseData = Strings.tr("Localizable", "agreeWithLosingPasswordYouLoseData", fallback: "I understand that [S]if I lose my password, I may lose my data.[/S] Read more about <a href=\"terms\">MEGA’s end-to-end encryption</a>.")
    /// 
    public static let agreeWithTheMEGATermsOfService = Strings.tr("Localizable", "agreeWithTheMEGATermsOfService", fallback: "I agree with the MEGA <a href=\"terms\">Terms of Service</a>")
    /// Title for the album/collection link view
    public static let albumLink = Strings.tr("Localizable", "albumLink", fallback: "Album link")
    /// Used in Photos app browser album listing screen.
    public static let albums = Strings.tr("Localizable", "Albums", fallback: "Albums")
    /// Add nickname screen: This text appears above the alias(nickname) entry
    public static let aliasNickname = Strings.tr("Localizable", "Alias/ Nickname", fallback: "Alias or nickname")
    /// Title of one of the filters in the Transfers section. In this case "All" transfers.
    public static let all = Strings.tr("Localizable", "all", fallback: "All")
    /// Text shown for switching from preview view to all media view.
    public static let allMedia = Strings.tr("Localizable", "All Media", fallback: "All media")
    /// Footer description when upload all burst photos is enabled
    public static let allThePhotosFromYourBurstPhotoSequencesWillBeUploaded = Strings.tr("Localizable", "All the photos from your burst photo sequences will be uploaded.", fallback: "All the photos from your burst photo sequences will be uploaded.")
    /// Button which triggers a request for a specific permission, that have been explained to the user beforehand
    public static let allowAccess = Strings.tr("Localizable", "Allow Access", fallback: "Allow access")
    /// Title label that explains that the user is going to be asked for the photos permission
    public static let allowAccessToPhotos = Strings.tr("Localizable", "Allow Access to Photos", fallback: "Allow access to photos")
    /// Footer text to explain the meaning of the functionaly 'Last seen' of your chat status.
    public static let allowYourContactsToSeeTheLastTimeYouWereActiveOnMEGA = Strings.tr("Localizable", "Allow your contacts to see the last time you were active on MEGA.", fallback: "Allow your contacts to see the last time you were active on MEGA.")
    /// Alert message to remenber the user that needs to enable purchases before continue
    public static let allowPurchaseMessage = Strings.tr("Localizable", "allowPurchase_message", fallback: "You must enable In-App Purchases in your iOS Settings before restoring a purchase.")
    /// Alert title to remenber the user that needs to enable purchases
    public static let allowPurchaseTitle = Strings.tr("Localizable", "allowPurchase_title", fallback: "Allow purchases")
    /// Label to show that an error related with an existent resource occurs during a SDK operation.
    public static let alreadyExists = Strings.tr("Localizable", "Already exists", fallback: "Already exists")
    /// Error message displayed when trying to invite a contact who is already added.
    public static func alreadyAContact(_ p1: UnsafePointer<CChar>) -> String {
      return Strings.tr("Localizable", "alreadyAContact", p1, fallback: "%s is already a contact.")
    }
    /// Used in the \"rich previews\", when the user first tries to send an url - we ask them before we generate previews for that URL, since we need to send them unencrypted to our servers.
    public static let alwaysAllow = Strings.tr("Localizable", "alwaysAllow", fallback: "Always allow")
    /// Section title inside of Settings - Appearance, where you can change the app's icon.
    public static let appIcon = Strings.tr("Localizable", "App Icon", fallback: "App icon")
    /// App means “Application”
    public static let appVersion = Strings.tr("Localizable", "App Version", fallback: "App version")
    /// Error message shown the In App Purchase is disabled in the device Settings
    public static let appPurchaseDisabled = Strings.tr("Localizable", "appPurchaseDisabled", fallback: "In-app purchases is disabled, please enable it in the iOS Settings app")
    /// Button title
    public static let approve = Strings.tr("Localizable", "approve", fallback: "Approve")
    /// Title of button to archive chats.
    public static let archiveChat = Strings.tr("Localizable", "archiveChat", fallback: "Archive")
    /// Confirmation message on archive chat dialog for user to confirm.
    public static let archiveChatMessage = Strings.tr("Localizable", "archiveChatMessage", fallback: "Are you sure you want to archive this conversation?")
    /// Title of flag of archived chats.
    public static let archived = Strings.tr("Localizable", "archived", fallback: "Archived")
    /// Title of archived chats button
    public static let archivedChats = Strings.tr("Localizable", "archivedChats", fallback: "Archived")
    /// text of the alert dialog when the user is changing the API URL to staging
    public static let areYouSureYouWantToChangeToATestServerYourAccountMaySufferIrrecoverableProblems = Strings.tr("Localizable", "Are you sure you want to change to a test server? Your account may suffer irrecoverable problems", fallback: "Are you sure you want to change to a test server? Your account may suffer irrecoverable problems.")
    /// Message when to move Camera Uploads folder to Rubbish Bin
    public static let areYouSureYouWantToMoveCameraUploadsFolderToRubbishBinIfSoANewFolderWillBeAutoGeneratedForCameraUploads = Strings.tr("Localizable", "Are you sure you want to move Camera Uploads folder to Rubbish Bin? If so, a new folder will be auto-generated for Camera Uploads.", fallback: "Are you sure you want to move the Camera uploads folder to the Rubbish bin? If so, a new folder will be automatically generated for Camera uploads.")
    /// Asking whether the user really wants to abort/stop the registration process or continue on.
    public static let areYouSureYouWantToAbortTheRegistration = Strings.tr("Localizable", "areYouSureYouWantToAbortTheRegistration", fallback: "Are you sure you want to abort the registration?")
    /// Mail subject to upgrade to a custom plan
    public static let askUsHowYouCanUpgradeToACustomPlan = Strings.tr("Localizable", "Ask us how you can upgrade to a custom plan:", fallback: "Ask us how you can upgrade to a custom plan:")
    /// A message appearing in the chat summary window when the most recent action performed by a user was attaching a file. Please keep %s as it will be replaced at runtime with the name of the attached file.
    public static func attachedFile(_ p1: UnsafePointer<CChar>) -> String {
      return Strings.tr("Localizable", "attachedFile", p1, fallback: "Attached: %s")
    }
    /// A summary message when a user has attached many files at once into the chat. Please keep %s as it will be replaced at runtime with the number of files.
    public static func attachedXFiles(_ p1: UnsafePointer<CChar>) -> String {
      return Strings.tr("Localizable", "attachedXFiles", p1, fallback: "Attached %s files.")
    }
    /// Alert title to attract attention
    public static let attention = Strings.tr("Localizable", "attention", fallback: "Attention")
    /// Title for audio explorer view
    public static let audio = Strings.tr("Localizable", "Audio", fallback: "Audio")
    /// Alert title shown when enabling Two-Factor Authentication when you don't have a two factor authentication app installed on the device
    public static let authenticatorAppRequired = Strings.tr("Localizable", "Authenticator app required", fallback: "Authenticator app required")
    /// Chat advantages information. Full text: Mega protects your chat with end-to-end (user controlled) encryption providing essential safety assurances: [S]Confidentiality.[/S] Only the author and intended recipients are able to decipher and read the content. [S]Authenticity.[/S] The system ensures that the data received is from the sender displayed, and its content has not been manipulated during transit.
    public static let authenticityExplanation = Strings.tr("Localizable", "authenticityExplanation", fallback: "[S]Authenticity.[/S] The system ensures that the data received is from the sender displayed, and its content has not been manipulated during transit.")
    /// Label for the setting that allow users to automatically add contacts when they scan his/her QR code. String as short as possible.
    public static let autoAccept = Strings.tr("Localizable", "autoAccept", fallback: "Auto-accept")
    /// Footer that explains the way Auto-Accept works for QR codes
    public static let autoAcceptFooter = Strings.tr("Localizable", "autoAcceptFooter", fallback: "MEGA users who scan your QR code will be automatically added to your contact list.")
    /// A header in the Chat settings. This changes the user's status to Away after some time of inactivity.
    public static let autoAway = Strings.tr("Localizable", "autoAway", fallback: "Auto-away")
    /// Text shown to explain what means 'Enable Camera Uploads'. The 'Cloud Drive' is the MEGA section, so please keep consistency
    public static let automaticallyBackupYourPhotosAndVideosToTheCloudDrive = Strings.tr("Localizable", "Automatically backup your photos and videos to the Cloud Drive.", fallback: "Automatically back up your photos and videos to your Cloud drive.")
    /// Text show under the setting 'History Retention' to explain what will happen if enabled
    public static let automaticallyDeleteMessagesOlderThanACertainAmountOfTime = Strings.tr("Localizable", "Automatically delete messages older than a certain amount of time", fallback: "Automatically delete messages older than a certain amount of time.")
    /// Text show under the setting 'History Retention' to explain that it is configured to '1 day'
    public static let automaticallyDeleteMessagesOlderThanOneDay = Strings.tr("Localizable", "Automatically delete messages older than one day", fallback: "Automatically delete messages older than one day.")
    /// Text show under the setting 'History Retention' to explain that it is configured to '1 month'
    public static let automaticallyDeleteMessagesOlderThanOneMonth = Strings.tr("Localizable", "Automatically delete messages older than one month", fallback: "Automatically delete messages older than one month.")
    /// Text show under the setting 'History Retention' to explain that it is configured to '1 week'
    public static let automaticallyDeleteMessagesOlderThanOneWeek = Strings.tr("Localizable", "Automatically delete messages older than one week", fallback: "Automatically delete messages older than one week.")
    /// Describe how works auto-renewable subscriptions on the Apple Store
    public static let autorenewableDescription = Strings.tr("Localizable", "autorenewableDescription", fallback: "Subscriptions are renewed automatically for successive subscription periods of the same duration and at the same price as the initial period chosen. You can switch off the automatic renewal of your MEGA Pro subscription no later than 24 hours before your next subscription payment is due via your iTunes account settings page. To manage your subscriptions, simply tap on the App Store icon on your mobile device, sign in with your Apple ID at the bottom of the page (if you haven’t already done so) and then tap View ID. You’ll be taken to your account page where you can scroll down to Manage App Subscriptions. From there, you can select your MEGA Pro subscription and view your scheduled renewal date, choose a different subscription package or toggle the on-off switch to off to disable the auto-renewal of your subscription.")
    /// Title for MEGA "Available" space.
    public static let availableLabel = Strings.tr("Localizable", "availableLabel", fallback: "Available")
    /// Title shown just after doing some action that requires confirming the action by an email
    public static let awaitingEmailConfirmation = Strings.tr("Localizable", "awaitingEmailConfirmation", fallback: "Awaiting email confirmation.")
    /// 
    public static let away = Strings.tr("Localizable", "away", fallback: "Away")
    /// Label for recovery key button
    public static let backupRecoveryKey = Strings.tr("Localizable", "backupRecoveryKey", fallback: "Back up Recovery key")
    /// Label to show that an error related with a bad session ID occurs during a SDK operation.
    public static let badSessionID = Strings.tr("Localizable", "Bad session ID", fallback: "Bad session ID")
    /// SDK error returned when there is a balance error
    public static let balanceError = Strings.tr("Localizable", "Balance error", fallback: "Balance error")
    /// Button title to start the setup of a feature. For example 'Begin Setup' for Two-Factor Authentication
    public static let beginSetup = Strings.tr("Localizable", "beginSetup", fallback: "Begin setup")
    /// SDK error returned when the billing failed
    public static let billingFailed = Strings.tr("Localizable", "Billing failed", fallback: "Billing failed")
    /// Label to show that an error related with a blocked account occurs during a SDK operation.
    public static let blocked = Strings.tr("Localizable", "Blocked", fallback: "Blocked")
    /// A notification telling the user that another user blocked them as a contact (they will no longer be able to contact them). E.g. name@email.com blocked you as a contact.
    public static let blockedYouAsAContact = Strings.tr("Localizable", "Blocked you as a contact", fallback: "Blocked you as a contact")
    /// A user can mark a folder or file with its own colour, in this case “Blue”.
    public static let blue = Strings.tr("Localizable", "Blue", fallback: "Blue")
    /// 
    public static let business = Strings.tr("Localizable", "Business", fallback: "Business")
    /// SDK error returned when a business account has expired
    public static let businessAccountHasExpired = Strings.tr("Localizable", "Business account has expired", fallback: "Account deactivated")
    /// 
    public static let busy = Strings.tr("Localizable", "busy", fallback: "Busy")
    /// Title of the button in the contact info screen to start an audio call
    public static let call = Strings.tr("Localizable", "Call", fallback: "Audio")
    /// Text to inform the user there is an active call and is participating
    public static let callStarted = Strings.tr("Localizable", "Call Started", fallback: "Call started")
    /// When an active call of user A with user B had ended
    public static let callEnded = Strings.tr("Localizable", "callEnded", fallback: "Call ended.")
    /// When an active call of user A with user B had failed
    public static let callFailed = Strings.tr("Localizable", "callFailed", fallback: "Call failed")
    /// Label shown when you call someone (outgoing call), before the call starts.
    public static let calling = Strings.tr("Localizable", "calling...", fallback: "Calling…")
    /// When an active call of user A with user B had cancelled
    public static let callWasCancelled = Strings.tr("Localizable", "callWasCancelled", fallback: "Call was cancelled")
    /// When an active call of user A with user B had not answered
    public static let callWasNotAnswered = Strings.tr("Localizable", "callWasNotAnswered", fallback: "Call was not answered")
    /// When an outgoing call of user A with user B had been rejected by user B
    public static let callWasRejected = Strings.tr("Localizable", "callWasRejected", fallback: "Call was rejected")
    /// Header title of Camera section on MEGA Settings > Advanced screen.
    public static let camera = Strings.tr("Localizable", "Camera", fallback: "Camera")
    /// Alert message to remember that MEGA app needs permission to use the Camera to take a photo or video and it doesn't have it
    public static let cameraPermissions = Strings.tr("Localizable", "cameraPermissions", fallback: "Please give MEGA permission to access your Camera in Settings")
    /// Message shown when the camera uploads have been completed
    public static let cameraUploadsComplete = Strings.tr("Localizable", "cameraUploadsComplete", fallback: "Camera uploads complete")
    /// Success message shown when Camera Uploads has been enabled
    public static let cameraUploadsEnabled = Strings.tr("Localizable", "cameraUploadsEnabled", fallback: "Camera uploads enabled")
    /// Title of one of the Settings sections where you can set up the 'Camera Uploads' options
    public static let cameraUploadsLabel = Strings.tr("Localizable", "cameraUploadsLabel", fallback: "Camera uploads")
    /// Message shown while uploading files. Singular.
    public static let cameraUploadsPendingFile = Strings.tr("Localizable", "cameraUploadsPendingFile", fallback: "Upload in progress, 1 file pending")
    /// Message shown while uploading files. Plural.
    public static func cameraUploadsPendingFiles(_ p1: Int) -> String {
      return Strings.tr("Localizable", "cameraUploadsPendingFiles", p1, fallback: "Upload in progress, %lu files pending")
    }
    /// Button title to cancel something
    public static let cancel = Strings.tr("Localizable", "cancel", fallback: "Cancel")
    /// During account cancellation (deletion)
    public static let cancellationLinkHasExpired = Strings.tr("Localizable", "cancellationLinkHasExpired", fallback: "Cancellation link has expired.")
    /// Possible state of a transfer. When the transfer was cancelled
    public static let cancelled = Strings.tr("Localizable", "Cancelled", fallback: "Cancelled")
    /// A notification that the other user cancelled their contact request so it is no longer valid. E.g. user@email.com cancelled their contact request.
    public static let cancelledTheirContactRequest = Strings.tr("Localizable", "Cancelled their contact request", fallback: "Cancelled their contact request")
    /// Message of the alert shown when you try to cancel transfers where {%@} = {ALL, UPLOAD or DOWNLOAD} + {tranfers}
    public static let cancelTransfersText = Strings.tr("Localizable", "cancelTransfersText", fallback: "Do you want to cancel all transfers?")
    /// Title of the alert shown when you try to cancel transfers
    public static let cancelTransfersTitle = Strings.tr("Localizable", "cancelTransfersTitle", fallback: "Cancel transfers")
    /// In 'My account', when user want to delete/remove/cancel account will click button named 'Cancel your account'
    public static let cancelYourAccount = Strings.tr("Localizable", "cancelYourAccount", fallback: "Delete account")
    /// Menu option from the `Add` section that allows the user to capture a video or a photo and upload it directly to MEGA.
    public static let capturePhotoVideo = Strings.tr("Localizable", "capturePhotoVideo", fallback: "Capture")
    /// The title of the alert dialog to change the email associated to an account.
    public static let changeEmail = Strings.tr("Localizable", "Change Email", fallback: "Change email address")
    /// Dialog title for the change launch tab screen
    public static let changeLaunchTab = Strings.tr("Localizable", "Change Launch Tab", fallback: "Change launch tab")
    /// Dialog button text for the change launch tab screen
    public static let changeSetting = Strings.tr("Localizable", "Change Setting", fallback: "Change setting")
    /// title of the alert dialog when the user is changing the API URL to staging
    public static let changeToATestServer = Strings.tr("Localizable", "Change to a test server?", fallback: "Change to a test server?")
    /// A log message in the chat conversation to tell the reader that a participant [A] changed group chat name to [B]. Please keep the [A] and '[B]' placeholders, they will be replaced at runtime. For example: Alice changed group chat name to 'MEGA'.
    public static let changedGroupChatNameTo = Strings.tr("Localizable", "changedGroupChatNameTo", fallback: "[A] changed the group chat name to “[B]”")
    /// Button title that allows the user change his name
    public static let changeName = Strings.tr("Localizable", "changeName", fallback: "Change name")
    /// Section title where you can change the app's passcode
    public static let changePasscodeLabel = Strings.tr("Localizable", "changePasscodeLabel", fallback: "Change passcode")
    /// Section title where you can change your MEGA's password
    public static let changePasswordLabel = Strings.tr("Localizable", "changePasswordLabel", fallback: "Change password")
    /// Chat section header
    public static let chat = Strings.tr("Localizable", "chat", fallback: "Chat")
    /// Default title of an empty chat.
    public static func chatCreatedOnS1(_ p1: UnsafePointer<CChar>) -> String {
      return Strings.tr("Localizable", "Chat created on %s1", p1, fallback: "Chat created on %s1")
    }
    /// Message show when the history of a chat has been successfully deleted.
    public static let chatHistoryHasBeenCleared = Strings.tr("Localizable", "Chat History has Been Cleared", fallback: "Chat history has been cleared")
    /// Label shown in a cell where you can enable a switch to get a chat link
    public static let chatLink = Strings.tr("Localizable", "Chat Link", fallback: "Chat link")
    /// Shown when an invalid/inexisting/not-available-anymore chat link is opened.
    public static let chatLinkUnavailable = Strings.tr("Localizable", "Chat Link Unavailable", fallback: "Chat link unavailable")
    /// Chat Notifications DND: This text will appear in the settings of every chat with the on/off switch
    public static let chatNotifications = Strings.tr("Localizable", "Chat Notifications", fallback: "Chat notifications")
    /// Full text: MEGA protects your chat with end-to-end (user controlled) encryption providing essential safety assurances: Confidentiality - Only the author and intended recipients are able to decipher and read the content. Authenticity - There is an assurance that the message received was authored by the stated sender, and its content has not been tampered with during transport or on the server.
    public static let chatIntroductionMessage = Strings.tr("Localizable", "chatIntroductionMessage", fallback: "MEGA protects your chat with zero-knowledge encryption providing essential safety assurances:")
    /// Alert message shown when a chat does not exist
    public static let chatNotFound = Strings.tr("Localizable", "chatNotFound", fallback: "Chat not found")
    /// Title show above the name of the persons with whom you're chatting
    public static let chattingWith = Strings.tr("Localizable", "chattingWith", fallback: "Chatting with")
    /// Choose Your Region title
    public static let chooseYourRegion = Strings.tr("Localizable", "Choose Your Region", fallback: "Choose your region")
    /// Menu option from the `Add` section that allows the user to choose a photo or video to upload it to MEGA.
    public static let choosePhotoVideo = Strings.tr("Localizable", "choosePhotoVideo", fallback: "Choose from Photos")
    /// Header that help you with the upgrading process explaining that you have to choose one of the plans below  to continue
    public static let choosePlan = Strings.tr("Localizable", "choosePlan", fallback: "Choose one of the plans from below:")
    /// 
    public static let chooseYourAccountType = Strings.tr("Localizable", "chooseYourAccountType", fallback: "Choose your account type")
    /// Label to show that an error related with a circular linkage occurs during a SDK operation.
    public static let circularLinkageDetected = Strings.tr("Localizable", "Circular linkage detected", fallback: "Circular linkage detected")
    /// Button title to clear something
    public static let clear = Strings.tr("Localizable", "clear", fallback: "Clear")
    /// tool bar title used in transfer widget, allow user to clear all items in the list
    public static let clearAll = Strings.tr("Localizable", "Clear All", fallback: "Clear All")
    /// Title show on the sheet to configure default values of the 'History Retention' setting
    public static let clearMessagesOlderThan = Strings.tr("Localizable", "Clear Messages Older Than", fallback: "Clear messages older than")
    /// tool bar title used in transfer widget, allow user to clear the selected items in the list
    public static let clearSelected = Strings.tr("Localizable", "Clear Selected", fallback: "Clear selected")
    /// Section title where you can 'Clear Cache' of your MEGA app
    public static let clearCache = Strings.tr("Localizable", "clearCache", fallback: "Clear cache")
    /// A button title to delete the history of a chat.
    public static let clearChatHistory = Strings.tr("Localizable", "clearChatHistory", fallback: "Clear chat history")
    /// A log message in the chat conversation to tell the reader that a participant [A] cleared the history of the chat. For example, Alice cleared the chat history.
    public static let clearedTheChatHistory = Strings.tr("Localizable", "clearedTheChatHistory", fallback: "[A] cleared the chat history.")
    /// Section title where you can 'Clear Offline files' of your MEGA app
    public static let clearOfflineFiles = Strings.tr("Localizable", "clearOfflineFiles", fallback: "Clear Offline files")
    /// A confirmation message for a user to confirm that they want to clear the history of a chat.
    public static let clearTheFullMessageHistory = Strings.tr("Localizable", "clearTheFullMessageHistory", fallback: "Are you sure you want to clear the full message history of this conversation?")
    /// A button label. The button allows the user to close the conversation.
    public static let close = Strings.tr("Localizable", "close", fallback: "Close")
    /// Account closure, password check dialog when user click on closure email.
    public static let closeAccount = Strings.tr("Localizable", "closeAccount", fallback: "Close account")
    /// Button text to close other login sessions except the current session in use. This will log out other devices which have an active login session.
    public static let closeOtherSessions = Strings.tr("Localizable", "closeOtherSessions", fallback: "Close other sessions")
    /// Title of the Cloud Drive section
    public static let cloudDrive = Strings.tr("Localizable", "cloudDrive", fallback: "Cloud drive")
    /// Title shown when your Cloud Drive is empty, when you don't have any files.
    public static let cloudDriveEmptyStateTitle = Strings.tr("Localizable", "cloudDriveEmptyState_title", fallback: "No files in your Cloud drive")
    /// Title shown when your Rubbish Bin is empty.
    public static let cloudDriveEmptyStateTitleRubbishBin = Strings.tr("Localizable", "cloudDriveEmptyState_titleRubbishBin", fallback: "Empty Rubbish bin")
    /// Success text shown in a label when the user scans a valid QR. String as short as possible.
    public static let codeScanned = Strings.tr("Localizable", "codeScanned", fallback: "Code scanned")
    /// Title of one of the filters in the Transfers section. In this case "Completed" transfers.
    public static let completed = Strings.tr("Localizable", "Completed", fallback: "Completed")
    /// Label for the state of a transfer when is being completing - (String as short as possible).
    public static let completing = Strings.tr("Localizable", "Completing...", fallback: "Completing…")
    /// Chat advantages information. Full text: Mega protects your chat with end-to-end (user controlled) encryption providing essential safety assurances: [S]Confidentiality.[/S] Only the author and intended recipients are able to decipher and read the content. [S]Authenticity.[/S] The system ensures that the data received is from the sender displayed, and its content has not been manipulated during transit.
    public static let confidentialityExplanation = Strings.tr("Localizable", "confidentialityExplanation", fallback: "[S]Confidentiality.[/S] Only the author and intended recipients are able to decipher and read the content.")
    /// Footer text explaining what means choosing a sorting preference 'Per Folder' or 'Same for All' in Settings - Appearance - Sorting And View Mode.
    public static let configureColumnSortingOrderOnAPerFolderBasisOrUseTheSameOrderForAllFolders = Strings.tr("Localizable", "Configure column sorting order on a per-folder basis, or use the same order for all folders.", fallback: "Configure column sorting order on a per-folder basis, or use the same order for all folders.")
    /// Footer text to explain what you could do in the Settings - User Interface - Launch section.
    public static let configureDefaultLaunchSection = Strings.tr("Localizable", "Configure default launch section.", fallback: "Configure default launch section.")
    /// Footer text to explain what you could do in the Settings - Appearance - Sorting And View Mode section.
    public static let configureSortingOrderAndTheDefaultViewListOrThumbnail = Strings.tr("Localizable", "Configure sorting order and the default view (List or Thumbnail).", fallback: "Configure sorting order and the default view (List or Thumbnail).")
    /// Title text for the account confirmation.
    public static let confirm = Strings.tr("Localizable", "confirm", fallback: "Confirm")
    /// Label for any ‘Confirm account’ button, link, text, title, etc. - (String as short as possible).
    public static let confirmAccount = Strings.tr("Localizable", "Confirm account", fallback: "Confirm account")
    /// Button text for the user to confirm their change of email address.
    public static let confirmEmail = Strings.tr("Localizable", "confirmEmail", fallback: "Confirm email")
    /// Hint text where the user have to re-write the new email to confirm it
    public static let confirmNewEmail = Strings.tr("Localizable", "confirmNewEmail", fallback: "Confirm new email")
    /// Hint text where the user have to re-write the new password to confirm it
    public static let confirmPassword = Strings.tr("Localizable", "confirmPassword", fallback: "Confirm password")
    /// Text shown on the confirm account view to remind the user what to do
    public static let confirmText = Strings.tr("Localizable", "confirmText", fallback: "Please enter your password to confirm your account")
    /// The [X] will be replaced with the e-mail address.
    public static let congratulationsNewEmailAddress = Strings.tr("Localizable", "congratulationsNewEmailAddress", fallback: "Congratulations, your new email address for this MEGA account is: [X]")
    /// Label in login screen to inform about the chat initialization proccess
    public static let connecting = Strings.tr("Localizable", "connecting", fallback: "Connecting…")
    /// Label to show that an error related with too many connections occurs during a SDK operation.
    public static let connectionOverflow = Strings.tr("Localizable", "Connection overflow", fallback: "Connection overflow")
    /// Menu option from the `Add` section that allows the user to share contact.
    public static let contact = Strings.tr("Localizable", "Contact", fallback: "Contact")
    /// A notification telling the user that they are now fully connected with the other user (the users are in each other’s address books).
    public static let contactRelationshipEstablished = Strings.tr("Localizable", "Contact relationship established", fallback: "Contact relationship established")
    /// A dialog message which is shown to sub-users of expired business accounts.
    public static let contactYourBusinessAccountAdministratorToResolveTheIssueAndActivateYourAccount = Strings.tr("Localizable", "Contact your business account administrator to resolve the issue and activate your account.", fallback: "Contact your Business account administrator to resolve the issue and activate your account.")
    /// Label title above the fingerprint credentials of a user's contact. A credential in this case is a stored piece of information representing the identity of the contact
    public static let contactCredentials = Strings.tr("Localizable", "contactCredentials", fallback: "Contact credentials")
    /// Clue text to help the user know what should write there. In this case the contact email you want to add to your contacts list
    public static let contactEmail = Strings.tr("Localizable", "contactEmail", fallback: "Contact email")
    /// Notification text body shown when you have received a contact request
    public static let contactRequest = Strings.tr("Localizable", "contactRequest", fallback: "Contact request")
    /// Title of Contacts requests section
    public static let contactRequests = Strings.tr("Localizable", "contactRequests", fallback: "Contact requests")
    /// Title shown when the Contacts section is empty, when you have not added any contact.
    public static let contactsEmptyStateTitle = Strings.tr("Localizable", "contactsEmptyState_title", fallback: "No contacts")
    /// Title of the Contacts section
    public static let contactsTitle = Strings.tr("Localizable", "contactsTitle", fallback: "Contacts")
    /// Label for what a selection contains. For example: "Contains: 3 folders & 13 files". (no need to put the colon punctuation in the translation)
    public static let contains = Strings.tr("Localizable", "contains", fallback: "Contains")
    /// 'Next' button in a dialog
    public static let `continue` = Strings.tr("Localizable", "continue", fallback: "Continue")
    /// Text of the button after the links were copied to the clipboard
    public static let copiedToTheClipboard = Strings.tr("Localizable", "copiedToTheClipboard", fallback: "Copied to the clipboard")
    /// List option shown on the details of a file or folder
    public static let copy = Strings.tr("Localizable", "copy", fallback: "Copy")
    /// Caption of the button that will copy multiple files or folders export links to his clipboard
    public static let copyAll = Strings.tr("Localizable", "Copy All", fallback: "Copy all")
    /// Success message shown when you have copied 1 file and 1 folder
    public static let copyFileFolderMessage = Strings.tr("Localizable", "copyFileFolderMessage", fallback: "1 file and 1 folder copied")
    /// Success message shown when you have copied 1 file and {1+} folders
    public static func copyFileFoldersMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "copyFileFoldersMessage", p1, fallback: "1 file and %d folders copied")
    }
    /// Success message shown when you have copied 1 file
    public static let copyFileMessage = Strings.tr("Localizable", "copyFileMessage", fallback: "1 file copied")
    /// Success message shown when you have copied {1+} files and 1 folder
    public static func copyFilesFolderMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "copyFilesFolderMessage", p1, fallback: "%d files and 1 folder copied")
    }
    /// Success message shown when you have copied [A] = {1+} files and [B] = {1+} folders
    public static let copyFilesFoldersMessage = Strings.tr("Localizable", "copyFilesFoldersMessage", fallback: "[A] files and [B] folders copied")
    /// Success message shown when you have copied {1+} files
    public static func copyFilesMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "copyFilesMessage", p1, fallback: "%d files copied")
    }
    /// Success message shown when you have copied 1 folder
    public static let copyFolderMessage = Strings.tr("Localizable", "copyFolderMessage", fallback: "1 folder copied")
    /// Success message shown when you have copied {1+} folders
    public static func copyFoldersMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "copyFoldersMessage", p1, fallback: "%d folders copied")
    }
    /// Title for a button that copies the key of the link to the clipboard
    public static let copyKey = Strings.tr("Localizable", "copyKey", fallback: "Copy key")
    /// Title for a button to copy the link to the clipboard
    public static let copyLink = Strings.tr("Localizable", "copyLink", fallback: "Copy link")
    /// String already exists: 367, but we need to split paragraphs.
    public static let copyrightMessagePart1 = Strings.tr("Localizable", "copyrightMessagePart1", fallback: "MEGA respects the copyrights of others and requires that users of the MEGA Cloud service comply with the laws of copyright.")
    /// String already exists: 367, but we need to split paragraphs
    public static let copyrightMessagePart2 = Strings.tr("Localizable", "copyrightMessagePart2", fallback: "You are strictly prohibited from using the MEGA Cloud service to infringe copyrights. You may not upload, download, store, share, display, stream, distribute, email, link to, transmit or otherwise make available any files, data or content that infringes any copyright or other proprietary rights of any person or entity.")
    /// A title for the Copyright Warning dialog.
    public static let copyrightWarning = Strings.tr("Localizable", "copyrightWarning", fallback: "Copyright warning")
    /// A title for the Copyright Warning dialog. Designed to make the user feel as though this is not targeting them, but is a warning for everybody who uses our service.
    public static let copyrightWarningToAll = Strings.tr("Localizable", "copyrightWarningToAll", fallback: "Copyright warning to all users")
    /// Text shown when an error occurs when trying to save a photo or video to Photos app
    public static let couldNotSaveItem = Strings.tr("Localizable", "Could not save Item", fallback: "Could not save Item")
    /// Country label for a button, title, etc.
    public static let country = Strings.tr("Localizable", "Country", fallback: "Country")
    /// Text shown for the action create new file
    public static let createNewFile = Strings.tr("Localizable", "Create new file", fallback: "Create new file")
    /// Title shown in a page of the on boarding screens explaining that the user can add contacts to chat and colaborate
    public static let createYourNetwork = Strings.tr("Localizable", "Create your Network", fallback: "Create your network")
    /// Button title which triggers the action to create a MEGA account
    public static let createAccount = Strings.tr("Localizable", "createAccount", fallback: "Create account")
    /// Title button for the create folder alert.
    public static let createFolderButton = Strings.tr("Localizable", "createFolderButton", fallback: "Create")
    /// SDK error returned when the credit card has been rejected
    public static let creditCardRejected = Strings.tr("Localizable", "Credit card rejected", fallback: "Credit card rejected")
    /// Footer text that explain what amount of space you will free up if 'Clear Offline data', 'Clear cache' or 'Clear Rubbish Bin' is tapped
    public static func currentlyUsing(_ p1: UnsafePointer<CChar>) -> String {
      return Strings.tr("Localizable", "currentlyUsing", p1, fallback: "Currently using %s")
    }
    /// Title of section to display information of the current version of a file.
    public static let currentVersion = Strings.tr("Localizable", "currentVersion", fallback: "Current version")
    /// Title of section to display information of all current versions of files.
    public static let currentVersions = Strings.tr("Localizable", "currentVersions", fallback: "Current versions")
    /// Action text to change to Custom Alphanumeric passcode type.
    public static let customAlphanumericCode = Strings.tr("Localizable", "Custom Alphanumeric Code", fallback: "Custom alphanumeric code")
    /// Title for custom settings
    public static let customSettings = Strings.tr("Localizable", "Custom Settings", fallback: "Custom settings")
    /// Used within the `Retention History` dropdown -- opens the dialog providing the ability to specify custom time range.
    public static let custom = Strings.tr("Localizable", "Custom...", fallback: "Custom…")
    /// Title of one of the Settings sections where you can see the MEGA's 'Data Protection Regulation'
    public static let dataProtectionRegulationLabel = Strings.tr("Localizable", "dataProtectionRegulationLabel", fallback: "Data protection regulation")
    /// Label for User Interface app icon "Day" in app settings
    public static let day = Strings.tr("Localizable", "day", fallback: "Day")
    /// 
    public static let days = Strings.tr("Localizable", "days", fallback: "days")
    /// Button title to try to decrypt the link
    public static let decrypt = Strings.tr("Localizable", "decrypt", fallback: "Decrypt")
    /// Hint text to suggest that the user has to write the decryption key
    public static let decryptionKey = Strings.tr("Localizable", "decryptionKey", fallback: "Decryption key")
    /// Alert message shown when you tap on a encrypted file/folder link that can't be opened because it doesn't include the key to see its contents
    public static let decryptionKeyAlertMessage = Strings.tr("Localizable", "decryptionKeyAlertMessage", fallback: "To access this folder or file, you will need its decryption key. If you do not have the key, please contact the creator of the link.")
    /// Alert message shown when you tap on a encrypted album/collection link that can't be opened because it doesn't include the key to see its contents
    public static let decryptionKeyAlertMessageForAlbum = Strings.tr("Localizable", "decryptionKeyAlertMessageForAlbum", fallback: "To access the album, enter the decryption key. If you don’t have it, contact the person who shared the link with you.")
    /// Alert title shown when you tap on a encrypted file/folder link that can't be opened because it doesn't include the key to see its contents
    public static let decryptionKeyAlertTitle = Strings.tr("Localizable", "decryptionKeyAlertTitle", fallback: "Enter decryption key")
    /// Alert title shown when you have written a decryption key not valid
    public static let decryptionKeyNotValid = Strings.tr("Localizable", "decryptionKeyNotValid", fallback: "Invalid decryption key")
    /// Label for any ‘Default’ button, link, text, title, etc. - (String as short as possible).
    public static let `default` = Strings.tr("Localizable", "Default", fallback: "Default")
    /// Inside of Settings - User Interface, there is a view on which you can change the default tab when launch the app.
    public static let defaultTab = Strings.tr("Localizable", "Default Tab", fallback: "Default tab")
    /// 
    public static let delete = Strings.tr("Localizable", "delete", fallback: "Delete")
    /// The title of the section about deleting file versions in the settings.
    public static let deleteAllOlderVersionsOfMyFiles = Strings.tr("Localizable", "Delete all older versions of my files", fallback: "Delete all older versions of my files")
    /// Text of a button which deletes all historical versions of files in the users entire account.
    public static let deletePreviousVersions = Strings.tr("Localizable", "Delete Previous Versions", fallback: "Delete previous versions")
    /// A notification telling the user that the other user deleted them as a contact. E.g. user@email.com deleted you as a contact.
    public static let deletedYouAsAContact = Strings.tr("Localizable", "Deleted you as a contact", fallback: "Deleted you as a contact")
    /// Button which allows to delete message in chat conversation.
    public static let deleteMessage = Strings.tr("Localizable", "deleteMessage", fallback: "Delete message")
    /// Question to ensure user wants to delete file version.
    public static let deleteVersion = Strings.tr("Localizable", "deleteVersion", fallback: "Do you want to delete this version?")
    /// When somebody denied your contact request
    public static let deniedYourContactRequest = Strings.tr("Localizable", "Denied your contact request", fallback: "Rejected your contact request")
    /// Description shown when you almost had used your available transfer quota.
    public static let depletedTransferQuotaMessage = Strings.tr("Localizable", "depletedTransferQuota_message", fallback: "Your queued download exceeds the current transfer quota available for your account and may therefore be interrupted.")
    /// Title shown when you almost had used your available transfer quota.
    public static let depletedTransferQuotaTitle = Strings.tr("Localizable", "depletedTransferQuota_title", fallback: "Insufficient transfer quota")
    /// Text used for a title or header listing the details of something.
    public static let details = Strings.tr("Localizable", "DETAILS", fallback: "Details")
    /// Title to show when device local storage is almost full
    public static let deviceStorageAlmostFull = Strings.tr("Localizable", "Device Storage Almost Full", fallback: "Device storage almost full")
    /// Alert message shown when the DEBUG mode is disabled
    public static let disableDebugModeMessage = Strings.tr("Localizable", "disableDebugMode_message", fallback: "The log (MEGAiOS.log) will be deleted from the Offline section.")
    /// Alert title shown when the DEBUG mode is disabled
    public static let disableDebugModeTitle = Strings.tr("Localizable", "disableDebugMode_title", fallback: "Disable debug mode")
    /// button caption text that the user clicks when he disagrees
    public static let disagree = Strings.tr("Localizable", "disagree", fallback: "Disagree")
    /// Text used to notify the user that some action would discard a non ended action
    public static let discardChanges = Strings.tr("Localizable", "Discard Changes", fallback: "Discard changes")
    /// Label for any 'Dismiss' button, link, text, title, etc. - (String as short as possible).
    public static let dismiss = Strings.tr("Localizable", "dismiss", fallback: "Dismiss")
    /// File Manager -> Context menu item for taken down file or folder, for dispute takedown.
    public static let disputeTakedown = Strings.tr("Localizable", "Dispute Takedown", fallback: "Dispute takedown")
    /// Chat settings: This text appears with the Do Not Disturb switch
    public static let doNotDisturb = Strings.tr("Localizable", "Do Not Disturb", fallback: "Do not disturb")
    /// Confirmation dialog for the button that logs the user out of all sessions except the current one.
    public static let doYouWantToCloseAllOtherSessionsThisWillLogYouOutOnAllOtherActiveSessionsExceptTheCurrentOne = Strings.tr("Localizable", "Do you want to close all other sessions? This will log you out on all other active sessions except the current one.", fallback: "Do you want to close all other sessions? This will log you out on all other active sessions except the current one.")
    /// Message shown when a link is shared having a password
    public static let doYouWantToShareThePasswordForThisLink = Strings.tr("Localizable", "Do you want to share the password for this link?", fallback: "Do you want to share the password for this link?")
    /// Home Screen: Explorer view card title - Documents
    public static let docs = Strings.tr("Localizable", "Docs", fallback: "Docs")
    /// A tooltip message which is shown when device does not support document scanning
    public static let documentScanningIsNotAvailable = Strings.tr("Localizable", "Document scanning is not available", fallback: "Document scanning is not available")
    /// Title for document explorer view
    public static let documents = Strings.tr("Localizable", "Documents", fallback: "Documents")
    /// 
    public static let done = Strings.tr("Localizable", "done", fallback: "Done")
    /// Text next to a toggle that if enabled won't appear again
    public static let dontShowAgain = Strings.tr("Localizable", "dontShowAgain", fallback: "Do not show again")
    /// Text next to a switch that allows disabling the HTTP protocol for transfers
    public static let dontUseHttp = Strings.tr("Localizable", "dontUseHttp", fallback: "Don’t use HTTP")
    /// 
    public static let download = Strings.tr("Localizable", "download", fallback: "Download")
    /// Title of the dialog displayed the first time that a user want to download a image. Asks if wants to export image files to the photo album after download in future and informs that user can change this option afterwards - (String as short as possible).
    public static let downloadOptions = Strings.tr("Localizable", "Download options", fallback: "Download options")
    /// Button title which downloads a file/folder to your device
    public static let downloadButton = Strings.tr("Localizable", "downloadButton", fallback: "Download")
    /// Title show when a file is being downloaded
    public static let downloading = Strings.tr("Localizable", "downloading", fallback: "Downloading")
    /// Label for the status of a transfer when is being Downloading - (String as short as possible.
    public static func downloading(_ p1: Any) -> String {
      return Strings.tr("Localizable", "Downloading %@", String(describing: p1), fallback: "Downloading %@")
    }
    /// Title of one of the filters in the Transfers section. In this case "Downloads" transfers.
    public static let downloads = Strings.tr("Localizable", "downloads", fallback: "Downloads")
    /// Message shown when a download starts
    public static let downloadStarted = Strings.tr("Localizable", "downloadStarted", fallback: "Download started")
    /// Action suggestion text to the user in voice recording view
    public static let dragLeftToCancelReleaseToSend = Strings.tr("Localizable", "Drag left to cancel, release to send", fallback: "Drag left to cancel, release to send")
    /// Displayed after a call had ended, where %@ is the duration of the call (1h, 10seconds, etc)
    public static func duration(_ p1: Any) -> String {
      return Strings.tr("Localizable", "duration", String(describing: p1), fallback: "Duration: %@")
    }
    /// Caption of a button to edit the files that are selected
    public static let edit = Strings.tr("Localizable", "edit", fallback: "Edit")
    /// Contact details screen: Edit the alias(nickname) for a user
    public static let editNickname = Strings.tr("Localizable", "Edit Nickname", fallback: "Edit nickname")
    /// A log message in a chat to indicate that the message has been edited by the user.
    public static let edited = Strings.tr("Localizable", "edited", fallback: "(edited)")
    /// Text to notify user an email has been sent
    public static let emailSent = Strings.tr("Localizable", "Email sent", fallback: "Email sent")
    /// Error message when a use wants to validate the same email twice
    public static let emailAddressChangeAlreadyRequested = Strings.tr("Localizable", "emailAddressChangeAlreadyRequested", fallback: "You have already requested a confirmation link for that email address.")
    /// Error shown when the user tries to change his mail to one that is already used
    public static let emailAlreadyInUse = Strings.tr("Localizable", "emailAlreadyInUse", fallback: "Error. This email address is already in use.")
    /// Error text shown when the users tries to create an account with an email already in use
    public static let emailAlreadyRegistered = Strings.tr("Localizable", "emailAlreadyRegistered", fallback: "This email address has already registered an account with MEGA")
    /// Message shown when the user writes an invalid format in the email field
    public static let emailInvalidFormat = Strings.tr("Localizable", "emailInvalidFormat", fallback: "Enter a valid email")
    /// Text shown just after tap to change an email account to remenber the user what to do to complete the change email proccess
    public static let emailIsChangingDescription = Strings.tr("Localizable", "emailIsChanging_description", fallback: "Please go to your inbox and click the link to confirm your new email address.")
    /// Hint text to suggest that the user has to write his email
    public static let emailPlaceholder = Strings.tr("Localizable", "emailPlaceholder", fallback: "Email")
    /// Error message shown when you have not written the same email when confirming a new one
    public static let emailsDoNotMatch = Strings.tr("Localizable", "emailsDoNotMatch", fallback: "Email addresses do not match")
    /// Title shown when a folder doesn't have any files
    public static let emptyFolder = Strings.tr("Localizable", "emptyFolder", fallback: "Empty folder")
    /// Button text on the Rubbish Bin page. This button will empty all files and folders currently stored in the rubbish bin.
    public static let emptyRubbishBin = Strings.tr("Localizable", "emptyRubbishBin", fallback: "Empty Rubbish bin")
    /// Alert title shown when you tap 'Empty Rubbish Bin'
    public static let emptyRubbishBinAlertTitle = Strings.tr("Localizable", "emptyRubbishBinAlertTitle", fallback: "All the items in the Rubbish bin will be deleted")
    /// Text button shown when the chat is disabled and if tapped the chat will be enabled
    public static let enable = Strings.tr("Localizable", "enable", fallback: "Enable")
    /// Title label that explains that the user is going to be asked for the contacts permission
    public static let enableAccessToYourAddressBook = Strings.tr("Localizable", "Enable Access to Your Address Book", fallback: "Grant access to your address book")
    /// Title shown in a cell to allow the users enable the 'Encrypted Key Rotation'
    public static let enableEncryptedKeyRotation = Strings.tr("Localizable", "Enable Encrypted Key Rotation", fallback: "Enable Encryption key rotation")
    /// Title label that explains that the user is going to be asked for the microphone and camera permission
    public static let enableMicrophoneAndCamera = Strings.tr("Localizable", "Enable Microphone and Camera", fallback: "Enable microphone and camera")
    /// Title label that explains that the user is going to be asked for the notifications permission
    public static let enableNotifications = Strings.tr("Localizable", "Enable Notifications", fallback: "Enable notifications")
    /// Button title that enables the functionality 'Camera Uploads', which uploads all the photos in your device to MEGA
    public static let enableCameraUploadsButton = Strings.tr("Localizable", "enableCameraUploadsButton", fallback: "Enable Camera uploads")
    /// The label of the toggle switch to indicate that file versioning is enabled.
    public static let enabled = Strings.tr("Localizable", "Enabled", fallback: "Enabled")
    /// Alert message shown when the DEBUG mode is enabled
    public static let enableDebugModeMessage = Strings.tr("Localizable", "enableDebugMode_message", fallback: "A log will be created in the Offline section (MEGAiOS.log). Logs can contain information related to your account.")
    /// Alert title shown when the DEBUG mode is enabled
    public static let enableDebugModeTitle = Strings.tr("Localizable", "enableDebugMode_title", fallback: "Enable debug mode")
    /// Used in the \"rich previews\", when the user first tries to send an url - we ask them before we generate previews for that URL, since we need to send them unencrypted to our servers.
    public static let enableRichUrlPreviews = Strings.tr("Localizable", "enableRichUrlPreviews", fallback: "Enable rich URL previews")
    /// The text of a button. This button will encrypt a link with a password.
    public static let encrypt = Strings.tr("Localizable", "encrypt", fallback: "Encrypt")
    /// The text of a button. This button will encrypt a link with a password.
    public static let encrypted = Strings.tr("Localizable", "encrypted", fallback: "Encrypted")
    /// Title shown in a page of the on boarding screens explaining that the chat is encrypted
    public static let encryptedChat = Strings.tr("Localizable", "Encrypted chat", fallback: "Encrypted chat")
    /// Label in a cell where you can enable the 'Encrypted Key Rotation'
    public static let encryptedKeyRotation = Strings.tr("Localizable", "Encrypted Key Rotation", fallback: "Encryption key rotation")
    /// Text used as a section title or similar
    public static let enterEmail = Strings.tr("Localizable", "Enter Email", fallback: "Enter email")
    /// Title of the dialog shown when the user it is creating a chat link and the chat has not title
    public static let enterGroupName = Strings.tr("Localizable", "Enter group name", fallback: "Enter group name")
    /// This placeholder text is used on the Password Decrypt dialog as an instruction for the user.
    public static let enterThePassword = Strings.tr("Localizable", "Enter the password", fallback: "Enter the password")
    /// Text shown in the last alert dialog to confirm the cancellation of an account
    public static let enterYourPasswordToConfirmThatYouWanToClose = Strings.tr("Localizable", "enterYourPasswordToConfirmThatYouWanToClose", fallback: "This is the last step to delete your account. You will permanently lose all the data stored in the cloud. Please enter your password below.")
    /// Title of one of the passcode options. If enabled will do what footer explains.
    public static let eraseAllLocalDataLabel = Strings.tr("Localizable", "eraseAllLocalDataLabel", fallback: "Erase local data")
    /// 
    public static let error = Strings.tr("Localizable", "error", fallback: "Error")
    /// Label to show that an error related with expiration occurs during a SDK operation.
    public static let expired = Strings.tr("Localizable", "Expired", fallback: "Expired")
    /// Text that shows the expiry date of the account PRO level
    public static func expiresOn(_ p1: Any) -> String {
      return Strings.tr("Localizable", "expiresOn", String(describing: p1), fallback: "expires on %@")
    }
    /// Text for options in Get Link View to activate expiry date
    public static let expiryDate = Strings.tr("Localizable", "Expiry Date", fallback: "Expiry date")
    /// Hint text for option separate the key from the link in Get Link View
    public static let exportTheLinkAndDecryptionKeySeparately = Strings.tr("Localizable", "Export the link and decryption key separately.", fallback: "Export the link and decryption key separately.")
    /// Advising the user to keep the user's master key safe.
    public static let exportMasterKeyFooter = Strings.tr("Localizable", "exportMasterKeyFooter", fallback: "Exporting the Recovery key and keeping it in a secure location enables you to set a new password without data loss.")
    /// A dialog title to export the Recovery Key for the current user.
    public static let exportRecoveryKey = Strings.tr("Localizable", "exportRecoveryKey", fallback: "Export Recovery key")
    /// Label to show that a SDK operation has failed permanently.
    public static let failedPermanently = Strings.tr("Localizable", "Failed permanently", fallback: "Failed permanently")
    /// A message shown to users when phone number removal fails.
    public static let failedToRemoveYourPhoneNumberPleaseTryAgainLater = Strings.tr("Localizable", "Failed to remove your phone number, please try again later.", fallback: "Failed to remove your phone number, please try again later.")
    /// Accessibility message when a message sending fails in chat
    public static let failedToSendTheMessage = Strings.tr("Localizable", "failed to send the message", fallback: "failed to send the message")
    /// Footer text that explain what will happen if reach the max number of failed attempts
    public static let failedAttempstSectionTitle = Strings.tr("Localizable", "failedAttempstSectionTitle", fallback: "You will be logged out and your offline files will be deleted after 10 failed attempts")
    /// Alert message shown when a purchase has stopped because some error between the process
    public static let failedPurchaseMessage = Strings.tr("Localizable", "failedPurchase_message", fallback: "Either you cancelled the request or Apple reported a transaction error. Please try again later, or contact ios@mega.nz.")
    /// Alert title shown when a purchase has stopped because some error between the process
    public static let failedPurchaseTitle = Strings.tr("Localizable", "failedPurchase_title", fallback: "Purchase stopped")
    /// Alert message shown when the restoring process has stopped for some reason
    public static let failedRestoreMessage = Strings.tr("Localizable", "failedRestore_message", fallback: "Either the request was cancelled or the prior purchase could not be restored. Please try again later, or contact ios@mega.nz.")
    /// Alert title shown when the restoring process has stopped for some reason
    public static let failedRestoreTitle = Strings.tr("Localizable", "failedRestore_title", fallback: "Restore stopped")
    /// Context menu item. Allows user to add file/folder to favourites
    public static let favourite = Strings.tr("Localizable", "Favourite", fallback: "Favourite")
    /// Text for title for favourite nodes
    public static let favourites = Strings.tr("Localizable", "Favourites", fallback: "Favourites")
    /// Singular of file. 1 file
    public static let file = Strings.tr("Localizable", "file", fallback: "file")
    /// Error message shown when opening a file link which doesn’t exist
    public static let fileLinkUnavailable = Strings.tr("Localizable", "File link unavailable", fallback: "File link unavailable")
    /// A section header which contains the file management settings. These settings allow users to remove duplicate files etc.
    public static let fileManagement = Strings.tr("Localizable", "File Management", fallback: "File management")
    /// file type title, used in changing the export format of scaned doc
    public static let fileType = Strings.tr("Localizable", "File Type", fallback: "File Type")
    /// Title of the option to enable or disable file versioning on Settings section
    public static let fileVersioning = Strings.tr("Localizable", "File versioning", fallback: "File versioning")
    /// Settings preference title to show file versions info of the account
    public static let fileVersions = Strings.tr("Localizable", "File Versions", fallback: "File versions")
    /// Hint text shown on the new text file alert.
    public static let fileName = Strings.tr("Localizable", "file_name", fallback: "File name")
    /// Message shown when the user selects a file from another cloud storage provider that's already uploaded. "[A] = {name of the original file} already uploaded with name [B] = {name of the file in MEGA}"
    public static let fileExistAlertControllerMessage = Strings.tr("Localizable", "fileExistAlertController_Message", fallback: "[A] already uploaded with the name [B]")
    /// Success message shown when you have moved 1 file and 1 folder to the rubbish bin
    public static let fileFolderMovedToRubbishBinMessage = Strings.tr("Localizable", "fileFolderMovedToRubbishBinMessage", fallback: "1 file and 1 folder moved to the Rubbish bin")
    /// Success message shown when 1 file and 1 folder have been removed from MEGA
    public static let fileFolderRemovedToRubbishBinMessage = Strings.tr("Localizable", "fileFolderRemovedToRubbishBinMessage", fallback: "1 file and 1 folder removed from MEGA")
    /// Success message shown when you have moved 1 file and {1+} folders to the rubbish bin
    public static func fileFoldersMovedToRubbishBinMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "fileFoldersMovedToRubbishBinMessage", p1, fallback: "1 file and %d folders moved to the Rubbish bin")
    }
    /// Success message shown when 1 file and {1+} folders have been removed from MEGA
    public static func fileFoldersRemovedToRubbishBinMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "fileFoldersRemovedToRubbishBinMessage", p1, fallback: "1 file and %d folders removed from MEGA")
    }
    /// Message shown when a file has been imported
    public static let fileImported = Strings.tr("Localizable", "fileImported", fallback: "File imported")
    /// Title for the file link view
    public static let fileLink = Strings.tr("Localizable", "fileLink", fallback: "File link")
    /// 
    public static let fileLinkUnavailableText1 = Strings.tr("Localizable", "fileLinkUnavailableText1", fallback: "This could be due to the following reasons:")
    /// ToS refers to Terms of Service and AUP refers to Acceptable Use Policy.
    public static let fileLinkUnavailableText2 = Strings.tr("Localizable", "fileLinkUnavailableText2", fallback: "The file has been removed as it violated our Terms of Service")
    /// 
    public static let fileLinkUnavailableText3 = Strings.tr("Localizable", "fileLinkUnavailableText3", fallback: "Invalid URL - the link you are trying to access does not exist")
    /// 
    public static let fileLinkUnavailableText4 = Strings.tr("Localizable", "fileLinkUnavailableText4", fallback: "The file has been deleted by the user.")
    /// Success message shown when you have moved 1 file to the rubbish bin
    public static let fileMovedToRubbishBinMessage = Strings.tr("Localizable", "fileMovedToRubbishBinMessage", fallback: "1 file moved to the Rubbish bin")
    /// Alert title shown when users try to stream an unsupported audio/video file
    public static let fileNotSupported = Strings.tr("Localizable", "fileNotSupported", fallback: "File not supported")
    /// Success message shown when 1 file has been removed from MEGA
    public static let fileRemovedToRubbishBinMessage = Strings.tr("Localizable", "fileRemovedToRubbishBinMessage", fallback: "1 file removed from MEGA")
    /// Subtitle shown on folders that gives you information about its content. This case "{1+} files"
    public static func files(_ p1: Int) -> String {
      return Strings.tr("Localizable", "files", p1, fallback: "%d files")
    }
    /// Message shown when you try to upload some photos or/and videos that are already uploaded in the current folder
    public static func filesAlreadyExistMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "filesAlreadyExistMessage", p1, fallback: "%d files selected were already uploaded into this folder.")
    }
    /// Toast text upon sending a single file to chat
    public static let fileSentToChat = Strings.tr("Localizable", "fileSentToChat", fallback: "File sent to chat")
    /// Success message when the attachment has been sent to a many chats
    public static func fileSentToXChats(_ p1: Int) -> String {
      return Strings.tr("Localizable", "fileSentToXChats", p1, fallback: "File sent to %1$d chats")
    }
    /// Success message shown when you have moved {1+} files and 1 folder to the rubbish bin
    public static func filesFolderMovedToRubbishBinMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "filesFolderMovedToRubbishBinMessage", p1, fallback: "%d files and 1 folder moved to the Rubbish bin")
    }
    /// Success message shown when {1+} files and 1 folder have been removed from MEGA
    public static func filesFolderRemovedToRubbishBinMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "filesFolderRemovedToRubbishBinMessage", p1, fallback: "%d files and 1 folder removed from MEGA")
    }
    /// Success message shown when you have moved [A] = {1+} files and [B] = {1+} folders to the rubbish bin
    public static let filesFoldersMovedToRubbishBinMessage = Strings.tr("Localizable", "filesFoldersMovedToRubbishBinMessage", fallback: "[A] files and [B] folders moved to the Rubbish bin")
    /// Success message shown when [A] = {1+} files and [B] = {1+} folders have been removed from MEGA
    public static let filesFoldersRemovedToRubbishBinMessage = Strings.tr("Localizable", "filesFoldersRemovedToRubbishBinMessage", fallback: "[A] files and [B] folders removed from MEGA")
    /// Message shown when some files have been imported
    public static let filesImported = Strings.tr("Localizable", "filesImported", fallback: "Files imported")
    /// Success message shown when you have moved {1+} files to the rubbish bin
    public static func filesMovedToRubbishBinMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "filesMovedToRubbishBinMessage", p1, fallback: "%d files moved to the Rubbish bin")
    }
    /// Success message shown when {1+} files have been removed from MEGA
    public static func filesRemovedToRubbishBinMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "filesRemovedToRubbishBinMessage", p1, fallback: "%d files removed from MEGA")
    }
    /// Toast text upon sending multiple files to chat
    public static let filesSentToChat = Strings.tr("Localizable", "filesSentToChat", fallback: "Files sent to chat")
    /// Error message shown when you try to download something bigger than the space available in your device
    public static let fileTooBigMessage = Strings.tr("Localizable", "fileTooBigMessage", fallback: "The file you are trying to download is bigger than the available memory.")
    /// Error message shown when you try to open something bigger than the free space in your device
    public static let fileTooBigMessageOpen = Strings.tr("Localizable", "fileTooBigMessage_open", fallback: "The file you are trying to open is bigger than the available memory.")
    /// Filter headline in the Filter UI on Camera Upload Timeline Screen
    public static let filter = Strings.tr("Localizable", "filter", fallback: "Filter")
    /// Hint text for the first name (Placeholder)
    public static let firstName = Strings.tr("Localizable", "firstName", fallback: "First name")
    /// 
    public static let folder = Strings.tr("Localizable", "folder", fallback: "Folder")
    /// Error message shown when opening a folder link which doesn’t exist
    public static let folderLinkUnavailable = Strings.tr("Localizable", "Folder link unavailable", fallback: "Folder link unavailable")
    /// Error message shown when a folder can't be created.
    public static func folderCreationError(_ p1: Any) -> String {
      return Strings.tr("Localizable", "folderCreationError", String(describing: p1), fallback: "The folder “%@” can’t be created")
    }
    /// Error message shown when a user tries to download a folder with the name Inbox on the main directory of the offline section
    public static let folderInboxError = Strings.tr("Localizable", "folderInboxError", fallback: "Inbox is reserved for use by Apple.")
    /// Title for the folder link view
    public static let folderLink = Strings.tr("Localizable", "folderLink", fallback: "Folder link")
    /// 
    public static let folderLinkUnavailableText1 = Strings.tr("Localizable", "folderLinkUnavailableText1", fallback: "This could be due to the following reasons:")
    /// 
    public static let folderLinkUnavailableText2 = Strings.tr("Localizable", "folderLinkUnavailableText2", fallback: "The folder link has been removed as it violated our Terms of Service.")
    /// 
    public static let folderLinkUnavailableText3 = Strings.tr("Localizable", "folderLinkUnavailableText3", fallback: "Invalid URL - the link you are trying to access does not exist")
    /// 
    public static let folderLinkUnavailableText4 = Strings.tr("Localizable", "folderLinkUnavailableText4", fallback: "The folder link has been disabled by the user.")
    /// Success message shown when you have moved 1 folder to the rubbish bin
    public static let folderMovedToRubbishBinMessage = Strings.tr("Localizable", "folderMovedToRubbishBinMessage", fallback: "1 folder moved to the Rubbish bin")
    /// Success message shown when 1 folder has been removed from MEGA
    public static let folderRemovedToRubbishBinMessage = Strings.tr("Localizable", "folderRemovedToRubbishBinMessage", fallback: "1 folder removed from MEGA")
    /// Success message shown when you have moved {1+} folders to the rubbish bin
    public static func foldersMovedToRubbishBinMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "foldersMovedToRubbishBinMessage", p1, fallback: "%d folders moved to the Rubbish bin")
    }
    /// Success message shown when {1+} folders have been removed from MEGA
    public static func foldersRemovedToRubbishBinMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "foldersRemovedToRubbishBinMessage", p1, fallback: "%d folders removed from MEGA")
    }
    /// Subtitle shown on the Contacts section under the name of the contact you have shared {Number of folders} with
    public static func foldersShared(_ p1: Int) -> String {
      return Strings.tr("Localizable", "foldersShared", p1, fallback: "%d folders")
    }
    /// Message shown when you try to downlonad a folder bigger than the available memory.
    public static let folderTooBigMessage = Strings.tr("Localizable", "folderTooBigMessage", fallback: "The folder you are trying to download is bigger than the available memory.")
    /// An option to reset the password.
    public static let forgotPassword = Strings.tr("Localizable", "forgotPassword", fallback: "Forgot password?")
    /// Item of a menu to forward a message chat to another chatroom
    public static let forward = Strings.tr("Localizable", "forward", fallback: "Forward")
    /// Label to indicate that the current user has a Free account.
    public static let free = Strings.tr("Localizable", "Free", fallback: "Free")
    /// 
    public static let fromCloudDrive = Strings.tr("Localizable", "fromCloudDrive", fallback: "From Cloud drive")
    /// Permissions given to the user you share your folder with
    public static let fullAccess = Strings.tr("Localizable", "fullAccess", fallback: "Full access")
    /// Description shown in a page of the onboarding screens explaining the chat feature
    public static let fullyEncryptedChatWithVoiceAndVideoCallsGroupMessagingAndFileSharingIntegrationWithYourCloudDrive = Strings.tr("Localizable", "Fully encrypted chat with voice and video calls, group messaging and file sharing integration with your Cloud Drive.", fallback: "Fully encrypted chat with voice and video calls, group messaging and file sharing integration with your Cloud drive.")
    /// Message shown when a link to a file or folder is being generated
    public static let generatingLink = Strings.tr("Localizable", "generatingLink", fallback: "Generating link…")
    /// Message shown when some links to files and/or folders are being generated
    public static let generatingLinks = Strings.tr("Localizable", "generatingLinks", fallback: "Generating links…")
    /// Label in a cell where you can get the chat link
    public static let getChatLink = Strings.tr("Localizable", "Get Chat Link", fallback: "Get chat link")
    /// 
    public static let good = Strings.tr("Localizable", "good", fallback: "Good")
    /// A user can mark a folder or file with its own colour, in this case “Green”.
    public static let green = Strings.tr("Localizable", "Green", fallback: "Green")
    /// A user can mark a folder or file with its own colour, in this case “Grey”.
    public static let grey = Strings.tr("Localizable", "Grey", fallback: "Grey")
    /// When an active goup call is ended
    public static let groupCallEnded = Strings.tr("Localizable", "Group call ended", fallback: "Group call ended")
    /// Label title for a group chat
    public static let groupChat = Strings.tr("Localizable", "groupChat", fallback: "Group chat")
    /// Label for any ‘Groups’ button, link, text, title, etc. On iOS is used to go to the chats 'Groups' section from Contacts
    public static let groups = Strings.tr("Localizable", "Groups", fallback: "Groups")
    /// Menu item
    public static let help = Strings.tr("Localizable", "help", fallback: "Help")
    /// Title of the section to access MEGA's help centre
    public static let helpCentreLabel = Strings.tr("Localizable", "helpCentreLabel", fallback: "Help Centre")
    /// Setting title for the feature that deletes messages automatically from a chat  after a period of time
    public static let historyClearing = Strings.tr("Localizable", "History Clearing", fallback: "History clearing")
    /// Accessibility label for Home section in tabbar item
    public static let home = Strings.tr("Localizable", "Home", fallback: "Home")
    /// 
    public static let howItWorks = Strings.tr("Localizable", "howItWorks", fallback: "How it works")
    /// 
    public static let howItWorksMain = Strings.tr("Localizable", "howItWorksMain", fallback: "Your friend needs to register for a free account on MEGA and [S]install at least one MEGA client application[/S] (either the MEGA Desktop App or one of our MEGA Mobile Apps)")
    /// 
    public static let howItWorksSecondary = Strings.tr("Localizable", "howItWorksSecondary", fallback: "You can notify your friend through any method. You will earn the quota if you have entered your friend’s email here prior to them registering with that address.")
    /// A message which is shown once someone has invited a friend as part of the achievements program.
    public static let howItWorksTertiary = Strings.tr("Localizable", "howItWorksTertiary", fallback: "You will not receive credit for inviting someone who has used MEGA previously and you will not be notified about such a rejection.")
    /// SDK error returned upon a HTTP error
    public static let httpError = Strings.tr("Localizable", "HTTP error", fallback: "HTTP error")
    /// Used in camera upload settings: This text will appear below the 'Include location tags' settings explaining the details of this settings
    public static let ifEnabledYouWillUploadInformationAboutWhereYourPicturesAndVideosWereTakenSoBeCarefulWhenSharingThem = Strings.tr("Localizable", "If enabled, you will upload information about where your pictures and videos were taken, so be careful when sharing them.", fallback: "If enabled, location information will be included with your pictures. Please be careful when sharing them.")
    /// This dialog message is used on the Password Decrypt dialog as an instruction for the user.
    public static let ifYouDoNotHaveThePasswordContactTheCreatorOfTheLink = Strings.tr("Localizable", "If you do not have the password, contact the creator of the link.", fallback: "If you do not have the password, contact the creator of the link.")
    /// 
    public static let ifYouLoseThisRecoveryKeyAndForgetYourPasswordBAllYourFilesFoldersAndMessagesWillBeInaccessibleEvenByMEGAB = Strings.tr("Localizable", "If you lose this Recovery key and forget your password, [B]all your files, folders and messages will be inaccessible, even by MEGA[/B].", fallback: "If you lose this Recovery key and forget your password, [B]all your files, folders and messages will be inaccessible, even by MEGA[/B].")
    /// Account closure, warning message to remind user to contact MEGA support after he confirms that he wants to cancel account.
    public static let ifYouCantAccessYourEmailAccount = Strings.tr("Localizable", "ifYouCantAccessYourEmailAccount", fallback: "If you can’t access your email, please contact support@mega.nz")
    /// Button title to allow the user ignore something
    public static let ignore = Strings.tr("Localizable", "ignore", fallback: "Ignore")
    /// Label used near to the option selected to encode the images uploaded to a chat (Automatic, High, Optimised)
    public static let imageQuality = Strings.tr("Localizable", "Image Quality", fallback: "Image quality")
    /// Footer text shown under the settings for download options 'Save Images/Videos in Library'
    public static let imagesAndOrVideosDownloadedWillBeStoredInTheDeviceSMediaLibraryInsteadOfTheOfflineSection = Strings.tr("Localizable", "Images and/or videos downloaded will be stored in the device’s media library instead of the Offline section.", fallback: "Images or videos downloaded will be stored in the device’s media library instead of the Offline section.")
    /// Label indicating that the enter passcode (pin) view will be displayed immediately if the application goes back to foreground after being in background.
    public static let immediately = Strings.tr("Localizable", "Immediately", fallback: "Immediately")
    /// Button title that triggers the importing link action
    public static let importToCloudDrive = Strings.tr("Localizable", "Import to Cloud Drive", fallback: "Import")
    /// Title of one of the filters in the Transfers section. In this case In Progress transfers
    public static let inProgress = Strings.tr("Localizable", "In Progress", fallback: "In progress")
    /// Subtitle of chat screen when the chat is inactive
    public static let inactiveChat = Strings.tr("Localizable", "Inactive chat", fallback: "Inactive chat")
    /// Used in camera upload settings: This text will appear with a switch to turn on/off location tags while uploading a file
    public static let includeLocationTags = Strings.tr("Localizable", "Include Location Tags", fallback: "Include location tags")
    /// Title of the "Incoming" Shared Items.
    public static let incoming = Strings.tr("Localizable", "incoming", fallback: "Incoming")
    /// notification subtitle of incoming calls
    public static let incomingCall = Strings.tr("Localizable", "Incoming call", fallback: "Incoming call")
    /// Title of the Incoming Shares section. Here you can see the folders that your contacts have shared with you
    public static let incomingShares = Strings.tr("Localizable", "incomingShares", fallback: "Incoming shares")
    /// Label to show that an error related with an Incomplete SDK operation.
    public static let incomplete = Strings.tr("Localizable", "Incomplete", fallback: "Incomplete")
    /// Alert message shown when a restore hasn't been completed correctly
    public static let incompleteRestoreMessage = Strings.tr("Localizable", "incompleteRestore_message", fallback: "The previous purchase could not be found. Please select the previously purchased product to restore. You will NOT be charged again.")
    /// Alert title shown when a restore hasn't been completed correctly
    public static let incompleteRestoreTitle = Strings.tr("Localizable", "incompleteRestore_title", fallback: "Restore issue")
    /// A button label. The button allows the user to get more info of the current context.
    public static let info = Strings.tr("Localizable", "info", fallback: "Info")
    /// 
    public static let insertYourFriendsEmails = Strings.tr("Localizable", "insertYourFriendsEmails", fallback: "Insert your friends’ emails:")
    /// Label to show that an Internal error occurs during a SDK operation.
    public static let internalError = Strings.tr("Localizable", "Internal error", fallback: "Internal error")
    /// Label to show that an error related with an invalid or missing application key occurs during a SDK operation.
    public static let invalidApplicationKey = Strings.tr("Localizable", "Invalid application key", fallback: "Invalid application key")
    /// Label to show that an error of Invalid argument occurs during a SDK operation.
    public static let invalidArgument = Strings.tr("Localizable", "Invalid argument", fallback: "Invalid argument")
    /// Label to show that an error related with the decryption process of a node occurs during a SDK operation.
    public static let invalidKeyDecryptionError = Strings.tr("Localizable", "Invalid key/Decryption error", fallback: "Decryption error")
    /// Error text shown when the user scans a QR that is not valid. String as short as possible.
    public static let invalidCode = Strings.tr("Localizable", "invalidCode", fallback: "Invalid code")
    /// Message shown when the user writes a wrong email or password on login
    public static let invalidMailOrPassword = Strings.tr("Localizable", "invalidMailOrPassword", fallback: "Invalid email or password. Please try again.")
    /// An alert title where the user provided the incorrect Recovery Key.
    public static let invalidRecoveryKey = Strings.tr("Localizable", "invalidRecoveryKey", fallback: "Invalid Recovery key")
    /// A button on a dialog which invites a contact to join MEGA.
    public static let invite = Strings.tr("Localizable", "invite", fallback: "Invite")
    /// Text showing the user one contact would be invited
    public static let invite1Contact = Strings.tr("Localizable", "Invite 1 contact", fallback: "Invite 1 contact")
    /// Text showing the user how many contacts would be invited
    public static let inviteXContacts = Strings.tr("Localizable", "Invite [X] contacts", fallback: "Invite [X] contacts")
    /// Text emncouraging the user to add contacts in MEGA
    public static let inviteContactNow = Strings.tr("Localizable", "Invite contact now", fallback: "Invite contacts now")
    /// Text encouraging the user to invite contacts to MEGA
    public static let inviteContactsAndStartChattingSecurelyWithMEGASEncryptedChat = Strings.tr("Localizable", "Invite contacts and start chatting securely with MEGA’s encrypted chat.", fallback: "Invite contacts and start chatting securely with MEGA’s encrypted chat.")
    /// Text shown when the user tries to make a call and the receiver is not a contact
    public static let inviteContact = Strings.tr("Localizable", "inviteContact", fallback: "Invite to MEGA")
    /// Text shown when the user sends a contact invitation
    public static let inviteSent = Strings.tr("Localizable", "inviteSent", fallback: "Invite sent")
    /// A typing indicator in the chat. Please leave the %@ which will be automatically replaced with the user's name at runtime.
    public static func isTyping(_ p1: Any) -> String {
      return Strings.tr("Localizable", "isTyping", String(describing: p1), fallback: "%@ is typing…")
    }
    /// Message shown when there is an ongoing call and the user tries to play an audio or video
    public static let itIsNotPossibleToPlayContentWhileThereIsACallInProgress = Strings.tr("Localizable", "It is not possible to play content while there is a call in progress", fallback: "It is not possible to play media files while there is a call in progress.")
    /// Message shown when there is an ongoing call and the user tries to record a voice message
    public static let itIsNotPossibleToRecordVoiceMessagesWhileThereIsACallInProgress = Strings.tr("Localizable", "It is not possible to record voice messages while there is a call in progress", fallback: "It is not possible to record voice messages while there is a call in progress.")
    /// Locked accounts description text by an external data breach. This text is 1 of 2 paragraph of a description.
    public static let itIsPossibleThatYouAreUsingTheSamePasswordForYourMEGAAccountAsForOtherServicesAndThatAtLeastOneOfTheseOtherServicesHasSufferedADataBreach = Strings.tr("Localizable", "It is possible that you are using the same password for your MEGA account as for other services, and that at least one of these other services has suffered a data breach.", fallback: "It is possible that you are using the same password for your MEGA account as for other services, and that at least one of these other services has suffered a data breach.")
    /// Title shown on the Camera Uploads section when the edit mode is enabled and you have selected more than one photo
    public static func itemsSelected(_ p1: Int) -> String {
      return Strings.tr("Localizable", "itemsSelected", p1, fallback: "%lu items selected")
    }
    /// Button text in public chat previews that allows the user to join the chat
    public static let join = Strings.tr("Localizable", "Join", fallback: "Join")
    /// Section title that links you to the webpage that let you join and test the beta versions
    public static let joinBeta = Strings.tr("Localizable", "Join Beta", fallback: "Join beta")
    /// A log message in a chat conversation to tell the reader that a participant [A] was added to the chat by a moderator [B]. Please keep the [A] and [B] placeholders, they will be replaced by the participant and the moderator names at runtime. For example: Alice joined the group chat by invitation from Frank.
    public static let joinedTheGroupChatByInvitationFrom = Strings.tr("Localizable", "joinedTheGroupChatByInvitationFrom", fallback: "[A] joined the group chat by invitation from [B].")
    /// Label shown while joining a public chat
    public static let joining = Strings.tr("Localizable", "Joining...", fallback: "Joining…")
    /// Label in a button that allows to jump to the latest item
    public static let jumpToLatest = Strings.tr("Localizable", "jumpToLatest", fallback: "Jump to latest")
    /// Text presenting a key (for a LINK or similar) as header usually
    public static let key = Strings.tr("Localizable", "KEY", fallback: "Key")
    /// Message shown when the key has been copied to the Clipboard
    public static let keyCopiedToClipboard = Strings.tr("Localizable", "Key Copied to Clipboard", fallback: "Key copied to clipboard")
    /// Footer to explain why key rotation is disabled for public chats with many participants
    public static let keyRotationIsDisabledForConversationsWithMoreThan100Participants = Strings.tr("Localizable", "Key rotation is disabled for conversations with more than 100 participants.", fallback: "Encryption key rotation is disabled for conversations with more than 100 participants.")
    /// Footer text to explain what means 'Encrypted Key Rotation'
    public static let keyRotationIsSlightlyMoreSecureButDoesNotAllowYouToCreateAChatLinkAndNewParticipantsWillNotSeePastMessages = Strings.tr("Localizable", "Key rotation is slightly more secure, but does not allow you to create a chat link and new participants will not see past messages.", fallback: "Encryption key rotation is slightly more secure, but does not allow you to create a chat link and new participants will not see past messages.")
    /// Sort by option (3/6). This one order the files by its size, in this case from bigger to smaller size
    public static let largest = Strings.tr("Localizable", "largest", fallback: "Largest")
    /// Shown when viewing a 1on1 chat (at least for now), if the user is offline.
    public static func lastSeenS(_ p1: UnsafePointer<CChar>) -> String {
      return Strings.tr("Localizable", "Last seen %s", p1, fallback: "Last seen: %s")
    }
    /// Text to inform the user the 'Last seen' time of a contact is a long time ago (>= 65535 minutes)
    public static let lastSeenALongTimeAgo = Strings.tr("Localizable", "Last seen a long time ago", fallback: "Last seen a long time ago")
    /// Hint text for the last name (Placeholder)
    public static let lastName = Strings.tr("Localizable", "lastName", fallback: "Last name")
    /// Button title to allow the user postpone an action
    public static let later = Strings.tr("Localizable", "later", fallback: "Later")
    /// Section title inside of Settings - User Interface, where you can change the app's launch.
    public static let launch = Strings.tr("Localizable", "Launch", fallback: "Launch")
    /// Text description leading the user to perform an action, ie the shortcuts widget
    public static let launchTheMEGAAppToPerformAnAction = Strings.tr("Localizable", "Launch the MEGA app to perform an action", fallback: "Launch the MEGA App to perform an action")
    /// Section title inside of Settings - Appearance, where you can change the app's layout.
    public static let layout = Strings.tr("Localizable", "Layout", fallback: "Layout")
    /// Label for any ‘Learn more’ button, link, text, title, etc. - (String as short as possible).
    public static let learnMore = Strings.tr("Localizable", "Learn more", fallback: "Learn more")
    /// A button label. The button allows the user to leave the group conversation.
    public static let leave = Strings.tr("Localizable", "leave", fallback: "Leave")
    /// Button title of the action that allows to leave a shared folder
    public static let leaveFolder = Strings.tr("Localizable", "leaveFolder", fallback: "Leave")
    /// Button title that allows the user to leave a group chat.
    public static let leaveGroup = Strings.tr("Localizable", "leaveGroup", fallback: "Leave group")
    /// Alert message shown when the user tap on the leave share action for one inshare
    public static let leaveShareAlertMessage = Strings.tr("Localizable", "leaveShareAlertMessage", fallback: "Are you sure you want to leave this share?")
    /// Alert message shown when the user tap on the leave share action selecting multiple inshares
    public static let leaveSharesAlertMessage = Strings.tr("Localizable", "leaveSharesAlertMessage", fallback: "Are you sure you want to leave these shares?")
    /// Label shown while leaving a public chat
    public static let leaving = Strings.tr("Localizable", "Leaving...", fallback: "Leaving…")
    /// A log message in the chat conversation to tell the reader that a participant [A] left the group chat. For example: Alice left the group chat.
    public static let leftTheGroupChat = Strings.tr("Localizable", "leftTheGroupChat", fallback: "[A] left the group chat")
    /// Label that encourage the user to line the QR to scan with the camera
    public static let lineCodeWithCamera = Strings.tr("Localizable", "lineCodeWithCamera", fallback: "Line up the QR code to scan it with your device’s camera")
    /// Text used as title or header for reference an url, for instance, a node link.
    public static let link = Strings.tr("Localizable", "LINK", fallback: "Link")
    /// Text referencing the date of creation of a link
    public static let linkCreation = Strings.tr("Localizable", "Link Creation", fallback: "Link creation")
    /// Text indicating the date until a link will be valid
    public static func linkExpires(_ p1: Any) -> String {
      return Strings.tr("Localizable", "Link expires %@", String(describing: p1), fallback: "Link expires %@")
    }
    /// Title for password protect link alert
    public static let linkPassword = Strings.tr("Localizable", "Link Password", fallback: "Link password")
    /// Message shown when the link has been copied to the pasteboard
    public static let linkCopied = Strings.tr("Localizable", "linkCopied", fallback: "Copied link")
    /// Message shown when the user clicks on an link that is not valid
    public static let linkNotValid = Strings.tr("Localizable", "linkNotValid", fallback: "Invalid link")
    /// Title of the "Links" Shared Items.
    public static let links = Strings.tr("Localizable", "Links", fallback: "Links")
    /// Message shown when some links have been copied to the pasteboard
    public static let linksCopied = Strings.tr("Localizable", "linksCopied", fallback: "Copied links")
    /// Error title shown when you open a file or folder link and it's no longer available
    public static let linkUnavailable = Strings.tr("Localizable", "linkUnavailable", fallback: "Unavailable link")
    /// This is button text on the Get Link dialog. This lets the user get a public file/folder link with the decryption key e.g. https://mega.nz/#!Qo12lSpT!3uv6GhJhAWWH46fcMN2KGRtxc_QSLthcwvAdaA_TjCE.
    public static let linkWithKey = Strings.tr("Localizable", "linkWithKey", fallback: "Link with key")
    /// This is button text on the Get Link dialog. This lets the user get a public file/folder link without the decryption key e.g. https://mega.nz/#!Qo12lSpT.
    public static let linkWithoutKey = Strings.tr("Localizable", "linkWithoutKey", fallback: "Link without key")
    /// Text shown for switching from thumbnail view to list view.
    public static let listView = Strings.tr("Localizable", "List View", fallback: "List view")
    /// state previous to import a file
    public static let loading = Strings.tr("Localizable", "loading", fallback: "Loading…")
    /// Title for "Local" used space.
    public static let localLabel = Strings.tr("Localizable", "localLabel", fallback: "Local")
    /// Title of a helping view about locked accounts
    public static let lockedAccounts = Strings.tr("Localizable", "Locked Accounts", fallback: "Locked accounts")
    /// Alert title shown when your account has been closed through another client or the web by killing all your sessions
    public static let loggedOutAlertTitle = Strings.tr("Localizable", "loggedOut_alertTitle", fallback: "Logged out")
    /// Alert message shown when your account has been closed through another client or the web by killing all your sessions
    public static let loggedOutFromAnotherLocation = Strings.tr("Localizable", "loggedOutFromAnotherLocation", fallback: "You have been logged out of this device from another location")
    /// String shown when you are logging out of your account.
    public static let loggingOut = Strings.tr("Localizable", "loggingOut", fallback: "Logging out")
    /// Button title which triggers the action to login in your MEGA account
    public static let login = Strings.tr("Localizable", "login", fallback: "Log in")
    /// Title of the button which logs out from your account.
    public static let logoutLabel = Strings.tr("Localizable", "logoutLabel", fallback: "Log out")
    /// A button to help them restore their account if they have lost their 2FA device.
    public static let lostYourAuthenticatorDevice = Strings.tr("Localizable", "lostYourAuthenticatorDevice", fallback: "Lost your authenticator device?")
    /// Footer text to explain the meaning of the functionaly 'Status Persistence' of your chat status.
    public static let maintainMyChosenStatusAppearance = Strings.tr("Localizable", "maintainMyChosenStatusAppearance", fallback: "Maintain my chosen status appearance even when I have no connected devices.")
    /// Text indicating to the user some action should be addressed. E.g. Navigate to Settings/File Management to clear cache.
    public static let manage = Strings.tr("Localizable", "Manage", fallback: "Manage")
    /// account management button title in business account’s landing page
    public static let manageAccount = Strings.tr("Localizable", "Manage Account", fallback: "Manage account")
    /// Text related with the section where you can manage the chat history. There you can for example, clear the history or configure the retention setting.
    public static let manageChatHistory = Strings.tr("Localizable", "Manage Chat History", fallback: "Manage chat history")
    /// Text indicating to the user the action that will be executed on tap.
    public static let manageShare = Strings.tr("Localizable", "Manage Share", fallback: "Manage share")
    /// Title of the alert that allows change between different maps: Standard, Satellite or Hybrid.
    public static let mapSettings = Strings.tr("Localizable", "Map settings", fallback: "Map settings")
    /// A button label. The button allows the user to mark a conversation as read.
    public static let markAsRead = Strings.tr("Localizable", "Mark as Read", fallback: "Mark as read")
    /// Alert title shown when you have exported your MEGA Recovery Key
    public static let masterKeyExported = Strings.tr("Localizable", "masterKeyExported", fallback: "Recovery key exported")
    /// Alert message shown to explain that the Recovery Key was saved on your device. Also that you can access it through iTunes. And ends with and security advise.
    public static let masterKeyExportedAlertMessage = Strings.tr("Localizable", "masterKeyExported_alertMessage", fallback: "The Recovery key has been exported into the Offline section as MEGA-RECOVERYKEY.txt. Note: It will be deleted if you log out, please store it in a safe place.")
    /// The title for my message in a chat. The message was sent from yourself.
    public static let me = Strings.tr("Localizable", "me", fallback: "Me")
    /// Section header of the settings that contains the folder to which photos will be uploded in camera upload
    public static let megaCameraUploadsFolder = Strings.tr("Localizable", "MEGA CAMERA UPLOADS FOLDER", fallback: "MEGA Camera uploads folder")
    /// Title of the label where the MEGAchat SDK version is shown
    public static let megachatSdkVersion = Strings.tr("Localizable", "megachatSdkVersion", fallback: "MEGA Chat SDK version")
    /// Label for any ‘Message’ button, link, text, title, etc. - (String as short as possible).
    public static let message = Strings.tr("Localizable", "Message", fallback: "Message")
    /// Accessibility message when a message is cancelled in chat
    public static let messageSendingCancelled = Strings.tr("Localizable", "message sending cancelled", fallback: "message sending cancelled")
    /// Accessibility message when a message is sent in chat
    public static let messageSent = Strings.tr("Localizable", "message sent", fallback: "message sent")
    /// Alert message shown when users try to stream an unsupported audio/video file
    public static let messageFileNotSupported = Strings.tr("Localizable", "message_fileNotSupported", fallback: "You can save it for Offline and open it in a compatible app.")
    /// Success message shown after forwarding messages to other chats
    public static let messagesSent = Strings.tr("Localizable", "messagesSent", fallback: "Messages sent")
    /// Alert message to remember that MEGA app needs permission to use the Microphone to make calls and record videos and it doesn't have it
    public static let microphonePermissions = Strings.tr("Localizable", "microphonePermissions", fallback: "Please give MEGA permission to access your Microphone in Settings")
    /// Label for any ‘Minimal’ button, link, text, title, etc. - (String as short as possible).
    public static let minimal = Strings.tr("Localizable", "Minimal", fallback: "Minimal")
    /// Title of the notification for a missed call
    public static let missedCall = Strings.tr("Localizable", "missedCall", fallback: "Missed call")
    /// A hint shown at the bottom of the Send Signup Link dialog to tell users they can edit the provided email.
    public static let misspelledEmailAddress = Strings.tr("Localizable", "misspelledEmailAddress", fallback: "If you have misspelled your email address, correct it and tap on “Resend”.")
    /// Information shown when the user has disabled the 'Mobile Data' setting for MEGA in the iOS Settings.
    public static let mobileDataIsTurnedOff = Strings.tr("Localizable", "Mobile Data is turned off", fallback: "Mobile data is turned off")
    /// The Moderator permission level in chat. With moderator permissions a participant can manage the chat.
    public static let moderator = Strings.tr("Localizable", "moderator", fallback: "Host")
    /// A label for any 'Modified' text or title. For example to show the modification date of a file/folder.
    public static let modified = Strings.tr("Localizable", "modified", fallback: "Modified")
    /// Title for action to modify the registered phone number.
    public static let modifyPhoneNumber = Strings.tr("Localizable", "Modify Phone Number", fallback: "Modify phone number")
    /// "Monthly" subscriptions
    public static let monthly = Strings.tr("Localizable", "monthly", fallback: "Monthly")
    /// Used on scheduling chat history clearing by month e.g. 3 months, 6 months.
    public static let months = Strings.tr("Localizable", "months", fallback: "months")
    /// Top menu option which opens more menu options in a context menu.
    public static let more = Strings.tr("Localizable", "more", fallback: "More")
    /// text that appear when there are more than 2 people writing at that time in a chat. For example User1, user2 and more are typing... The parameter will be the concatenation of the first two user names. The tags and placeholders shouldn't be translated or modified.
    public static func moreThanTwoUsersAreTyping(_ p1: UnsafePointer<CChar>) -> String {
      return Strings.tr("Localizable", "moreThanTwoUsersAreTyping", p1, fallback: "%1$s [A]and more are typing…[/A]")
    }
    /// Title for the action that allows you to move a file or folder
    public static let move = Strings.tr("Localizable", "move", fallback: "Move")
    /// Success message shown when you have moved 1 file and 1 folder
    public static let moveFileFolderMessage = Strings.tr("Localizable", "moveFileFolderMessage", fallback: "1 file and 1 folder moved")
    /// Success message shown when you have moved 1 file and {1+} folders
    public static func moveFileFoldersMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "moveFileFoldersMessage", p1, fallback: "1 file and %d folders moved")
    }
    /// Success message shown when you have moved 1 file
    public static let moveFileMessage = Strings.tr("Localizable", "moveFileMessage", fallback: "1 file moved")
    /// Success message shown when you have moved {1+} files and 1 folder
    public static func moveFilesFolderMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "moveFilesFolderMessage", p1, fallback: "%d files and 1 folder moved")
    }
    /// Success message shown when you have moved [A] = {1+} files and [B] = {1+} folders
    public static let moveFilesFoldersMessage = Strings.tr("Localizable", "moveFilesFoldersMessage", fallback: "[A] files and [B] folders moved")
    /// Success message shown when you have moved {1+} files
    public static func moveFilesMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "moveFilesMessage", p1, fallback: "%d files moved")
    }
    /// Success message shown when you have moved 1 folder
    public static let moveFolderMessage = Strings.tr("Localizable", "moveFolderMessage", fallback: "1 folder moved")
    /// Success message shown when you have moved {1+} folders
    public static func moveFoldersMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "moveFoldersMessage", p1, fallback: "%d folders moved")
    }
    /// SDK error returned when a MFA is required to perform an operation
    public static let multiFactorAuthenticationRequired = Strings.tr("Localizable", "Multi-factor authentication required", fallback: "Two-factor authentication required")
    /// A button label. The button allows the user to mute a conversation.
    public static let mute = Strings.tr("Localizable", "mute", fallback: "Mute")
    /// Chat Notifications DND: Title bar message for the dnd activate options
    public static let muteChatNotificationsFor = Strings.tr("Localizable", "Mute chat Notifications for", fallback: "Mute chat notifications for")
    /// The avatar picture button to go to my account page. Use for voice over.
    public static let myAccount = Strings.tr("Localizable", "My Account", fallback: "My account")
    /// Destination folder name of chat files
    public static let myChatFiles = Strings.tr("Localizable", "My chat files", fallback: "My chat files")
    /// Column header of my contacts/chats at copy dialog
    public static let myChats = Strings.tr("Localizable", "My chats", fallback: "My chats")
    /// Title of the label in the my account section. It shows the credentials of the current user so it can be used to be verified by other contacts
    public static let myCredentials = Strings.tr("Localizable", "My credentials", fallback: "My credentials")
    /// Label for any ‘My QR code’ button, link, text, title, etc. - (String as short as possible).
    public static let myQRCode = Strings.tr("Localizable", "My QR code", fallback: "My QR code")
    /// Sort by option (1/6). This one orders the files alphabethically
    public static let nameAscending = Strings.tr("Localizable", "nameAscending", fallback: "Name (ascending)")
    /// Sort by option (2/6). This one arranges the files on reverse alphabethical order
    public static let nameDescending = Strings.tr("Localizable", "nameDescending", fallback: "Name (descending)")
    /// Error text shown when you have not entered a correct name
    public static let nameInvalidFormat = Strings.tr("Localizable", "nameInvalidFormat", fallback: "Enter a valid name")
    /// Error message when a user attempts to change their email without an active login session.
    public static let needToBeLoggedInToCompleteYourEmailChange = Strings.tr("Localizable", "needToBeLoggedInToCompleteYourEmailChange", fallback: "You need to be logged in to complete your email change. Please log in again with your current email address, then tap on your confirmation link again.")
    /// 
    public static let never = Strings.tr("Localizable", "never", fallback: "Never")
    /// Label shown inside an unseen notification
    public static let new = Strings.tr("Localizable", "New", fallback: "New")
    /// Title for new camera upload feature
    public static let newCameraUpload = Strings.tr("Localizable", "New Camera Upload!", fallback: "New Camera uploads options")
    /// Text button for init a group chat with link.
    public static let newChatLink = Strings.tr("Localizable", "New Chat Link", fallback: "New chat link")
    /// Text button for init a group chat
    public static let newGroupChat = Strings.tr("Localizable", "New Group Chat", fallback: "New group chat")
    /// Menu option from the `Add` section that allows the user to create a new text file and upload it directly to MEGA.
    public static let newTextFile = Strings.tr("Localizable", "new_text_file", fallback: "New text file")
    /// Hint text to suggest that the user have to write the new email on it
    public static let newEmail = Strings.tr("Localizable", "newEmail", fallback: "New email address")
    /// Sort by option (5/6). This one order the files by its modification date, newer first
    public static let newest = Strings.tr("Localizable", "newest", fallback: "Newest")
    /// Menu option from the `Add` section that allows you to create a 'New Folder'
    public static let newFolder = Strings.tr("Localizable", "newFolder", fallback: "New folder")
    /// Hint text shown on the create folder alert.
    public static let newFolderMessage = Strings.tr("Localizable", "newFolderMessage", fallback: "Name for the new folder")
    /// Label in a button that allows to jump to the latest message
    public static let newMessages = Strings.tr("Localizable", "newMessages", fallback: "New messages")
    /// Hint text to suggest that the user have to write the new password on it
    public static let newPassword = Strings.tr("Localizable", "newPassword", fallback: "New password")
    /// Notification text body shown when you have received a new shared folder
    public static let newSharedFolder = Strings.tr("Localizable", "newSharedFolder", fallback: "New shared folder")
    /// 
    public static let next = Strings.tr("Localizable", "next", fallback: "Next")
    /// Label for any ‘Night’ button, link, text, title, etc. - (String as short as possible).
    public static let night = Strings.tr("Localizable", "Night", fallback: "Night")
    /// 
    public static let no = Strings.tr("Localizable", "no", fallback: "No")
    /// Audio Explorer Screen: No audio files in the account
    public static let noAudioFilesFound = Strings.tr("Localizable", "No audio files found", fallback: "No audio files found")
    /// In some cases, a user may try to get the link for a chat room, but if such is not set by an operator - it would say "not link available" and not auto create it.
    public static let noChatLinkAvailable = Strings.tr("Localizable", "No chat link available.", fallback: "No chat link available.")
    /// Photo Explorer Screen: No documents in the account
    public static let noDocumentsFound = Strings.tr("Localizable", "No documents found", fallback: "No documents found")
    /// Label to show that an SDK operation has been complete successfully.
    public static let noError = Strings.tr("Localizable", "No error", fallback: "No error")
    /// Text describing that there is not any node marked as favourite
    public static let noFavourites = Strings.tr("Localizable", "No Favourites", fallback: "No favourites")
    /// Empty Gifs section
    public static let noGIFsFound = Strings.tr("Localizable", "No GIFs found", fallback: "No GIFs found")
    /// There are no notifications to display.
    public static let noNotifications = Strings.tr("Localizable", "No notifications", fallback: "No notifications")
    /// Used in Photos app browser. Shown when there are no photos or videos in the Photos app.
    public static let noPhotosOrVideos = Strings.tr("Localizable", "No Photos or Videos", fallback: "No photos or videos")
    /// Label to indicate not to use any proxy. String as short as possible.
    public static let noProxy = Strings.tr("Localizable", "No proxy", fallback: "No proxy")
    /// Title for empty state view of "Links" in Shared Items.
    public static let noPublicLinks = Strings.tr("Localizable", "No Public Links", fallback: "No public links")
    /// Message shown when the user has not recent activity in their account.
    public static let noRecentActivity = Strings.tr("Localizable", "No recent activity", fallback: "No recent activity")
    /// Title shown when there are no shared files
    public static let noSharedFiles = Strings.tr("Localizable", "No Shared Files", fallback: "No shared files")
    /// Video Explorer Screen: No audio files in the account
    public static let noVideosFound = Strings.tr("Localizable", "No videos found", fallback: "No videos found")
    /// Title of empty state view for archived chats.
    public static let noArchivedChats = Strings.tr("Localizable", "noArchivedChats", fallback: "No archived chats or meetings")
    /// Error message shown when there's no camera available on the device
    public static let noCamera = Strings.tr("Localizable", "noCamera", fallback: "No camera available")
    /// Information if there are no history messages in current chat conversation
    public static let noConversationHistory = Strings.tr("Localizable", "noConversationHistory", fallback: "No conversation history")
    /// Empty Conversations section
    public static let noConversations = Strings.tr("Localizable", "noConversations", fallback: "No conversations")
    /// Title shown inside an alert if you don't have enough space on your device to download something
    public static let nodeTooBig = Strings.tr("Localizable", "nodeTooBig", fallback: "You need to free some space on your device")
    /// Text shown when you want to send feedback of the app and you don't have an email account set up on your device
    public static let noEmailAccountConfigured = Strings.tr("Localizable", "noEmailAccountConfigured", fallback: "No email account set up on your device")
    /// Title shown when there's no incoming Shared Items
    public static let noIncomingSharedItemsEmptyStateText = Strings.tr("Localizable", "noIncomingSharedItemsEmptyState_text", fallback: "No incoming shared folders")
    /// Text shown on the app when you don't have connection to the internet or when you have lost it
    public static let noInternetConnection = Strings.tr("Localizable", "noInternetConnection", fallback: "No Internet connection")
    /// Add contacts and share dialog error message when user try to add your own email address
    public static let noNeedToAddYourOwnEmailAddress = Strings.tr("Localizable", "noNeedToAddYourOwnEmailAddress", fallback: "There’s no need to add your own email address")
    /// Title shown when there's no outgoing Shared Items
    public static let noOutgoingSharedItemsEmptyStateText = Strings.tr("Localizable", "noOutgoingSharedItemsEmptyState_text", fallback: "No outgoing shared folders")
    /// Title shown when there's no pending contact requests
    public static let noRequestPending = Strings.tr("Localizable", "noRequestPending", fallback: "No pending requests")
    /// Title shown when you make a search and there is 'No Results'
    public static let noResults = Strings.tr("Localizable", "noResults", fallback: "No results")
    /// Label shown when current account does not have enough quota to complete the operation
    public static let notEnoughQuota = Strings.tr("Localizable", "Not enough quota", fallback: "Not enough quota")
    /// Label to show that an error related with a resource Not found occurs during a SDK operation.
    public static let notFound = Strings.tr("Localizable", "Not found", fallback: "Not found")
    /// 
    public static let notifications = Strings.tr("Localizable", "notifications", fallback: "Notifications")
    /// Chat Notifications DND: Option that does not deactivate DND automatically
    public static let notificationsMuted = Strings.tr("Localizable", "Notifications muted", fallback: "Notifications muted")
    /// Chat Notifications DND: Remaining time left if until today
    public static func notificationsWillBeSilencedUntil(_ p1: Any) -> String {
      return Strings.tr("Localizable", "Notifications will be silenced until %@", String(describing: p1), fallback: "Notifications will be muted until %@")
    }
    /// Chat Notifications DND: Remaining time left if until tomorrow
    public static func notificationsWillBeSilencedUntilTomorrow(_ p1: Any) -> String {
      return Strings.tr("Localizable", "Notifications will be silenced until tomorrow, %@", String(describing: p1), fallback: "Notifications will be muted until tomorrow, %@")
    }
    /// Text indicating to the user that some action will be postpone. E.g. used for 'rich previews' and management of disk storage.
    public static let notNow = Strings.tr("Localizable", "notNow", fallback: "Not now")
    /// Location Usage Description. In order to protect user's privacy, Apple requires a specific string explaining why location will be accessed.
    public static let nsLocationWhenInUseUsageDescription = Strings.tr("Localizable", "NSLocationWhenInUseUsageDescription", fallback: "MEGA accesses your location when you share it with your contacts in chat.")
    /// Users previewing a public chat
    public static let observers = Strings.tr("Localizable", "Observers", fallback: "Observers")
    /// State shown to if something is enabled or disabled on Settings main tab. For example: "Passcode Off"
    public static let off = Strings.tr("Localizable", "off", fallback: "Off")
    /// Title of the Offline section
    public static let offline = Strings.tr("Localizable", "offline", fallback: "Offline")
    /// Title shown when the Offline section is empty, when you don't have download any files. Keep the upper.
    public static let offlineEmptyStateTitle = Strings.tr("Localizable", "offlineEmptyState_title", fallback: "No files saved for Offline")
    /// Button title to accept something
    public static let ok = Strings.tr("Localizable", "ok", fallback: "OK")
    /// Error message shown when the users tryes to change his/her email and writes the current one as the new one.
    public static let oldAndNewEmailMatch = Strings.tr("Localizable", "oldAndNewEmailMatch", fallback: "The new and the old email must not match")
    /// Sort by option (6/6). This one order the files by its modification date, older first
    public static let oldest = Strings.tr("Localizable", "oldest", fallback: "Oldest")
    /// State shown to if something is enabled or disabled on Settings main tab. For example: "Passcode On"
    public static let on = Strings.tr("Localizable", "on", fallback: "On")
    /// Used within the `Retention History` dropdown -- available option for the time range selection.
    public static let oneDay = Strings.tr("Localizable", "One Day", fallback: "One day")
    /// Used within the `Retention History` dropdown -- available option for the time range selection.
    public static let oneMonth = Strings.tr("Localizable", "One Month", fallback: "One month")
    /// Used within the `Retention History` dropdown -- available option for the time range selection.
    public static let oneWeek = Strings.tr("Localizable", "One Week", fallback: "One week")
    /// 
    public static let oneContact = Strings.tr("Localizable", "oneContact", fallback: "1 contact")
    /// Subtitle shown on folders that gives you information about its content. This case "{1} file"
    public static func oneFile(_ p1: Int) -> String {
      return Strings.tr("Localizable", "oneFile", p1, fallback: "%d file")
    }
    /// Subtitle shown on the Contacts section under the name of the contact you have shared one folder with
    public static let oneFolderShared = Strings.tr("Localizable", "oneFolderShared", fallback: "1 folder")
    /// Title shown on the Camera Uploads section when the edit mode is enabled and you have selected one photo
    public static func oneItemSelected(_ p1: Int) -> String {
      return Strings.tr("Localizable", "oneItemSelected", p1, fallback: "%lu item selected")
    }
    /// Text to inform the user there is an active call and is not participating
    public static let ongoingCall = Strings.tr("Localizable", "Ongoing Call", fallback: "Ongoing call")
    /// 
    public static let online = Strings.tr("Localizable", "online", fallback: "Online")
    /// Footer description when upload videos for Live Photos is disabled
    public static let onlyThePhotoInEachLivePhotoWillBeUploaded = Strings.tr("Localizable", "Only the photo in each Live Photo will be uploaded.", fallback: "Only the photo version of each Live Photo will be uploaded.")
    /// Footer description when upload all burst photos is disabled
    public static let onlyTheRepresentativePhotosFromYourBurstPhotoSequencesWillBeUploaded = Strings.tr("Localizable", "Only the representative photos from your burst photo sequences will be uploaded.", fallback: "Only favourite photos from your burst photo sequences will be uploaded.")
    /// "Title header that refers to where do you do the action 'Empty Rubbish Bin' inside 'Settings' -> 'Advanced' section"
    public static let onMEGA = Strings.tr("Localizable", "onMEGA", fallback: "On MEGA")
    /// Title header that refers to where do you do the actions 'Clear Offlines files' and 'Clear cache' inside 'Settings' -> 'Advanced' section"
    public static let onYourDevice = Strings.tr("Localizable", "onYourDevice", fallback: "On your device")
    /// Text indicating the user to open the device settings for MEGA
    public static let openSettings = Strings.tr("Localizable", "Open Settings", fallback: "Open Settings")
    /// Button title to allow the user open the default browser
    public static let openBrowser = Strings.tr("Localizable", "openBrowser", fallback: "Open browser")
    /// Button title to trigger the action of opening the file without downloading or opening it.
    public static let openButton = Strings.tr("Localizable", "openButton", fallback: "Open")
    /// Title shown under the action that allows you to open a file in another app
    public static let openIn = Strings.tr("Localizable", "openIn", fallback: "Open in…")
    /// Text shown when you try to use a MEGA extension in iOS and you aren't logged
    public static let openMEGAAndSignInToContinue = Strings.tr("Localizable", "openMEGAAndSignInToContinue", fallback: "Open MEGA and sign in to continue")
    /// Header to explain that 'Upload videos', 'Use cellular connection' and 'Only when charging' are options of the Camera Uploads
    public static let options = Strings.tr("Localizable", "options", fallback: "Options")
    /// Description text about options when exporting links for several nodes
    public static let optionsSuchAsSendDecryptionKeySeparatelySetExpiryDateOrPasswordsAreOnlyAvailableForSingleItems = Strings.tr("Localizable", "Options such as Send Decryption Key Separately, Set Expiry Date or Passwords are only available for single items.", fallback: "Options such as Send decryption key separately, Set expiry date or Set password are only available for single items.")
    /// A user can mark a folder or file with its own colour, in this case "Orange
    public static let orange = Strings.tr("Localizable", "Orange", fallback: "Orange")
    /// Label to show that an error of Out of range occurs during a SDK operation.
    public static let outOfRange = Strings.tr("Localizable", "Out of range", fallback: "Out of range")
    /// Title of the "Outgoing" Shared Items.
    public static let outgoing = Strings.tr("Localizable", "outgoing", fallback: "Outgoing")
    /// Label to show that an error related with an over quota occurs during a SDK operation.
    public static let overQuota = Strings.tr("Localizable", "Over quota", fallback: "Over quota")
    /// Text shown when switching from thumbnail view to page view when previewing a document, for example a PDF.
    public static let pageView = Strings.tr("Localizable", "Page View", fallback: "Page view")
    /// Headline for parking an account (basically restarting from scratch)
    public static let parkAccount = Strings.tr("Localizable", "parkAccount", fallback: "Park account")
    /// Label to describe the section where you can see the participants of a group chat
    public static let participants = Strings.tr("Localizable", "participants", fallback: "Participants")
    /// 
    public static let passcode = Strings.tr("Localizable", "passcode", fallback: "Passcode")
    /// Button text to change the passcode type.
    public static let passcodeOptions = Strings.tr("Localizable", "Passcode Options", fallback: "Passcode options")
    /// Message shown when the password has been copied to the Clipboard
    public static let passwordCopiedToClipboard = Strings.tr("Localizable", "Password Copied to Clipboard", fallback: "Password copied to clipboard")
    /// Text for options in Get Link View to activate password protection
    public static let passwordProtection = Strings.tr("Localizable", "Password Protection", fallback: "Password protection")
    /// Title for feature Password Reminder
    public static let passwordReminder = Strings.tr("Localizable", "Password Reminder", fallback: "Password reminder")
    /// Used as a message in the "Password reminder" dialog that is shown when the user enters his password, clicks confirm and his password is correct.
    public static let passwordAccepted = Strings.tr("Localizable", "passwordAccepted", fallback: "Password accepted")
    /// Success message shown when the password has been changed
    public static let passwordChanged = Strings.tr("Localizable", "passwordChanged", fallback: "Your password has been changed.")
    /// 
    public static let passwordGood = Strings.tr("Localizable", "passwordGood", fallback: "This password will withstand most typical brute-force attacks. Please ensure that you will remember it.")
    /// Message shown when the user enters a wrong password
    public static let passwordInvalidFormat = Strings.tr("Localizable", "passwordInvalidFormat", fallback: "Enter a valid password")
    /// 
    public static let passwordMedium = Strings.tr("Localizable", "passwordMedium", fallback: "Your password is good enough to proceed, but it is recommended to strengthen your password further.")
    /// Hint text to suggest that the user has to write his password
    public static let passwordPlaceholder = Strings.tr("Localizable", "passwordPlaceholder", fallback: "Password")
    /// Headline of the password reset recovery procedure
    public static let passwordReset = Strings.tr("Localizable", "passwordReset", fallback: "Password reset")
    /// Error text shown when you have not written the same password
    public static let passwordsDoNotMatch = Strings.tr("Localizable", "passwordsDoNotMatch", fallback: "Passwords do not match")
    /// Label displayed during checking the strength of the password introduced. Represents Medium security
    public static let passwordStrengthMedium = Strings.tr("Localizable", "PasswordStrengthMedium", fallback: "Medium")
    /// 
    public static let passwordStrong = Strings.tr("Localizable", "passwordStrong", fallback: "This password will withstand most sophisticated brute-force attacks. Please ensure that you will remember it.")
    /// 
    public static let passwordVeryWeakOrWeak = Strings.tr("Localizable", "passwordVeryWeakOrWeak", fallback: "Your password is easily guessed. Try making your password longer. Combine uppercase and lowercase letters. Add special characters. Do not use names or dictionary words.")
    /// Error text shown when you introduce a wrong password on the confirmation proccess
    public static let passwordWrong = Strings.tr("Localizable", "passwordWrong", fallback: "Wrong password")
    /// tool bar title used in transfer widget, allow user to resume all transfers in the list
    public static let pauseAll = Strings.tr("Localizable", "Pause All", fallback: "Pause all")
    /// A label to indicate a paused state for a transfer item (upload/download).
    public static let paused = Strings.tr("Localizable", "paused", fallback: "Paused")
    /// The header of a notification related to payments
    public static let paymentInfo = Strings.tr("Localizable", "Payment info", fallback: "Payment info")
    /// Business expired account Overdue payment page header.
    public static let paymentOverdue = Strings.tr("Localizable", "Payment overdue", fallback: "Payment overdue")
    /// Label shown when a contact request is pending
    public static let pending = Strings.tr("Localizable", "pending", fallback: "Pending")
    /// Text explaining users how the chat links work.
    public static let peopleCanJoinYourGroupByUsingThisLink = Strings.tr("Localizable", "People can join your group by using this link.", fallback: "People can join your group by using this link.")
    /// Per folder configuration. For example the options for 'Sorting Preference' in the app are: 'Per Folder' and 'Same for All'.
    public static let perFolder = Strings.tr("Localizable", "Per Folder", fallback: "Per folder")
    /// Message to notify user the file version will be permanently removed
    public static let permanentlyRemoved = Strings.tr("Localizable", "permanentlyRemoved", fallback: "It will be permanently removed")
    /// Error message shown when you are trying to do an action with a file or folder and you don't have the necessary permissions
    public static let permissionMessage = Strings.tr("Localizable", "permissionMessage", fallback: "Check your permissions on this folder")
    /// Title of the view that shows the kind of permissions (Read Only, Read & Write or Full Access) that you can give to a shared folder
    public static let permissions = Strings.tr("Localizable", "permissions", fallback: "Permissions")
    /// Message shown when you have changed the permissions of a shared folder
    public static let permissionsChanged = Strings.tr("Localizable", "permissionsChanged", fallback: "Permissions changed")
    /// Error title shown when you are trying to do an action with a file or folder and you don't have the necessary permissions
    public static let permissionTitle = Strings.tr("Localizable", "permissionTitle", fallback: "Permission error")
    /// Text related to verified phone number. Used as title or cell description.
    public static let phoneNumber = Strings.tr("Localizable", "Phone Number", fallback: "Phone Number")
    /// Alert message to explain that the MEGA app needs permission to access your device photos
    public static let photoLibraryPermissions = Strings.tr("Localizable", "photoLibraryPermissions", fallback: "Please give MEGA permission to access your Photos in Settings")
    /// Footer text for Camera Upload switch section when photos and videos upload is enabled
    public static let photosAndVideosWillBeUploadedToCameraUploadsFolder = Strings.tr("Localizable", "Photos and videos will be uploaded to Camera Uploads folder.", fallback: "Photos and videos will be uploaded to the Camera uploads folder.")
    /// Message shown the pending video files when photos uploaded and video upload is not enabled. Plural.
    public static func photosUploadedVideoUploadsAreOffLuVideosNotUploaded(_ p1: Int) -> String {
      return Strings.tr("Localizable", "Photos uploaded, video uploads are off, %lu videos not uploaded", p1, fallback: "Photos uploaded, video uploads are off; %lu videos not uploaded")
    }
    /// Message shown the pending video file when photos uploaded and video upload is not enabled. Singular.
    public static let photosUploadedVideoUploadsAreOff1VideoNotUploaded = Strings.tr("Localizable", "Photos uploaded, video uploads are off, 1 video not uploaded", fallback: "Photos uploaded, video uploads are off; 1 video not uploaded")
    /// Footer text for Camera Upload switch section when only photos upload is enabled
    public static let photosWillBeUploadedToCameraUploadsFolder = Strings.tr("Localizable", "Photos will be uploaded to Camera Uploads folder.", fallback: "Photos will be uploaded to the Camera uploads folder.")
    /// Text shown in location-type messages
    public static let pinnedLocation = Strings.tr("Localizable", "Pinned Location", fallback: "Pinned location")
    /// Title of the section about the plan in the storage tab in My Account Section
    public static let plan = Strings.tr("Localizable", "Plan", fallback: "Plan")
    /// Section header of Audio Player playlist that contains playing track
    public static let playing = Strings.tr("Localizable", "Playing", fallback: "Playing")
    /// Title of a dialog in which we request access to a specific permission, like the Location Services
    public static let pleaseAllowAccess = Strings.tr("Localizable", "Please allow access", fallback: "Please allow access")
    /// Error message if user click next button without enter a valid phone number
    public static let pleaseEnterAValidPhoneNumber = Strings.tr("Localizable", "Please enter a valid phone number", fallback: "Please supply a valid phone number.")
    /// Detailed explanation of why the user should give permission to access to the photos
    public static let pleaseGiveTheMEGAAppPermissionToAccessPhotosToSharePhotosAndVideos = Strings.tr("Localizable", "Please give the MEGA App permission to access Photos to share photos and videos.", fallback: "Please give MEGA permission to access Photos to share photos and videos.")
    /// Label tell user to enter received txt to below input boxes
    public static let pleaseTypeTheVerificationCodeSentTo = Strings.tr("Localizable", "Please type the verification code sent to", fallback: "Please enter the verification code sent to")
    /// A message on the Verify Login page telling the user to enter their 2FA code.
    public static let pleaseEnterTheSixDigitCode = Strings.tr("Localizable", "pleaseEnterTheSixDigitCode", fallback: "Please enter the 6-digit code generated by your authenticator app.")
    /// A message shown to explain that the user has to input (type or paste) their recovery key to continue with the reset password process.
    public static let pleaseEnterYourRecoveryKey = Strings.tr("Localizable", "pleaseEnterYourRecoveryKey", fallback: "Please enter your Recovery key")
    /// Alert title shown when you need to log in to continue with the action you want to do
    public static let pleaseLogInToYourAccount = Strings.tr("Localizable", "pleaseLogInToYourAccount", fallback: "Please log in to your account.")
    /// A warning message on the Backup Recovery Key dialog to tell the user to backup their Recovery Key to their local computer.
    public static let pleaseSaveYourRecoveryKey = Strings.tr("Localizable", "pleaseSaveYourRecoveryKey", fallback: "Please save your Recovery key in a safe location")
    /// 
    public static let pleaseStrengthenYourPassword = Strings.tr("Localizable", "pleaseStrengthenYourPassword", fallback: "Please strengthen your password.")
    /// Message body of the email that appears when the users tap on "Send feedback"
    public static let pleaseWriteYourFeedback = Strings.tr("Localizable", "pleaseWriteYourFeedback", fallback: "Please write your feedback here:")
    /// Label to indicate a server port to be used. String as short as possible.
    public static let port = Strings.tr("Localizable", "Port", fallback: "Port")
    /// Label for the status of a transfer when is being preparing - (String as short as possible).
    public static let preparing = Strings.tr("Localizable", "preparing...", fallback: "Preparing…")
    /// Title to preview document
    public static let previewContent = Strings.tr("Localizable", "previewContent", fallback: "Preview content")
    /// A button label which opens a dialog to display the full version history of the selected file.
    public static let previousVersions = Strings.tr("Localizable", "previousVersions", fallback: "Previous versions")
    /// Title of one of the Settings sections where you can see the MEGA's 'Privacy Policy'
    public static let privacyPolicyLabel = Strings.tr("Localizable", "privacyPolicyLabel", fallback: "Privacy Policy")
    /// The new LITE payment plan. This means it is a light or lightweight payment plan compared to the full / heavyweight plans with lots of bandwidth and storage (PRO I, PRO II, PRO III).
    public static let proLite = Strings.tr("Localizable", "Pro Lite", fallback: "Pro Lite")
    /// A title for a notification saying the user’s pricing plan will expire soon.
    public static let proMembershipPlanExpiringSoon = Strings.tr("Localizable", "PRO membership plan expiring soon", fallback: "Pro membership plan expiring soon")
    /// Title to confirm that you want to logout
    public static let proceedToLogout = Strings.tr("Localizable", "proceedToLogout", fallback: "Proceed to log out")
    /// Error message shown when the selected product doesn't exist
    public static func productNotFound(_ p1: Any) -> String {
      return Strings.tr("Localizable", "productNotFound", String(describing: p1), fallback: "Product %@ is not found, please contact ios@mega.nz")
    }
    /// Price asociated with the MEGA PRO account level you can subscribe
    public static func productPricePerMonth(_ p1: Any) -> String {
      return Strings.tr("Localizable", "productPricePerMonth", String(describing: p1), fallback: "%@ per month")
    }
    /// Label for any 'Profile' button, link, text, title, etc. - (String as short as possible).
    public static let profile = Strings.tr("Localizable", "profile", fallback: "Profile")
    /// An alert dialog for the Get Link feature
    public static let proOnly = Strings.tr("Localizable", "proOnly", fallback: "(Pro only)")
    /// Title of the Proxy section under Settings
    public static let proxy = Strings.tr("Localizable", "Proxy", fallback: "Proxy")
    /// Label to indicate if the proxy used requires a password. String as short as possible.
    public static let proxyServerRequiresAPassword = Strings.tr("Localizable", "Proxy server requires a password", fallback: "Proxy server requires a password")
    /// Label to indicate the dialog of Proxy Settings. Keep capital letters.
    public static let proxySettings = Strings.tr("Localizable", "Proxy Settings", fallback: "Proxy settings")
    /// Alert message shown when a purchase was restored succesfully
    public static let purchaseRestoreMessage = Strings.tr("Localizable", "purchaseRestore_message", fallback: "Your purchase was restored")
    /// A user can mark a folder or file with its own colour, in this case “Purple”.
    public static let purple = Strings.tr("Localizable", "Purple", fallback: "Purple")
    /// QR Code label, used in Settings as title. String as short as possible
    public static let qrCode = Strings.tr("Localizable", "qrCode", fallback: "QR code")
    /// Quality title, used in changing the export quality of scaned doc
    public static let quality = Strings.tr("Localizable", "Quality", fallback: "Quality")
    /// Text shown under the title 'Video quality' that explains what it means
    public static let qualityOfVideosUploadedToAChat = Strings.tr("Localizable", "qualityOfVideosUploadedToAChat", fallback: "Quality of videos uploaded to a chat")
    /// Text shown when one file has been selected to be downloaded but it's on the queue to be downloaded, it's pending for download
    public static let queued = Strings.tr("Localizable", "queued", fallback: "Queued")
    /// Title for the QuickAccess widget
    public static let quickAccess = Strings.tr("Localizable", "Quick Access", fallback: "Quick access")
    /// Text description for the Favourites QuickAccess widget
    public static let quicklyAccessFilesOnFavouritesSection = Strings.tr("Localizable", "Quickly access files on Favourites section", fallback: "Quickly access files from your Favourites section")
    /// Text description for the Offline QuickAccess widget
    public static let quicklyAccessFilesOnOfflineSection = Strings.tr("Localizable", "Quickly access files on Offline section", fallback: "Quickly access files from your Offline section")
    /// Text description for the Recents QuickAccess widget
    public static let quicklyAccessFilesOnRecentsSection = Strings.tr("Localizable", "Quickly access files on Recents section", fallback: "Quickly access files from your Recents section")
    /// Text description for the QuickAccess widget
    public static let quicklyAccessFilesOnRecentsFavouritesOrOfflineSection = Strings.tr("Localizable", "Quickly access files on Recents, Favourites, or Offline section", fallback: "Quickly access files on Recents, Favourites, or the Offline section")
    /// Label to show that the rate limit has been reached during a SDK operation.
    public static let rateLimitExceeded = Strings.tr("Localizable", "Rate limit exceeded", fallback: "Rate limit exceeded")
    /// Title to rate the app
    public static let rateUsLabel = Strings.tr("Localizable", "rateUsLabel", fallback: "Rate us")
    /// Label to show that an error related with an read error occurs during a SDK operation.
    public static let readError = Strings.tr("Localizable", "Read error", fallback: "Read error")
    /// Permissions given to the user you share your folder with
    public static let readAndWrite = Strings.tr("Localizable", "readAndWrite", fallback: "Read and write")
    /// Permissions given to the user you share your folder with
    public static let readOnly = Strings.tr("Localizable", "readOnly", fallback: "Read-only")
    /// Title of one of the filters in 'Contacts requests' section. If 'Received' is selected, it will only show the requests which have been recieved.
    public static let received = Strings.tr("Localizable", "received", fallback: "Received")
    /// Label for any ‘Recently Added’ button, link, text, title, etc. On iOS is used on a section that shows the 'Recently Added' contacts
    public static let recentlyAdded = Strings.tr("Localizable", "Recently Added", fallback: "Recently added")
    /// Title for the recents section.
    public static let recents = Strings.tr("Localizable", "Recents", fallback: "Recents")
    /// Title shown when the user lost the connection in a call, and the app will try to reconnect the user again.
    public static let reconnecting = Strings.tr("Localizable", "Reconnecting...", fallback: "Reconnecting…")
    /// Label indicating that a voice clip is being recorded. String as short as possible.
    public static let recording = Strings.tr("Localizable", "Recording...", fallback: "Recording…")
    /// Label for any 'Recovery Key' button, link, text, title, etc. Preserve uppercase - (String as short as possible). The Recovery Key is the new name for the account 'Master Key', and can unlock (recover) the account if the user forgets their password.
    public static let recoveryKey = Strings.tr("Localizable", "recoveryKey", fallback: "Recovery key")
    /// Message of the dialog displayed when copy the user's Recovery Key to the clipboard to be saved or exported.
    public static let recoveryKeyCopiedToClipboard = Strings.tr("Localizable", "recoveryKeyCopiedToClipboard", fallback: "Recovery key copied to clipboard. Save it to a safe place where you can easily access later.")
    /// Message shown during forgot your password process if the link to reset password has expired
    public static let recoveryLinkHasExpired = Strings.tr("Localizable", "recoveryLinkHasExpired", fallback: "This recovery link has expired, please try again.")
    /// A user can mark a folder or file with its own colour, in this case “Red”.
    public static let red = Strings.tr("Localizable", "Red", fallback: "Red")
    /// SDK error returned when an operation is rejected due to fraud protection
    public static let rejectedByFraudProtection = Strings.tr("Localizable", "Rejected by fraud protection", fallback: "Rejected by fraud protection")
    /// A reminder notification to remind the user to respond to the contact request.
    public static let reminderYouHaveAContactRequest = Strings.tr("Localizable", "Reminder: You have a contact request", fallback: "Reminder: you have a contact request")
    /// Text that describes why the user should test his/her password before logging out
    public static let remindPasswordLogoutText = Strings.tr("Localizable", "remindPasswordLogoutText", fallback: "Before logging out we recommend you export your Recovery key to a safe place. Note that you’re not able to reset your password if you forget it.")
    /// Text that describes why the user should test his/her password
    public static let remindPasswordText = Strings.tr("Localizable", "remindPasswordText", fallback: "Due to MEGA’s encryption technology you are unable to reset your password without data loss. Please make sure you remember your password.")
    /// Used as a title in the "Password reminder" dialog, that pop ups to ensure that the user had exported his recovery key OR still remembers his password.
    public static let remindPasswordTitle = Strings.tr("Localizable", "remindPasswordTitle", fallback: "Do you remember your password?")
    /// Title for the action that allows to remove a file or folder
    public static let remove = Strings.tr("Localizable", "remove", fallback: "Remove")
    /// Context menu item. Allows user to delete file/folder from favourites
    public static let removeFavourite = Strings.tr("Localizable", "Remove Favourite", fallback: "Remove favourite")
    /// A rubbish bin scheduler setting which allows removing old files from the rubbish bin automatically. E.g. Remove files older than 15 days.
    public static let removeFilesOlderThan = Strings.tr("Localizable", "Remove files older than", fallback: "Remove files older than")
    /// Option shown on the action sheet where you can choose or change the color label of a file or folder. The 'Remove Label' only appears if you have previously selected a label
    public static let removeLabel = Strings.tr("Localizable", "Remove Label", fallback: "Remove label")
    /// Edit nickname screen: Remove nickname button title
    public static let removeNickname = Strings.tr("Localizable", "Remove Nickname", fallback: "Remove nickname")
    /// Text to indicate the user to remove the password of a link
    public static let removePassword = Strings.tr("Localizable", "Remove Password", fallback: "Remove password")
    /// Title for action to remove the registered phone number.
    public static let removePhoneNumber = Strings.tr("Localizable", "Remove Phone Number", fallback: "Remove phone number")
    /// Button to remove some photo, e.g. avatar photo. Try to keep the text short (as in English)
    public static let removePhoto = Strings.tr("Localizable", "Remove Photo", fallback: "Remove photo")
    /// The text in the button to remove all contacts to a shared folder on one click
    public static let removeShare = Strings.tr("Localizable", "Remove Share", fallback: "Remove share")
    /// Notification popup. Notification for multiple removed items from a share. Please keep [X] as it will be replaced at runtime with the number of removed items.
    public static let removedXItemsFromAShare = Strings.tr("Localizable", "Removed [X] items from a share", fallback: "Removed [X] items from a share")
    /// Notification when on client side when owner of a shared folder removes folder/file from it.
    public static let removedItemFromSharedFolder = Strings.tr("Localizable", "Removed item from shared folder", fallback: "Removed item from shared folder")
    /// Success message shown when the selected contact has been removed. 'Contact {Name of contact} removed'
    public static func removedContact(_ p1: Any) -> String {
      return Strings.tr("Localizable", "removedContact", String(describing: p1), fallback: "Contact %@ removed")
    }
    /// Alert message shown on the Rubbish Bin when you want to remove "1 file and {1+} folders"
    public static func removeFileFoldersToRubbishBinMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "removeFileFoldersToRubbishBinMessage", p1, fallback: "You are about to permanently remove 1 file and %d folders. Would you like to proceed? (You cannot undo this action.)")
    }
    /// Alert message shown on the Rubbish Bin when you want to remove "1 file and 1 folder"
    public static let removeFileFolderToRubbishBinMessage = Strings.tr("Localizable", "removeFileFolderToRubbishBinMessage", fallback: "You are about to permanently remove 1 file and 1 folder. Would you like to proceed? (You cannot undo this action.)")
    /// Alert message shown on the Rubbish Bin when you want to remove "[A] = {1+} files and [B] = {1+} folders
    public static let removeFilesFoldersToRubbishBinMessage = Strings.tr("Localizable", "removeFilesFoldersToRubbishBinMessage", fallback: "You are about to permanently remove [A] files and [B] folders. Would you like to proceed? (You cannot undo this action.)")
    /// Alert message shown on the Rubbish Bin when you want to remove "{1+} files and 1 folder"
    public static func removeFilesFolderToRubbishBinMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "removeFilesFolderToRubbishBinMessage", p1, fallback: "You are about to permanently remove %d files and 1 folder. Would you like to proceed? (You cannot undo this action.)")
    }
    /// Alert message shown on the Rubbish Bin when you want to remove "{1+} files"
    public static func removeFilesToRubbishBinMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "removeFilesToRubbishBinMessage", p1, fallback: "You are about to permanently remove %d files. Would you like to proceed? (You cannot undo this action.)")
    }
    /// Alert message shown on the Rubbish Bin when you want to remove '1 file'
    public static let removeFileToRubbishBinMessage = Strings.tr("Localizable", "removeFileToRubbishBinMessage", fallback: "You are about to permanently remove 1 file. Would you like to proceed? (You cannot undo this action.)")
    /// Alert message shown on the Rubbish Bin when you want to remove "{1+} folders"
    public static func removeFoldersToRubbishBinMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "removeFoldersToRubbishBinMessage", p1, fallback: "You are about to permanently remove %d folders. Would you like to proceed? (You cannot undo this action.)")
    }
    /// Alert message shown on the Rubbish Bin when you want to remove '1 folder'
    public static let removeFolderToRubbishBinMessage = Strings.tr("Localizable", "removeFolderToRubbishBinMessage", fallback: "You are about to permanently remove 1 folder. Would you like to proceed? (You cannot undo this action.)")
    /// Alert message shown when the user remove one item from the Offline section
    public static let removeItemFromOffline = Strings.tr("Localizable", "removeItemFromOffline", fallback: "Are you sure you want to delete this item from Offline?")
    /// Alert message shown when the user remove various items from the Offline section
    public static let removeItemsFromOffline = Strings.tr("Localizable", "removeItemsFromOffline", fallback: "Are you sure you want to delete these items from Offline?")
    /// Alert message shown on the Shared Items section when you want to remove %d shares
    public static func removeMultipleSharesMultipleContactsMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "removeMultipleSharesMultipleContactsMessage", p1, fallback: "Are you sure you want to remove these shares? (Shared with %d contacts)")
    }
    /// Alert confirmation message shown when you want to remove more than one contact from your contacts list
    public static func removeMultipleUsersMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "removeMultipleUsersMessage", p1, fallback: "Are you sure you want to remove %d users from your contact list?")
    }
    /// Alert title shown on the Rubbish Bin when you want to remove some files and folders of your MEGA account
    public static let removeNodeFromRubbishBinTitle = Strings.tr("Localizable", "removeNodeFromRubbishBinTitle", fallback: "Confirm removal")
    /// Alert message shown on the Shared Items section when you want to remove 1 share
    public static func removeOneShareMultipleContactsMessage(_ p1: Int) -> String {
      return Strings.tr("Localizable", "removeOneShareMultipleContactsMessage", p1, fallback: "Are you sure you want to remove this share? (Shared with %d contacts)")
    }
    /// Alert message shown on the Shared Items section when you want to remove 1 share
    public static let removeOneShareOneContactMessage = Strings.tr("Localizable", "removeOneShareOneContactMessage", fallback: "Are you sure you want to remove this share? (Shared with 1 contact)")
    /// A button title which removes a participant from a chat.
    public static let removeParticipant = Strings.tr("Localizable", "removeParticipant", fallback: "Remove participant")
    /// Once a preview is generated for a message which contains URLs, the user can remove it. Same button is also shown during loading of the preview - and would cancel the loading (text of the button is the same in both cases).
    public static let removePreview = Strings.tr("Localizable", "removePreview", fallback: "Remove preview")
    /// Alert title shown on the Shared Items section when you want to remove 1 share
    public static let removeSharing = Strings.tr("Localizable", "removeSharing", fallback: "Remove sharing")
    /// Alert title shown when you want to remove one or more contacts
    public static let removeUserTitle = Strings.tr("Localizable", "removeUserTitle", fallback: "Remove contact")
    /// Title for the action that allows you to rename a file or folder
    public static let rename = Strings.tr("Localizable", "rename", fallback: "Rename")
    /// Alert title to ask if user want to rename the file. %@ is a place holder.
    public static func renameFileAlertTitle(_ p1: Any) -> String {
      return Strings.tr("Localizable", "rename_file_alert_title", String(describing: p1), fallback: "Rename file %@?")
    }
    /// The title of a menu button which allows users to rename a group chat.
    public static let renameGroup = Strings.tr("Localizable", "renameGroup", fallback: "Rename group")
    /// Hint text to suggest that the user have to write the new name for the file or folder
    public static let renameNodeMessage = Strings.tr("Localizable", "renameNodeMessage", fallback: "Enter the new name")
    /// Label for the ‘Renews on’ text into the my account page, indicating the renewal date of a subscription - (String as short as possible).
    public static let renewsOn = Strings.tr("Localizable", "Renews on", fallback: "Renews on")
    /// Title for the action that allows you to replace a file.
    public static let replace = Strings.tr("Localizable", "replace", fallback: "Replace")
    /// Label to show that a request error occurs during a SDK operation.
    public static let requestFailedRetrying = Strings.tr("Localizable", "Request failed, retrying", fallback: "Request failed, retrying")
    /// Success message shown when you acepted a contact request
    public static let requestAccepted = Strings.tr("Localizable", "requestAccepted", fallback: "Request accepted")
    /// Button on the Pro page to request a custom Pro plan because their storage usage is more than the regular plans.
    public static let requestAPlan = Strings.tr("Localizable", "requestAPlan", fallback: "Request a plan")
    /// Success message shown when you Cancelled a contact request
    public static let requestCancelled = Strings.tr("Localizable", "requestCancelled", fallback: "Request cancelled")
    /// Success message shown when you remove a contact request
    public static let requestDeleted = Strings.tr("Localizable", "requestDeleted", fallback: "Request deleted")
    /// Label for any ‘Requests’ button, link, text, title, etc. On iOS is used to go to the Contact request section from Contacts
    public static let requests = Strings.tr("Localizable", "Requests", fallback: "Requests")
    /// Label indicating that the passcode (pin) view will be displayed if the application goes back to foreground after being x time in background. Examples: require passcode immediately, require passcode after 5 minutes.
    public static let requirePasscode = Strings.tr("Localizable", "Require Passcode", fallback: "Require passcode")
    /// A button to resend the email confirmation.
    public static let resend = Strings.tr("Localizable", "resend", fallback: "Resend")
    /// Button to reset the password
    public static let reset = Strings.tr("Localizable", "reset", fallback: "Reset")
    /// Text to indicate the user to reset/change the password of a link
    public static let resetPassword = Strings.tr("Localizable", "Reset Password", fallback: "Reset password")
    /// Action to reset the current valid QR code of the user
    public static let resetQrCode = Strings.tr("Localizable", "resetQrCode", fallback: "Reset QR code")
    /// Footer that explains what would happen if the user resets his/her QR code
    public static let resetQrCodeFooter = Strings.tr("Localizable", "resetQrCodeFooter", fallback: "Previous QR codes will no longer be valid.")
    /// A label for the Restart button to relaunch MEGAsync.
    public static let restart = Strings.tr("Localizable", "restart", fallback: "Restart")
    /// Button title to restore failed purchases
    public static let restore = Strings.tr("Localizable", "restore", fallback: "Restore")
    /// 
    public static let resume = Strings.tr("Localizable", "resume", fallback: "Resume")
    /// tool bar title used in transfer widget, allow user to Pause all transfers in the list
    public static let resumeAll = Strings.tr("Localizable", "Resume All", fallback: "Resume all")
    /// Alert header for asking permission to resume transfers
    public static let resumeTransfers = Strings.tr("Localizable", "Resume Transfers?", fallback: "Resume transfers?")
    /// Button which allows to retry send message in chat conversation.
    public static let retry = Strings.tr("Localizable", "retry", fallback: "Retry")
    /// Label for the state of a transfer when is being retrying - (String as short as possible).
    public static let retrying = Strings.tr("Localizable", "Retrying...", fallback: "Retrying…")
    /// A button label which reverts a certain version of a file to be the current version of the selected file.
    public static let revert = Strings.tr("Localizable", "revert", fallback: "Revert")
    /// After several times (right now set to 3) that the user may had decided to click \"Not now\" (for when being asked if he/she wants a URL preview to be generated for a link, posted in a chat room), we change the \"Not now\" button to \"Never\". If the user clicks it, we ask for one final time - to ensure he wants to not be asked for this anymore and tell him that he can do that in Settings.
    public static let richPreviewsConfirmation = Strings.tr("Localizable", "richPreviewsConfirmation", fallback: "You are disabling rich URL previews permanently. You can re-enable rich URL previews in your settings. Do you want to proceed?")
    /// Used in the \"rich previews\", when the user first tries to send an url - we ask them before we generate previews for that URL, since we need to send them unencrypted to our servers.
    public static let richPreviewsFooter = Strings.tr("Localizable", "richPreviewsFooter", fallback: "Enhance the MEGA Chat experience. URL content will be retrieved without zero-knowledge encryption.")
    /// Title used in settings that enables the generation of link previews in the chat
    public static let richUrlPreviews = Strings.tr("Localizable", "richUrlPreviews", fallback: "Rich URL previews")
    /// title of a field to show the role or position (you can use whichever is best for translation) of the user in business accounts
    public static let role = Strings.tr("Localizable", "Role:", fallback: "Role:")
    /// Title for the Rubbish-Bin Cleaning Scheduler feature
    public static let rubbishBinCleaningScheduler = Strings.tr("Localizable", "Rubbish-Bin Cleaning Scheduler:", fallback: "Rubbish bin emptying scheduler")
    /// Title of one of the Settings sections where you can see your MEGA 'Rubbish Bin'
    public static let rubbishBinLabel = Strings.tr("Localizable", "rubbishBinLabel", fallback: "Rubbish bin")
    /// Same for all configuration. For example the options for 'Sorting Preference' in the app are: 'Per Folder' and 'Same for all Folders'.
    public static let sameForAll = Strings.tr("Localizable", "Same for All", fallback: "Same for all")
    /// Button title to 'Save' the selected option
    public static let save = Strings.tr("Localizable", "save", fallback: "Save")
    /// Footer text shown under the Camera setting to explain the option 'Save in Photos'
    public static let saveACopyOfTheImagesAndVideosTakenFromTheMEGAAppInYourDeviceSMediaLibrary = Strings.tr("Localizable", "Save a copy of the images and videos taken from the MEGA app in your device’s media library.", fallback: "Save a copy of the images and videos taken from the MEGA App in your device’s media library.")
    /// Header to introduce how to deal with HEIC format photos in Camera Uplaod
    public static let saveHeicPhotosAs = Strings.tr("Localizable", "SAVE HEIC PHOTOS AS", fallback: "Save HEIC photos as")
    /// Header to introduce how to deal with HEVC format videos in Camera Uplaod
    public static let saveHevcVideosAs = Strings.tr("Localizable", "SAVE HEVC VIDEOS AS", fallback: "Save HEVC videos as")
    /// Settings section title where you can enable the option to 'Save Images in Photos'
    public static let saveImagesInPhotos = Strings.tr("Localizable", "Save Images in Photos", fallback: "Save images in Photos")
    /// Settings section title where you can enable the option to 'Save in Photos' the images or videos taken from your camera in the MEGA app
    public static let saveInPhotos = Strings.tr("Localizable", "Save in Photos", fallback: "Save in Photos")
    /// Setting title for Doc scan view
    public static let saveSettings = Strings.tr("Localizable", "Save Settings", fallback: "Save settings")
    /// A button label which allows the users save images/videos in the Photos app.
    public static let saveToPhotos = Strings.tr("Localizable", "Save to Photos", fallback: "Save to Photos")
    /// Settings section title where you can enable the option to 'Save Videos in Photos'
    public static let saveVideosInPhotos = Strings.tr("Localizable", "Save Videos in Photos", fallback: "Save videos in Photos")
    /// Footer shown to remenber that if you select a yearly plan yo will save up to 17%
    public static let save17 = Strings.tr("Localizable", "save17", fallback: "Save 16%")
    /// State shown if something is 'Saved' (String as short as possible).
    public static let saved = Strings.tr("Localizable", "saved", fallback: "Saved")
    /// Text shown when a photo or video is saved to Photos app
    public static let savedToPhotos = Strings.tr("Localizable", "Saved to Photos", fallback: "Saved to Photos")
    /// Title shown under the action that allows you to save an image to your camera roll
    public static let saveImage = Strings.tr("Localizable", "saveImage", fallback: "Save image")
    /// Text shown when starting the process to save a photo or video to Photos app
    public static let savingToPhotos = Strings.tr("Localizable", "Saving to Photos…", fallback: "Saving to Photos…")
    /// Menu option from the `Add` section that allows the user to scan document and upload it directly to MEGA.
    public static let scanDocument = Strings.tr("Localizable", "Scan Document", fallback: "Scan document")
    /// Segmented control title for view that allows the user to scan QR codes. String as short as possible.
    public static let scanCode = Strings.tr("Localizable", "scanCode", fallback: "Scan code")
    /// A message on the setup two-factor authentication page on the mobile web client.
    public static let scanOrCopyTheSeed = Strings.tr("Localizable", "scanOrCopyTheSeed", fallback: "Scan or copy the seed to your authenticator app. Be sure to back up this seed to a safe place in case you lose your device.")
    /// Title of the label where the SDK version is shown
    public static let sdkVersion = Strings.tr("Localizable", "sdkVersion", fallback: "MEGA SDK version")
    /// Title of the Spotlight Search section
    public static let search = Strings.tr("Localizable", "Search", fallback: "Search")
    /// This is the placeholder text for GIPHY search
    public static let searchGIPHY = Strings.tr("Localizable", "Search GIPHY", fallback: "Search GIPHY")
    /// Search placeholder text in search bar on home screen
    public static let searchYourFiles = Strings.tr("Localizable", "Search Your Files", fallback: "Search your files")
    /// Description shown in a page of the onboarding screens explaining the encryption paradigm
    public static let securityIsWhyWeExistYourFilesAreSafeWithUsBehindAWellOiledEncryptionMachineWhereOnlyYouCanAccessYourFiles = Strings.tr("Localizable", "Security is why we exist, your files are safe with us behind a well oiled encryption machine where only you can access your files.", fallback: "Security is why we exist, your files are safe with us behind a well oiled encryption machine where only you can access your files.")
    /// Title of one of the Settings sections where you can configure "Security Options" of your MEGA account
    public static let securityOptions = Strings.tr("Localizable", "securityOptions", fallback: "Security options")
    /// Button title to see the available pro plans in MEGA
    public static let seePlans = Strings.tr("Localizable", "seePlans", fallback: "See plans")
    /// Button that allows you to select something (a folder, a message...)
    public static let select = Strings.tr("Localizable", "select", fallback: "Select")
    /// Action button text of folder selection screen for camera uploads
    public static let selectFolder = Strings.tr("Localizable", "Select Folder", fallback: "Select folder")
    /// Text shown to explain how and where you can invite friends
    public static let selectFromPhoneContactsOrEnterMultipleEmailAddresses = Strings.tr("Localizable", "Select from phone contacts or enter multiple email addresses", fallback: "Select from device contacts or enter multiple email addresses.")
    /// Footer text explaining what means choosing a view mode preference 'Per Folder', 'List view' or 'Thumbnail view' in Settings - Appearance - Sorting And View Mode.
    public static let selectViewModeListOrThumbnailOnAPerFolderBasisOrUseTheSameViewModeForAllFolders = Strings.tr("Localizable", "Select view mode (List or Thumbnail) on a per-folder basis, or use the same view mode for all folders.", fallback: "Select view mode (List or Thumbnail) on a per-folder basis, or use the same view mode for all folders.")
    /// Select all items/elements on the list
    public static let selectAll = Strings.tr("Localizable", "selectAll", fallback: "Select all")
    /// Title shown on the navigation bar to explain that you have to choose a destination for the files and/or folders in case you copy, move, import or do some action with them.
    public static let selectDestination = Strings.tr("Localizable", "selectDestination", fallback: "Select destination")
    /// Text of the button for user to select files in MEGA.
    public static let selectFiles = Strings.tr("Localizable", "selectFiles", fallback: "Select files")
    /// Header shown to help on the purchasin process
    public static let selectMembership = Strings.tr("Localizable", "selectMembership", fallback: "Select membership:")
    /// Text that explains that you have to select the plan you want and/or need after creating an account
    public static let selectOneAccountType = Strings.tr("Localizable", "selectOneAccountType", fallback: "Select one account type:")
    /// Title shown on the Camera Uploads section when the edit mode is enabled. On this mode you can select photos
    public static let selectTitle = Strings.tr("Localizable", "selectTitle", fallback: "Select items")
    /// Label for any 'Send' button, link, text, title, etc. - (String as short as possible).
    public static let send = Strings.tr("Localizable", "send", fallback: "Send")
    /// Used in Photos app browser view to send the photos from the view to the chat.
    public static func sendD(_ p1: Int) -> String {
      return Strings.tr("Localizable", "Send (%d)", p1, fallback: "Send (%d)")
    }
    /// Text for options in Get Link View to separate the key from the link
    public static let sendDecryptionKeySeparately = Strings.tr("Localizable", "Send Decryption Key Separately", fallback: "Send decryption key separately")
    /// Giphy section header
    public static let sendGIF = Strings.tr("Localizable", "Send GIF", fallback: "Send GIF")
    /// Alert title shown when the user opens a shared Geolocation for the first time from any client, we will show a confirmation dialog warning the user that he is now leaving the E2EE paradigm.
    public static let sendLocation = Strings.tr("Localizable", "Send Location", fallback: "Send location")
    /// Description of High Image Quality option
    public static let sendOriginalSizeIncreasedQualityImages = Strings.tr("Localizable", "Send original size, increased quality images", fallback: "Always send original size images.")
    /// Description of Optimised Image Quality option
    public static let sendSmallerSizeImagesOptimisedForLowerDataConsumption = Strings.tr("Localizable", "Send smaller size images optimised for lower data consumption", fallback: "Always send optimised images.")
    /// Description of Automatic Image Quality option
    public static let sendSmallerSizeImagesThroughCellularNetworksAndOriginalSizeImagesThroughWifi = Strings.tr("Localizable", "Send smaller size images through cellular networks and original size images through wifi", fallback: "Send optimised images when on mobile data but original size images when on Wi-Fi.")
    /// Title of the button to share a location in a chat
    public static let sendThisLocation = Strings.tr("Localizable", "Send This Location", fallback: "Send this location")
    /// A button label. The button sends contact information to a user in the conversation.
    public static let sendContact = Strings.tr("Localizable", "sendContact", fallback: "Send contacts")
    /// Title of one of the Settings sections where you can 'Send Feedback' to MEGA
    public static let sendFeedbackLabel = Strings.tr("Localizable", "sendFeedbackLabel", fallback: "Send feedback")
    /// Title to perform the action of sending a message to a contact.
    public static let sendMessage = Strings.tr("Localizable", "sendMessage", fallback: "Send message")
    /// Title of one of the filters in 'Contacts requests' section. If 'Sent' is selected, it will only show the requests which have been sent out.
    public static let sent = Strings.tr("Localizable", "sent", fallback: "Sent")
    /// When a contact sent a contact/friend request
    public static let sentYouAContactRequest = Strings.tr("Localizable", "Sent you a contact request", fallback: "Sent you a contact request")
    /// A summary message when a user sent a contact's details through the chat. Please keep %s as it will be replaced at runtime with the name of the contact that was sent.
    public static func sentContact(_ p1: UnsafePointer<CChar>) -> String {
      return Strings.tr("Localizable", "sentContact", p1, fallback: "Sent contact: %s")
    }
    /// A summary message when a user sent the information of %s number of contacts at once. Please keep %s as it will be replaced at runtime with the number of contacts sent.
    public static func sentXContacts(_ p1: UnsafePointer<CChar>) -> String {
      return Strings.tr("Localizable", "sentXContacts", p1, fallback: "Sent %s contacts.")
    }
    /// Label to indicate the server IP to be used. String as short as possible.
    public static let server = Strings.tr("Localizable", "Server:", fallback: "Server:")
    /// Message shown when the app is waiting for the server to complete a request due to a HTTP error 500.
    public static let serversAreTooBusy = Strings.tr("Localizable", "serversAreTooBusy", fallback: "Servers are too busy. Please wait…")
    /// Message shown when you click on 'Close other session' to block other login sessions except the current session in use. This message is shown when this has been done.
    public static let sessionsClosed = Strings.tr("Localizable", "sessionsClosed", fallback: "Sessions closed")
    /// Contact details screen: Set the alias(nickname) for a user
    public static let setNickname = Strings.tr("Localizable", "Set Nickname", fallback: "Set nickname")
    /// Text for options in Get Link View to set password protection
    public static let setPassword = Strings.tr("Localizable", "Set Password", fallback: "Set password")
    /// A label in the Get Link dialog which allows the user to set an expiry date on their public link.
    public static let setExpiryDate = Strings.tr("Localizable", "setExpiryDate", fallback: "Set expiry date")
    /// This is a title label on the Export Link dialog. The title covers the section where the user can password protect a public link.
    public static let setPasswordProtection = Strings.tr("Localizable", "setPasswordProtection", fallback: "Set password protection")
    /// Navigation path for Storage settings in iOS
    public static func settingsGeneralStorage(_ p1: Any) -> String {
      return Strings.tr("Localizable", "Settings > General > %@ Storage", String(describing: p1), fallback: "Settings > General > %@ Storage")
    }
    /// Title of the Settings section
    public static let settingsTitle = Strings.tr("Localizable", "settingsTitle", fallback: "Settings")
    /// Button which triggers the initial setup
    public static let setupMEGA = Strings.tr("Localizable", "Setup MEGA", fallback: "Set up MEGA")
    /// Title of the screen that shows the users with whom the user can share a folder
    public static let shareWith = Strings.tr("Localizable", "Share with", fallback: "Share with")
    /// Title of the tab bar item for the Shared Items section
    public static let shared = Strings.tr("Localizable", "shared", fallback: "Shared")
    /// Footer description for Upload Shared Albums title when option enabled
    public static let sharedAlbumsFromYourDeviceSPhotosAppWillBeUploaded = Strings.tr("Localizable", "Shared Albums from your device's Photos app will be uploaded.", fallback: "Shared Albums from your device’s Photos app will be uploaded.")
    /// Footer description for Upload Shared Albums title when option disabled
    public static let sharedAlbumsFromYourDeviceSPhotosAppWillNotBeUploaded = Strings.tr("Localizable", "Shared Albums from your device's Photos app will not be uploaded.", fallback: "Shared albums from your device’s Photos app will not be uploaded.")
    /// Header of block with all shared files in chat.
    public static let sharedFiles = Strings.tr("Localizable", "Shared Files", fallback: "Shared files")
    /// Success message shown when the user has successfully shared something
    public static let sharedSuccessfully = Strings.tr("Localizable", "Shared successfully", fallback: "Shared")
    /// Message shown when a folder have been shared
    public static let sharedFolderSuccess = Strings.tr("Localizable", "sharedFolder_success", fallback: "Folder shared")
    /// Title of the incoming shared folders of a user.
    public static let sharedFolders = Strings.tr("Localizable", "sharedFolders", fallback: "Shared folders")
    /// Success message for sharing multiple folders.
    public static func sharedFoldersSuccess(_ p1: Int) -> String {
      return Strings.tr("Localizable", "sharedFolders_success", p1, fallback: "%d folders shared")
    }
    /// Title of Shared Items section
    public static let sharedItems = Strings.tr("Localizable", "sharedItems", fallback: "Shared items")
    /// title of the screen that shows the users with whom the user has shared a folder
    public static let sharedWidth = Strings.tr("Localizable", "sharedWidth", fallback: "Shared with:")
    /// Title of the view where you see with who you have shared a folder
    public static let sharedWith = Strings.tr("Localizable", "sharedWith", fallback: "Shared with")
    /// Text shown to explain with how many contacts you have shared a folder
    public static func sharedWithXContacts(_ p1: Int) -> String {
      return Strings.tr("Localizable", "sharedWithXContacts", p1, fallback: "Shared with %d contacts")
    }
    /// Inform user that there were unsupported assets in the share extension
    public static let shareExtensionUnsupportedAssets = Strings.tr("Localizable", "shareExtensionUnsupportedAssets", fallback: "Some items could not be shared with MEGA")
    /// Message shown when a share has been left
    public static let shareLeft = Strings.tr("Localizable", "shareLeft", fallback: "Share left")
    /// Message shown when a share have been removed
    public static let shareRemoved = Strings.tr("Localizable", "shareRemoved", fallback: "Share removed")
    /// Message shown when some shares have been left
    public static let sharesLeft = Strings.tr("Localizable", "sharesLeft", fallback: "Shares left")
    /// Message shown when some shares have been removed
    public static let sharesRemoved = Strings.tr("Localizable", "sharesRemoved", fallback: "Shares removed")
    /// Item menu option upon right click on one or multiple files.
    public static let sharing = Strings.tr("Localizable", "sharing", fallback: "Sharing")
    /// Text title for shortcuts, ie in the widget
    public static let shortcuts = Strings.tr("Localizable", "Shortcuts", fallback: "Shortcuts")
    /// Label shown next to a feature name that can be enabled or disabled, like in 'Show Last seen...'
    public static let show = Strings.tr("Localizable", "Show", fallback: "Show")
    /// Title to describe a simple (four digit) passcode
    public static let simplePasscodeLabel = Strings.tr("Localizable", "simplePasscodeLabel", fallback: "Simple passcode")
    /// "Size" of the file or folder you are sharing
    public static let size = Strings.tr("Localizable", "size", fallback: "Size")
    /// Button title that skips the current action
    public static let skipButton = Strings.tr("Localizable", "skipButton", fallback: "Skip")
    /// Sort by option (4/6). This one order the files by its size, in this case from smaller to bigger size
    public static let smallest = Strings.tr("Localizable", "smallest", fallback: "Smallest")
    /// 
    public static let somethingWentWrong = Strings.tr("Localizable", "Something went wrong", fallback: "Something went wrong")
    /// Inside of Settings - Appearance, there is a view on which you can change the sorting preferences or the view mode preference for the app.
    public static let sortingAndViewMode = Strings.tr("Localizable", "Sorting And View Mode", fallback: "Sorting and view mode")
    /// Section title of the 'Sorting And View Mode' view inside of Settings - Appearence - Sorting And View Mode.
    public static let sortingPreference = Strings.tr("Localizable", "Sorting preference", fallback: "Sorting preference")
    /// Section title of the 'Sort by'
    public static let sortTitle = Strings.tr("Localizable", "sortTitle", fallback: "Sort by")
    /// Error shown when SSL check has failed
    public static let sslVerificationFailed = Strings.tr("Localizable", "SSL verification failed", fallback: "SSL verification failed")
    /// Alert title shown when the app detects that the Secure Sockets Layer (SSL) key of MEGA can't be verified.
    public static let sslUnverifiedAlertTitle = Strings.tr("Localizable", "sslUnverified_alertTitle", fallback: "MEGA is unable to connect securely through SSL. You might be on public Wi-Fi with additional requirements.")
    /// The Standard permission level in chat. With the standard permissions a participant can read and type messages in a chat.
    public static let standard = Strings.tr("Localizable", "standard", fallback: "Standard")
    /// Empty Conversations description
    public static let startChattingSecurelyWithYourContactsUsingEndToEndEncryption = Strings.tr("Localizable", "Start chatting securely with your contacts using end-to-end encryption", fallback: "Start chatting securely with your contacts using zero-knowledge encryption")
    /// Menu option from the `Add` section that allows the user to Start Group.
    public static let startGroup = Strings.tr("Localizable", "Start Group", fallback: "Start group")
    /// start a chat/conversation
    public static let startConversation = Strings.tr("Localizable", "startConversation", fallback: "Start conversation")
    /// Label text of a checkbox to ensure that the user is aware that the data of his current account will be lost when proceeding unless they remember their password or have their master encryption key (now renamed "Recovery Key")
    public static let startingFreshAccount = Strings.tr("Localizable", "startingFreshAccount", fallback: "I acknowledge that I am starting a fresh, empty account and that I will lose all data in my present account unless I recall my password or locate an exported Recovery key.")
    /// Caption of the button to proceed
    public static let startNewAccount = Strings.tr("Localizable", "startNewAccount", fallback: "Start new account")
    /// Title that refers to the status of the chat (Either Online or Offline)
    public static let status = Strings.tr("Localizable", "status", fallback: "Status")
    /// Label title to enable/disable the feature of the chat status that mantains your chosen status even if you don't have connected devices
    public static let statusPersistence = Strings.tr("Localizable", "statusPersistence", fallback: "Status persistence")
    /// Label for any ‘Storage’ button, link, text, title, etc. - (String as short as possible).
    public static let storage = Strings.tr("Localizable", "Storage", fallback: "Storage")
    /// Over Disk Quota Screen Navigation Bar Title
    public static let storageFull = Strings.tr("Localizable", "Storage Full", fallback: "Storage full")
    /// A header/title of a section which contains information about used/available storage space on a user's cloud drive.
    public static let storageQuota = Strings.tr("Localizable", "storageQuota", fallback: "Storage quota")
    /// Label displayed during checking the strength of the password introduced. Represents Strong security
    public static let strong = Strings.tr("Localizable", "strong", fallback: "Strong")
    /// A message shown at registration time when users have to select their plan. The FREE 50 GB plan is subject to the achievements program.
    public static let subjectToYourParticipationInOurAchievementsProgram = Strings.tr("Localizable", "subjectToYourParticipationInOurAchievementsProgram", fallback: "Subject to your participation in our achievements program.")
    /// Footer description for upload synced albums title
    public static let syncedAlbumsAreWhereYouSyncPhotosOrVideosToYourDeviceSPhotosAppFromITunes = Strings.tr("Localizable", "Synced albums are where you sync photos or videos to your device's Photos app from iTunes.", fallback: "Synced albums are where you sync photos or videos to your device’s Photos app from iTunes.")
    /// The header of a notification indicating that a file or folder has been taken down due to infringement or other reason.
    public static let takedownNotice = Strings.tr("Localizable", "Takedown notice", fallback: "Takedown notice")
    /// The header of a notification indicating that a file or folder that was taken down has now been restored due to a successful counter-notice.
    public static let takedownReinstated = Strings.tr("Localizable", "Takedown reinstated", fallback: "Takedown reinstated")
    /// Stand-alone error message shown to users who attempt to load/access a link where the link has been taken down due to severe violation of our terms of service.
    public static let takenDownDueToSevereViolationOfOurTermsOfService = Strings.tr("Localizable", "Taken down due to severe violation of our terms of service", fallback: "This folder or file was reported to contain objectionable content, such as Child Exploitation Material, Violent Extremism, or Bestiality. The link creator’s account has been closed and their full details, including IP address, have been provided to the authorities.")
    /// Message shown when the app is waiting for the server to complete a request due to an API lock (error -3).
    public static let takingLongerThanExpected = Strings.tr("Localizable", "takingLongerThanExpected", fallback: "The process is taking longer than expected. Please wait…")
    /// Tooltip shown when the user presses but does not hold the microphone icon to send a voice clip
    public static func tapAndHoldToRecordReleaseToSend(_ p1: Any) -> String {
      return Strings.tr("Localizable", "Tap and hold %@ to record, release to send", String(describing: p1), fallback: "Tap and hold %@ to record, release to send")
    }
    /// Subtitle shown in a chat to inform where to tap to enter in the chat details view
    public static let tapHereForInfo = Strings.tr("Localizable", "Tap here for info", fallback: "Tap here for info")
    /// Text showing the user how to write more than one email in order to invite them to MEGA
    public static let tapSpaceToEnterMultipleEmails = Strings.tr("Localizable", "Tap space to enter multiple emails", fallback: "Tap space to enter multiple emails")
    /// Text hint to let the user know that tapping something will be copied into the pasteboard
    public static let tapToCopy = Strings.tr("Localizable", "Tap to Copy", fallback: "Tap to copy")
    /// Message shown in a chat room for a one on one call
    public static let tapToReturnToCall = Strings.tr("Localizable", "Tap to return to call", fallback: "Tap to return to call")
    /// Footer shown in the Share Extension telling that a file can be renamed if tapped
    public static let tapFileToRename = Strings.tr("Localizable", "tapFileToRename", fallback: "Tap file to rename")
    /// Label to show that an error related with a temporary problem occurs during a SDK operation.
    public static let temporarilyNotAvailable = Strings.tr("Localizable", "Temporarily not available", fallback: "Temporarily not available")
    /// Error shown when terms of service are breached during download.
    public static let termsOfServiceBreached = Strings.tr("Localizable", "Terms of Service breached", fallback: "Terms of Service breached")
    /// Error text shown when you don't have selected the checkbox to agree with the Terms of Service
    public static let termsCheckboxUnselected = Strings.tr("Localizable", "termsCheckboxUnselected", fallback: "You need to agree with the Terms of Service to register an account on MEGA.")
    /// This error is shown in the account creation page. User has to agree to the terms and conditions. If the user does not agree to the losing password results in data loss condition then this error is shown
    public static let termsForLosingPasswordCheckboxUnselected = Strings.tr("Localizable", "termsForLosingPasswordCheckboxUnselected", fallback: "You need to agree that you understand the danger of losing your password")
    /// Title of one of the Settings sections where you can see the MEGA's 'Terms of Service'
    public static let termsOfServicesLabel = Strings.tr("Localizable", "termsOfServicesLabel", fallback: "Terms of Service")
    /// Label for test password button and titles
    public static let testPassword = Strings.tr("Localizable", "testPassword", fallback: "Test password")
    /// Used as a message in the "Password reminder" dialog as a tip on why confirming the password and/or exporting the recovery key is important and vital for the user to not lose any data.
    public static let testPasswordLogoutText = Strings.tr("Localizable", "testPasswordLogoutText", fallback: "You are about to log out, please test your password to ensure you remember it. If you lose your password, you will lose access to your MEGA data.")
    /// Used as a message in the 'Password reminder' dialog as a tip on why confirming the password and/or exporting the recovery key is important and vital for the user to not lose any data.
    public static let testPasswordText = Strings.tr("Localizable", "testPasswordText", fallback: "Please test your password below to ensure you remember it. If you lose your password, you will lose access to your MEGA data. [A]Learn more[/A]")
    /// Alert title shown when the user has purchase correctly some plan
    public static let thankYouTitle = Strings.tr("Localizable", "thankYou_title", fallback: "Thank you")
    /// An error message which is shown when you open a file/folder link (or other shared resource) and it’s no longer available because the user account that created the link has been terminated due to multiple violations of our Terms of Service
    public static let theAccountThatCreatedThisLinkHasBeenTerminatedDueToMultipleViolationsOfOurATermsOfServiceA = Strings.tr("Localizable", "The account that created this link has been terminated due to multiple violations of our [A]Terms of Service[/A].", fallback: "The account that created this link has been terminated due to multiple violations of our [A]Terms of Service[/A].")
    /// Dialog title for the no enough device storage screen
    public static let theDeviceDoesNotHaveEnoughSpaceForMEGAToRunProperly = Strings.tr("Localizable", "The device does not have enough space for MEGA to run properly.", fallback: "The device does not have enough space for MEGA to run properly.")
    /// Footer description when upload Hidden Album is enabled
    public static let theHiddenAlbumIsWhereYouHidePhotosOrVideosInYourDevicePhotosApp = Strings.tr("Localizable", "The Hidden Album is where you hide photos or videos in your device Photos app.", fallback: "The Hidden album is where you hide photos or videos in your device’s Photos app.")
    /// Error message that will be shown when the code introduced do not match with the one you received
    public static let theVerificationCodeDoesnTMatch = Strings.tr("Localizable", "The verification code doesn't match.", fallback: "The verification code doesn’t match.")
    /// Footer description when upload videos for Live Photos is enabled
    public static let theVideoAndThePhotoInEachLivePhotoWillBeUploaded = Strings.tr("Localizable", "The video and the photo in each Live Photo will be uploaded.", fallback: "The photo and video versions of each Live photo will be uploaded.")
    /// Message shown when you're trying to open a file or folder from the mobile webclient and the accounts logged are not the same
    public static let theContentIsNotAvailableForThisAccount = Strings.tr("Localizable", "theContentIsNotAvailableForThisAccount", fallback: "The content you are trying to access is not available for this account. Please try to log in with same account as in the mobile web client.")
    /// Add contacts and share dialog error message when user try to add wrong email address
    public static let theEmailAddressFormatIsInvalid = Strings.tr("Localizable", "theEmailAddressFormatIsInvalid", fallback: "The email address format is invalid")
    /// A tooltip message which shows when a file name is duplicated during renaming.
    public static let thereIsAlreadyAFileWithTheSameName = Strings.tr("Localizable", "There is already a file with the same name", fallback: "There is already a file with the same name")
    /// A tooltip message which is shown when a folder name is duplicated during renaming or creation.
    public static let thereIsAlreadyAFolderWithTheSameName = Strings.tr("Localizable", "There is already a folder with the same name", fallback: "There is already a folder with the same name")
    /// Success message shown when some contacts have been invited
    public static let theUsersHaveBeenInvited = Strings.tr("Localizable", "theUsersHaveBeenInvited", fallback: "The users have been invited and will appear in your contact list once accepted.")
    /// Error message shown to user when a copy/import operation would take them over their storage limit.
    public static let thisActionCanNotBeCompletedAsItWouldTakeYouOverYourCurrentStorageLimit = Strings.tr("Localizable", "This action can not be completed as it would take you over your current storage limit", fallback: "This action cannot be completed as it would take you over your current storage limit")
    /// Shown when an inexisting/unavailable/removed link is tried to be opened.
    public static let thisChatLinkIsNoLongerAvailable = Strings.tr("Localizable", "This chat link is no longer available", fallback: "This chat link is no longer available")
    /// Popup notification text on mouse-over of taken down file.
    public static let thisFileHasBeenTheSubjectOfATakedownNotice = Strings.tr("Localizable", "This file has been the subject of a takedown notice.", fallback: "This file has been the subject of a takedown notice.")
    /// Popup notification text on mouse-over taken down folder.
    public static let thisFolderHasBeenTheSubjectOfATakedownNotice = Strings.tr("Localizable", "This folder has been the subject of a takedown notice.", fallback: "This folder has been the subject of a takedown notice.")
    /// Stand-alone error message shown to users who attempt to load/access a link where the user has been suspended/taken-down due to severe violation of our terms of service.
    public static let thisLinkIsUnavailableAsTheUserSAccountHasBeenClosedForGrossViolationOfMEGASATermsOfServiceA = Strings.tr("Localizable", "This link is unavailable as the user’s account has been closed for gross violation of MEGA’s [A]Terms of Service[/A].", fallback: "This link is unavailable as the user’s account has been closed for gross violation of MEGA’s [A]Terms of Service[/A].")
    /// Message shown when the user opens a shared Geolocation for the first time from any client, we will show a confirmation dialog warning the user that he is now leaving the E2EE paradigm.
    public static let thisLocationWillBeOpenedUsingAThirdPartyMapsProviderOutsideTheEndToEndEncryptedMEGAPlatform = Strings.tr("Localizable", "This location will be opened using a third party maps provider outside the end-to-end encrypted MEGA platform.", fallback: "This location will be opened using a third party maps provider outside the end-to-end encrypted MEGA platform.")
    /// Shows the error when the limit of reactions per message is reached and a user tries to add one more. Keep the placeholder because is to show limit number in runtime.
    public static func thisMessageHasReachedTheMaximumLimitOfDReactions(_ p1: Int) -> String {
      return Strings.tr("Localizable", "This message has reached the maximum limit of %d reactions.", p1, fallback: "This message has reached the maximum limit of %d reactions.")
    }
    /// Error message that will show to user when host detected that the mobile number has been registered already
    public static let thisNumberIsAlreadyAssociatedWithAMegaAccount = Strings.tr("Localizable", "This number is already associated with a Mega account", fallback: "This number is already associated with a MEGA account.")
    /// Message for action to modify the registered phone number.
    public static let thisOperationWillRemoveYourCurrentPhoneNumberAndStartTheProcessOfAssociatingANewPhoneNumberWithYourAccount = Strings.tr("Localizable", "This operation will remove your current phone number and start the process of associating a new phone number with your account.", fallback: "This operation will remove your current phone number and start the process of associating a new phone number with your account.")
    /// A log message in a chat to indicate that the message has been deleted by the user.
    public static let thisMessageHasBeenDeleted = Strings.tr("Localizable", "thisMessageHasBeenDeleted", fallback: "This message has been deleted")
    /// Text shown for switching from list view to thumbnail view.
    public static let thumbnailView = Strings.tr("Localizable", "Thumbnail View", fallback: "Thumbnail view")
    /// This dialog message is used on the Password Decrypt dialog. The link is a password protected link so the user needs to enter the password to decrypt the link.
    public static let toAccessThisLinkYouWillNeedItsPassword = Strings.tr("Localizable", "To access this link, you will need its password.", fallback: "To access this link, you will need its password.")
    /// Shown as an error message when the user selects "create chat link", but haven't entered a title for the newly created room
    public static let toCreateAChatLinkYouMustNameTheGroup = Strings.tr("Localizable", "To create a chat link you must name the group.", fallback: "To create a chat link you must name the group.")
    /// Description shown when you try to disable the feature Rubbish-Bin Cleaning Scheduler and you are a free user
    public static let toDisableTheRubbishBinCleaningSchedulerOrSetALongerRetentionPeriodYouNeedToSubscribeToAPROPlan = Strings.tr("Localizable", "To disable the Rubbish-Bin Cleaning Scheduler or set a longer retention period, you need to subscribe to a PRO plan.", fallback: "To disable the Rubbish bin emptying scheduler or set a longer retention period, you need to subscribe to a Pro plan.")
    /// Detailed explanation of why the user should give some permissions to MEGA
    public static let toFullyTakeAdvantageOfYourMEGAAccountWeNeedToAskYouSomePermissions = Strings.tr("Localizable", "To fully take advantage of your MEGA account we need to ask you some permissions.", fallback: "To fully take advantage of your MEGA account we need to ask you some permissions.")
    /// Detailed explanation of why the user should give permission to access to the camera and the microphone
    public static let toMakeEncryptedVoiceAndVideoCallsAllowMEGAAccessToYourCameraAndMicrophone = Strings.tr("Localizable", "To make encrypted voice and video calls, allow MEGA access to your Camera and Microphone", fallback: "To send voice messages and make encrypted voice and video calls, allow MEGA access to your Camera and Microphone")
    /// When user is on PRO 3 plan, we will display an extra label to notify user that they can still contact support to have a customised plan.
    public static let toUpgradeYourCurrentSubscriptionPleaseContactSupportForAACustomPlanA = Strings.tr("Localizable", "To upgrade your current subscription, please contact support for a [A]custom plan[/A].", fallback: "To upgrade your current subscription, please contact support for a [A]custom plan[/A].")
    /// 
    public static let today = Strings.tr("Localizable", "Today", fallback: "Today")
    /// Label to show that an error for multiple concurrent connections or transfers occurs during a SDK operation.
    public static let tooManyConcurrentConnectionsOrTransfers = Strings.tr("Localizable", "Too many concurrent connections or transfers", fallback: "Too many concurrent connections or transfers")
    /// SDK error returned when there are too many requests
    public static let tooManyRequests = Strings.tr("Localizable", "Too many requests", fallback: "Too many requests")
    /// Error message when to many attempts to login
    public static func tooManyAttemptsLogin(_ p1: Any) -> String {
      return Strings.tr("Localizable", "tooManyAttemptsLogin", String(describing: p1), fallback: "You have attempted to log in too many times. Please wait until %@ and try again.")
    }
    /// Message shown when the app is waiting for the server to complete a request due to a rate limit (error -4).
    public static let tooManyRequest = Strings.tr("Localizable", "tooManyRequest", fallback: "Too many requests. Please wait.")
    /// A title message in the user’s account settings for showing the storage used for file versions.
    public static let totalSizeTakenUpByFileVersions = Strings.tr("Localizable", "Total size taken up by file versions:", fallback: "Total size taken up by file versions:")
    /// label for the total file size of multiple files and/or folders (no need to put the colon punctuation in the translation)
    public static let totalSize = Strings.tr("Localizable", "totalSize", fallback: "Total size")
    /// Label to indicate the amount of transfer quota in several places. It is a ‘noun‘ and there is an screenshot with an use example - (String as short as possible).
    public static let transfer = Strings.tr("Localizable", "Transfer", fallback: "Transfer")
    /// Notification message shown when a transfer failed. Keep colon.
    public static let transferFailed = Strings.tr("Localizable", "Transfer failed:", fallback: "Transfer failed:")
    /// Label indicating transfer over quota.
    public static let transferOverQuota = Strings.tr("Localizable", "Transfer over quota", fallback: "Transfer quota exceeded")
    /// Some text listed after the amount of transfer quota a user gets with a certain package. For example: '8 TB Transfer quota'.
    public static let transferQuota = Strings.tr("Localizable", "Transfer Quota", fallback: "Transfer")
    /// Success message shown when one transfer has been cancelled
    public static let transferCancelled = Strings.tr("Localizable", "transferCancelled", fallback: "Transfer cancelled")
    /// Title of the Transfers section
    public static let transfers = Strings.tr("Localizable", "transfers", fallback: "Transfers")
    /// Success message shown when all the transfers have been cancelled
    public static let transfersCancelled = Strings.tr("Localizable", "transfersCancelled", fallback: "Transfers cancelled")
    /// Title shown when the there is not any transfer and they are not paused
    public static let transfersEmptyStateTitleAll = Strings.tr("Localizable", "transfersEmptyState_titleAll", fallback: "No transfers")
    /// Title shown when the there is not any transfer, and the filter "Download" option is selected
    public static let transfersEmptyStateTitleDownload = Strings.tr("Localizable", "transfersEmptyState_titleDownload", fallback: "No downloads")
    /// Title shown when the transfers are paused
    public static let transfersEmptyStateTitlePaused = Strings.tr("Localizable", "transfersEmptyState_titlePaused", fallback: "Paused transfers")
    /// Title shown when the there is not any transfer, and the filter "Upload" option is selected
    public static let transfersEmptyStateTitleUpload = Strings.tr("Localizable", "transfersEmptyState_titleUpload", fallback: "No uploads")
    /// Footer text that explains when disabling the HTTP protocol for transfers may be useful
    public static let transfersSectionFooter = Strings.tr("Localizable", "transfersSectionFooter", fallback: "Enable this option only if your transfers don’t start. In normal circumstances HTTP is satisfactory as all transfers are already encrypted.")
    /// Button title to go to the iOS Settings to enable 'Mobile Data' for the MEGA app.
    public static let turnMobileDataOn = Strings.tr("Localizable", "Turn Mobile Data on", fallback: "Turn mobile data on")
    /// A title for the Two-Factor Authentication section on the My Account - Security page.
    public static let twoFactorAuthentication = Strings.tr("Localizable", "twoFactorAuthentication", fallback: "Two-factor authentication")
    /// A message on a dialog to say that 2FA has been successfully disabled.
    public static let twoFactorAuthenticationDisabled = Strings.tr("Localizable", "twoFactorAuthenticationDisabled", fallback: "Two-factor authentication disabled")
    /// A title on the mobile web client page showing that 2FA has been enabled successfully.
    public static let twoFactorAuthenticationEnabled = Strings.tr("Localizable", "twoFactorAuthenticationEnabled", fallback: "Two-factor authentication enabled")
    /// A message on the dialog shown after 2FA was successfully enabled.
    public static let twoFactorAuthenticationEnabledDescription = Strings.tr("Localizable", "twoFactorAuthenticationEnabledDescription", fallback: "Next time you log in to your account you will be asked to enter a 6-digit code provided by your authenticator app.")
    /// An informational message on the Backup Recovery Key dialog.
    public static let twoFactorAuthenticationEnabledWarning = Strings.tr("Localizable", "twoFactorAuthenticationEnabledWarning", fallback: "If you lose access to your account after enabling 2FA and you have not backed up your Recovery key, MEGA cannot help you gain access to it again.")
    /// Text shown in the purchase plan view to explain that annual subscription is 17% cheaper than 12 monthly payments
    public static func twoMonthsFree(_ p1: CChar) -> String {
      return Strings.tr("Localizable", "twoMonthsFree", p1, fallback: "An annual subscription is 16% cheaper than 12 monthly payments")
    }
    /// Plural, a hint that appears when two users are typing in a group chat at the same time. The parameter will be the concatenation of both user names. The tags and placeholders shouldn't be translated or modified.
    public static func twoUsersAreTyping(_ p1: UnsafePointer<CChar>) -> String {
      return Strings.tr("Localizable", "twoUsersAreTyping", p1, fallback: "%1$s [A]are typing…[/A]")
    }
    /// Refers to the type of a file or folder.
    public static let type = Strings.tr("Localizable", "type", fallback: "Type")
    /// Error shown when trying to start a call in a group with more peers than allowed
    public static let unableToStartACallBecauseTheParticipantsLimitWasExceeded = Strings.tr("Localizable", "Unable to start a call because the participants limit was exceeded.", fallback: "Unable to start the call due to the participant limit having been exceeded.")
    /// Message shown when the app is waiting for the server to complete a request due to connectivity issue.
    public static let unableToReachMega = Strings.tr("Localizable", "unableToReachMega", fallback: "Unable to reach MEGA. Please check your connectivity or try again later.")
    /// The title of the dialog to unarchive an archived chat.
    public static let unarchiveChat = Strings.tr("Localizable", "unarchiveChat", fallback: "Unarchive")
    /// Confirmation message for user to confirm it will unarchive an archived chat.
    public static let unarchiveChatMessage = Strings.tr("Localizable", "unarchiveChatMessage", fallback: "Are you sure you want to unarchive this conversation?")
    /// Text used to show the user that some resource is not available
    public static let unavailable = Strings.tr("Localizable", "Unavailable", fallback: "Unavailable")
    /// Label to show that an error related with an unknown error occurs during a SDK operation.
    public static let unknownError = Strings.tr("Localizable", "Unknown error", fallback: "Unknown error")
    /// Header of block with achievements bonuses.
    public static let unlockedBonuses = Strings.tr("Localizable", "unlockedBonuses", fallback: "Unlocked bonuses:")
    /// A button label. The button allows the user to unmute a conversation.
    public static let unmute = Strings.tr("Localizable", "unmute", fallback: "Unmute")
    /// Used in Photos app browser carousel view to unselect a selected photo.
    public static let unselect = Strings.tr("Localizable", "Unselect", fallback: "Unselect")
    /// Chat Notifications DND: Option to turn the DND on forever
    public static let untilITurnItBackOn = Strings.tr("Localizable", "Until I turn it back on", fallback: "Until I turn them back on")
    /// Chat Notifications DND: Option to turn the DND on until this morning 8 AM
    public static let untilThisMorning = Strings.tr("Localizable", "Until this morning", fallback: "Until this morning")
    /// Chat Notifications DND: Option to turn the DND on until tomorrow morning 8 AM
    public static let untilTomorrowMorning = Strings.tr("Localizable", "Until tomorrow morning", fallback: "Until tomorrow morning")
    /// Caption of a button to upgrade the account to Pro status
    public static let upgrade = Strings.tr("Localizable", "upgrade", fallback: "Upgrade")
    /// Mail title to upgrade to a custom plan
    public static let upgradeToACustomPlan = Strings.tr("Localizable", "Upgrade to a custom plan", fallback: "Upgrade to a custom plan")
    /// Title of a warning recommending upgrade to Pro
    public static let upgradeToPro = Strings.tr("Localizable", "Upgrade to Pro", fallback: "Upgrade to Pro")
    /// Button title which triggers the action to upgrade your MEGA account level
    public static let upgradeAccount = Strings.tr("Localizable", "upgradeAccount", fallback: "Upgrade account")
    /// 
    public static let upload = Strings.tr("Localizable", "upload", fallback: "Upload")
    /// Used in Photos app browser view to upload the photos from the view to the cloud.
    public static func uploadD(_ p1: Int) -> String {
      return Strings.tr("Localizable", "Upload (%d)", p1, fallback: "Upload (%d)")
    }
    /// Title of the switch to config whether to upload synced albums
    public static let uploadAlbumsSyncedFromITunes = Strings.tr("Localizable", "Upload Albums Synced from iTunes", fallback: "Upload albums synced from iTunes")
    /// Title of the switch to config whether to upload all burst photos
    public static let uploadAllBurstPhotos = Strings.tr("Localizable", "Upload All Burst Photos", fallback: "Upload all burst photos")
    /// Text to indicate the action of uploading a file to the cloud drive
    public static let uploadFile = Strings.tr("Localizable", "Upload File", fallback: "Upload file")
    /// Title of the switch to config whether to upload Hidden Album
    public static let uploadHiddenAlbum = Strings.tr("Localizable", "Upload Hidden Album", fallback: "Upload Hidden album")
    /// Message shown when camera upload paused because of no WiFi. Plural.
    public static func uploadPausedBecauseOfNoWiFiLuFilesPending(_ p1: Int) -> String {
      return Strings.tr("Localizable", "Upload paused because of no WiFi, %lu files pending", p1, fallback: "Upload paused due to no Wi-Fi connection, %lu files pending")
    }
    /// Message shown when camera upload paused because of no WiFi. Singular.
    public static let uploadPausedBecauseOfNoWiFi1FilePending = Strings.tr("Localizable", "Upload paused because of no WiFi, 1 file pending", fallback: "Upload paused due to no Wi-Fi connection, 1 file pending")
    /// SDK error returned when an upload would produce recursivity
    public static let uploadProducesRecursivity = Strings.tr("Localizable", "Upload produces recursivity", fallback: "Transfer failed due to a recursive directory structure")
    /// Title of the switch to config whether to upload Shared Albums
    public static let uploadSharedAlbums = Strings.tr("Localizable", "Upload Shared Albums", fallback: "Upload shared albums")
    /// Title of the switch to config whether to upload videos for Live Photos
    public static let uploadVideosForLivePhotos = Strings.tr("Localizable", "Upload Videos for Live Photos", fallback: "Upload videos for Live photos")
    /// Title of one of the filters in the Transfers section. In this case "Uploads" transfers.
    public static let uploads = Strings.tr("Localizable", "uploads", fallback: "Uploads")
    /// Message shown when a upload starts
    public static let uploadStartedMessage = Strings.tr("Localizable", "uploadStarted_Message", fallback: "Upload started")
    /// 
    public static let uploadToMega = Strings.tr("Localizable", "uploadToMega", fallback: "Upload to MEGA")
    /// Option title to enable upload videos with Camera Uploads
    public static let uploadVideosLabel = Strings.tr("Localizable", "uploadVideosLabel", fallback: "Upload videos")
    /// Title next to a switch button (On-Off) to allow using mobile data (Roaming) for videos.
    public static let useMobileDataForVideos = Strings.tr("Localizable", "Use Mobile Data for Videos", fallback: "Use mobile data for videos")
    /// Title for an action to use most compatible formats
    public static let useMostCompatibleFormats = Strings.tr("Localizable", "Use Most Compatible Formats", fallback: "Use most compatible formats")
    /// Title next to a switch button (On-Off) to allow using mobile data (Roaming) for a feature.
    public static let useMobileData = Strings.tr("Localizable", "useMobileData", fallback: "Use mobile data")
    /// user (singular) label indicating is receiving some info, for example shared folders
    public static let user = Strings.tr("Localizable", "user", fallback: "user")
    /// Label presented to Admins that full management of the business is only available in a desktop web browser
    public static let userManagementIsOnlyAvailableFromADesktopWebBrowser = Strings.tr("Localizable", "User management is only available from a desktop web browser.", fallback: "User management is only available from a desktop web browser.")
    /// Label to indicate the username of the proxy. String as short as possible.
    public static let username = Strings.tr("Localizable", "Username:", fallback: "Username:")
    /// used for example when a folder is shared with 2 or more users
    public static let users = Strings.tr("Localizable", "users", fallback: "users")
    /// Button title
    public static let verified = Strings.tr("Localizable", "verified", fallback: "Approved")
    /// Label for any ‘Verify’ button, link, text, title, etc. - (String as short as possible).
    public static let verify = Strings.tr("Localizable", "verify", fallback: "Approve")
    /// Verify your account title
    public static let verifyYourAccount = Strings.tr("Localizable", "Verify Your Account", fallback: "Verify your account")
    /// Title for a section on the fingerprint warning dialog. Below it is a button which will allow the user to verify their contact's fingerprint credentials.
    public static let verifyCredentials = Strings.tr("Localizable", "verifyCredentials", fallback: "Approve credentials")
    /// Text shown on the confirm email view to remind the user what to do
    public static let verifyYourEmailAddressDescription = Strings.tr("Localizable", "verifyYourEmailAddress_description", fallback: "Please enter your password to verify your email address")
    /// Text shown when the creation of a version as a new file was successful
    public static let versionCreatedAsANewFileSuccessfully = Strings.tr("Localizable", "Version created as a new file successfully.", fallback: "Version was created as a new file")
    /// Title of section to display number of all historical versions of files.
    public static let versions = Strings.tr("Localizable", "versions", fallback: "Versions")
    /// Label displayed during checking the strength of the password introduced. Represents Very Weak security
    public static let veryWeak = Strings.tr("Localizable", "veryWeak", fallback: "Very weak")
    /// Title of the button in the contact info screen to start a video call
    public static let video = Strings.tr("Localizable", "Video", fallback: "Video")
    /// Label used near to the option selected to encode the videos uploaded to a chat (Low, Medium, Original)
    public static let videoQuality = Strings.tr("Localizable", "videoQuality", fallback: "Video quality")
    /// Title for video explorer view
    public static let videos = Strings.tr("Localizable", "Videos", fallback: "Videos")
    /// Footer for video uploads switch section when enabled
    public static let videosWillBeUploadedToTheCameraUploadsFolder = Strings.tr("Localizable", "Videos will be uploaded to the Camera Uploads folder.", fallback: "Videos will be uploaded to the Camera uploads folder.")
    /// Button title which, if tapped, will trigger the action of opening a folder containg this file
    public static let viewInFolder = Strings.tr("Localizable", "View in Folder", fallback: "View in folder")
    /// Section title of the 'Sorting And View Mode' view inside of Settings - Appearence - Sorting And View Mode.
    public static let viewModePreference = Strings.tr("Localizable", "View mode preference", fallback: "View mode preference")
    /// Text indicating to the user that can perform an action to view more results
    public static let viewMore = Strings.tr("Localizable", "VIEW MORE", fallback: "View more")
    /// Link to the public code of the app
    public static let viewSourceCode = Strings.tr("Localizable", "View Source Code", fallback: "View source code")
    /// Title show on the hall of My Account section that describes a place where you can view, edit and upgrade your account and profile
    public static let viewAndEditProfile = Strings.tr("Localizable", "viewAndEditProfile", fallback: "View and edit profile")
    /// Menu option from the `Add` section that allows the user to make voice call.
    public static let voice = Strings.tr("Localizable", "Voice", fallback: "Voice")
    /// Menu option from the `Add` section that allows the user to share voice clip
    public static let voiceClip = Strings.tr("Localizable", "Voice Clip", fallback: "Voice clip")
    /// Text shown when a notification or the last message of a chat corresponds to a voice clip
    public static let voiceMessage = Strings.tr("Localizable", "Voice message", fallback: "Voice message")
    /// Section title of a button where you can enable mobile data for voice and video calls.
    public static let voiceAndVideoCalls = Strings.tr("Localizable", "voiceAndVideoCalls", fallback: "Voice and video calls")
    /// 
    public static let warning = Strings.tr("Localizable", "warning", fallback: "Warning")
    /// A log message in a chat conversation to tell the reader that a participant [A] was removed from the group chat by the moderator [B]. Please keep [A] and [B], they will be replaced by the participant and the moderator names at runtime. For example: Alice was removed from the group chat by Frank.
    public static let wasRemovedFromTheGroupChatBy = Strings.tr("Localizable", "wasRemovedFromTheGroupChatBy", fallback: "[A] was removed from the group chat by [B].")
    /// Footer for HEIC format section
    public static let weRecommendJPGAsItsTheMostCompatibleFormatForPhotos = Strings.tr("Localizable", "We recommend JPG, as its the most compatible format for photos.", fallback: "We recommend JPG, as it is the most compatible format for photos.")
    /// Detailed explanation of why the user should give permission to deliver notifications
    public static let weWouldLikeToSendYouNotificationsSoYouReceiveNewMessagesOnYourDeviceInstantly = Strings.tr("Localizable", "We would like to send you notifications so you receive new messages on your device instantly.", fallback: "We would like to send you notifications so you receive new messages on your device instantly.")
    /// 
    public static let `weak` = Strings.tr("Localizable", "weak", fallback: "Weak")
    /// Description for the ‘Two-Factor Authentication’ in the security settings section.
    public static let whatIsTwoFactorAuthentication = Strings.tr("Localizable", "whatIsTwoFactorAuthentication", fallback: "Two-factor authentication is a second layer of security for your account.")
    /// Footer text for Camera Upload switch section when camera upload is disabled
    public static let whenEnabledPhotosWillBeUploaded = Strings.tr("Localizable", "When enabled, photos will be uploaded.", fallback: "When enabled, photos will be uploaded.")
    /// Footer for video uploads switch section when disabled
    public static let whenEnabledVideosWillBeUploaded = Strings.tr("Localizable", "When enabled, videos will be uploaded.", fallback: "When enabled, videos will be uploaded.")
    /// Warning message to alert user about logout in My Account section if has offline files and transfers in progress.
    public static let whenYouLogoutFilesFromYourOfflineSectionWillBeDeletedFromYourDeviceAndOngoingTransfersWillBeCancelled = Strings.tr("Localizable", "When you logout, files from your Offline section will be deleted from your device and ongoing transfers will be cancelled.", fallback: "When you log out, files from your Offline section will be deleted from your device and ongoing transfers will be cancelled.")
    /// Warning message to alert user about logout in My Account section if has offline files.
    public static let whenYouLogoutFilesFromYourOfflineSectionWillBeDeletedFromYourDevice = Strings.tr("Localizable", "When you logout, files from your Offline section will be deleted from your device.", fallback: "When you log out, files from your Offline section will be deleted from your device.")
    /// Warning message to alert user about logout in My Account section if has transfers in progress.
    public static let whenYouLogoutOngoingTransfersWillBeCancelled = Strings.tr("Localizable", "When you logout, ongoing transfers will be cancelled.", fallback: "When you log out, ongoing transfers will be cancelled.")
    /// Message shown when users with a business account (no administrators of a business account) try to enable the Camera Uploads, to advise them that the administrator do have the ability to view their data.
    public static let whileMEGADoesNotHaveAccessToYourDataYourOrganizationAdministratorsDoHaveTheAbilityToControlAndViewTheCameraUploadsInYourUserAccount = Strings.tr("Localizable", "While MEGA does not have access to your data, your organization administrators do have the ability to control and view the Camera Uploads in your user account", fallback: "MEGA cannot access your data. However, your Business account administrator can access your Camera uploads.")
    /// Text for button to open an helping view
    public static let whyAmISeeingThis = Strings.tr("Localizable", "Why am I seeing this?", fallback: "Why am I seeing this?")
    /// Question button to present a view where it's explained what is the Recovery Key
    public static let whyDoINeedARecoveryKey = Strings.tr("Localizable", "whyDoINeedARecoveryKey", fallback: "Why do I need a Recovery key?")
    /// Title of the dialog displayed to start setup the Two-Factor Authentication
    public static let whyYouDoNeedTwoFactorAuthentication = Strings.tr("Localizable", "whyYouDoNeedTwoFactorAuthentication", fallback: "Why do you need two-factor authentication?")
    /// Description text of the dialog displayed to start setup the Two-Factor Authentication
    public static let whyYouDoNeedTwoFactorAuthenticationDescription = Strings.tr("Localizable", "whyYouDoNeedTwoFactorAuthenticationDescription", fallback: "Two-factor authentication is a second layer of security for your account. Which means that even if someone knows your password they cannot access it, without also having access to the six digit code only you have access to.")
    /// Label to show that an error related with an write error occurs during a SDK operation.
    public static let writeError = Strings.tr("Localizable", "Write error", fallback: "Write error")
    /// This is shown in the typing area in chat, as a placeholder before the user starts typing anything in the field. The format is: Write a message to Contact Name... Write a message to "Chat room topic"... Write a message to Contact Name1, Contact Name2, Contact Name3
    public static func writeAMessage(_ p1: UnsafePointer<CChar>) -> String {
      return Strings.tr("Localizable", "writeAMessage", p1, fallback: "Write a message to %s…")
    }
    /// Error message shown when the purchase has failed
    public static func wrongPurchase(_ p1: Any, _ p2: Int) -> String {
      return Strings.tr("Localizable", "wrongPurchase", String(describing: p1), p2, fallback: "Wrong purchase %@ (%ld)")
    }
    /// [X] will be replaced by a plural number, indicating the total number of contacts the user has
    public static let xContactsSelected = Strings.tr("Localizable", "XContactsSelected", fallback: "[X] contacts")
    /// success message when sending multiple files. Please do not modify the %d placeholder.
    public static func xfilesSentSuccesfully(_ p1: Int) -> String {
      return Strings.tr("Localizable", "xfilesSentSuccesfully", p1, fallback: "%d files sent")
    }
    /// String shown when multi selection is enabled and the user has more than one item selected.
    public static func xSelected(_ p1: Int) -> String {
      return Strings.tr("Localizable", "xSelected", p1, fallback: "%d selected")
    }
    /// Message to display the number of historical versions of files. Please keep [X] as it will be replaced at the runtime.
    public static let xVersions = Strings.tr("Localizable", "xVersions", fallback: "[X] versions")
    /// "Yearly" subscriptions
    public static let yearly = Strings.tr("Localizable", "yearly", fallback: "Yearly")
    /// A user can mark a folder or file with its own colour, in this case “Yellow”.
    public static let yellow = Strings.tr("Localizable", "Yellow", fallback: "Yellow")
    /// 
    public static let yes = Strings.tr("Localizable", "yes", fallback: "Yes")
    /// 
    public static let yesterday = Strings.tr("Localizable", "Yesterday", fallback: "Yesterday")
    /// Response text after clicking Accept on an incoming contact request notification.
    public static let youAcceptedAContactRequest = Strings.tr("Localizable", "You accepted a contact request", fallback: "You accepted a contact request")
    /// Title shown when the user reconnect in a call.
    public static let youAreBack = Strings.tr("Localizable", "You are back!", fallback: "You are back.")
    /// Extra information shown when the user has disabled the 'Mobile Data' setting for MEGA in the iOS Settings.
    public static let youCanTurnOnMobileDataForThisAppInSettings = Strings.tr("Localizable", "You can turn on mobile data for this app in Settings.", fallback: "You can turn on mobile data for this app in the device’s Settings.")
    /// Error shown when a Business account user (sub-user or admin) tries to remove a contact which is part of the same Business account. Please, keep the placeholder, it will be replaced with the name or email of the account, for example: Jane Appleseed or ja@mega.nz
    public static func youCannotRemove1SAsAContactBecauseTheyArePartOfYourBusinessAccount(_ p1: UnsafePointer<CChar>) -> String {
      return Strings.tr("Localizable", "You cannot remove %1$s as a contact because they are part of your Business account.", p1, fallback: "You cannot remove %1$s as a contact because they are part of your Business account.")
    }
    /// Response text after clicking Deny on an incoming contact request notification.
    public static let youDeniedAContactRequest = Strings.tr("Localizable", "You denied a contact request", fallback: "You denied a contact request")
    /// Text message to remind user to resend verification code
    public static let youDidnTReceiveACode = Strings.tr("Localizable", "You didn't receive a code?", fallback: "You didn’t receive a code?")
    /// Text shown in a notification to let the user know that has joined a public chat room after login or account creation
    public static func youHaveJoined(_ p1: Any) -> String {
      return Strings.tr("Localizable", "You have joined %@", String(describing: p1), fallback: "You have joined %@")
    }
    /// Error message that will show to user when user reached the sms verification daily limit
    public static let youHaveReachedTheDailyLimit = Strings.tr("Localizable", "You have reached the daily limit", fallback: "You have reached the daily limit")
    /// Shows the error when the limit of reactions per user is reached and the user tries to add one more. Keep the placeholder because is to show limit number in runtime.
    public static func youHaveReachedTheMaximumLimitOfDReactions(_ p1: Int) -> String {
      return Strings.tr("Localizable", "You have reached the maximum limit of %d reactions.", p1, fallback: "You have reached the maximum limit of %d reactions.")
    }
    /// Title shown in a page of the on boarding screens explaining that the user keeps the encryption keys
    public static let youHoldTheKeys = Strings.tr("Localizable", "You hold the keys", fallback: "You hold the keys")
    /// Response text after clicking Ignore on an incoming contact request notification.
    public static let youIgnoredAContactRequest = Strings.tr("Localizable", "You ignored a contact request", fallback: "You ignored a contact request")
    /// Content of the notification when there is unknown activity on the Chat
    public static let youMayHaveNewMessages = Strings.tr("Localizable", "You may have new messages", fallback: "You have new messages")
    /// Success message when changing profile information.
    public static let youHaveSuccessfullyChangedYourProfile = Strings.tr("Localizable", "youHaveSuccessfullyChangedYourProfile", fallback: "You have changed your profile")
    /// Alert text shown when enabling Two-Factor Authentication when you don't have a two factor authentication app installed on the device
    public static let youNeedATwoFactorAuthenticationApp = Strings.tr("Localizable", "youNeedATwoFactorAuthenticationApp", fallback: "We’re sorry, two-factor authentication cannot be enabled on your device. Please open the App Store to install an authenticator app.")
    /// Alert title shown when you are seeing the details of a file and you are not able to access it anymore because it has been removed or moved from the shared folder where it used to be
    public static let youNoLongerHaveAccessToThisFileAlertTitle = Strings.tr("Localizable", "youNoLongerHaveAccessToThisFile_alertTitle", fallback: "You no longer have access to this file")
    /// Alert title shown when you are seeing the details of a folder and you are not able to access it anymore because it has been removed or moved from the shared folder where it used to be
    public static let youNoLongerHaveAccessToThisFolderAlertTitle = Strings.tr("Localizable", "youNoLongerHaveAccessToThisFolder_alertTitle", fallback: "You no longer have access to this folder")
    /// Text describing account suspended state to the user
    public static let yourAccountHasBeenTemporarilySuspendedForYourSafety = Strings.tr("Localizable", "Your account has been temporarily suspended for your safety.", fallback: "Your account has been temporarily locked for your safety.")
    /// Error message that will show to user its account is already verified
    public static let yourAccountIsAlreadyVerified = Strings.tr("Localizable", "Your account is already verified", fallback: "Your account is already verified")
    /// A dialog title shown to users when their business account is expired.
    public static let yourBusinessAccountIsExpired = Strings.tr("Localizable", "Your business account is expired", fallback: "Account deactivated")
    /// Over Disk Quota title message that tell customer your data at risk.
    public static let yourDataIsAtRisk = Strings.tr("Localizable", "Your Data is at Risk!", fallback: "Your data is at risk!")
    /// Locked accounts description text by bad use of user password. This text is 2 of 2 paragraph of a description.
    public static let yourPasswordLeakedAndIsNowBeingUsedByBadActorsToLogIntoYourAccountsIncludingButNotLimitedToYourMEGAAccount = Strings.tr("Localizable", "Your password leaked and is now being used by bad actors to log into your accounts, including, but not limited to, your MEGA account.", fallback: "Your password leaked and is now being used by bad actors to log in to your accounts, including, but not limited to, your MEGA account.")
    /// A notification telling the user that their Pro plan payment was successfully received. The %1 indicates the name of the Pro plan they paid for e.g. Lite, PRO III.
    public static let yourPaymentForThe1PlanWasReceived = Strings.tr("Localizable", "Your payment for the %1 plan was received.", fallback: "Your payment for the %1 plan was received.")
    /// A notification telling the user that their Pro plan payment was unsuccessful. The %1 indicates the name of the Pro plan they were trying to pay for e.g. Lite, PRO II.
    public static let yourPaymentForThe1PlanWasUnsuccessful = Strings.tr("Localizable", "Your payment for the %1 plan was unsuccessful.", fallback: "We didn’t receive your payment for the %1 plan.")
    /// Place holder for enter mobile number field
    public static let yourPhoneNumber = Strings.tr("Localizable", "Your phone number", fallback: "Your phone number")
    /// Information message shown to users when the operation of removing phone number succeed.
    public static let yourPhoneNumberHasBeenRemovedSuccessfully = Strings.tr("Localizable", "Your phone number has been removed successfully.", fallback: "Your phone number has been removed")
    /// Message shown when verify phone number successfully
    public static let yourPhoneNumberHasBeenVerifiedSuccessfully = Strings.tr("Localizable", "Your phone number has been verified successfully", fallback: "Your phone number has been verified")
    /// Title shown in a page of the on boarding screens explaining that the user can backup the photos automatically
    public static let yourPhotosInTheCloud = Strings.tr("Localizable", "Your Photos in the Cloud", fallback: "Your photos in the Cloud")
    /// The professional pricing plan which the user was on expired %1 days ago. The %1 is a placeholder for the number of days and should not be removed.
    public static let yourPROMembershipPlanExpired1DaysAgo = Strings.tr("Localizable", "Your PRO membership plan expired %1 days ago", fallback: "Your Pro plan expired %1 days ago")
    /// The professional pricing plan which the user was on expired one day ago.
    public static let yourPROMembershipPlanExpired1DayAgo = Strings.tr("Localizable", "Your PRO membership plan expired 1 day ago", fallback: "Your Pro plan expired 1 day ago")
    /// The professional pricing plan which the user is currently on will expire in 5 days. The %1 is a placeholder for the number of days and should not be removed.
    public static let yourPROMembershipPlanWillExpireIn1Days = Strings.tr("Localizable", "Your PRO membership plan will expire in %1 days.", fallback: "Your Pro membership plan will expire in %1 days.")
    /// The professional pricing plan which the user is currently on will expire in one day.
    public static let yourPROMembershipPlanWillExpireIn1Day = Strings.tr("Localizable", "Your PRO membership plan will expire in 1 day.", fallback: "Your Pro membership plan will expire tomorrow.")
    /// uploads over storage quota warning dialog title
    public static let yourUploadSCannotProceedBecauseYourAccountIsFull = Strings.tr("Localizable", "Your upload(s) cannot proceed because your account is full", fallback: "Your upload cannot proceed because your Cloud storage is full")
    /// 
    public static let yourAccounHasBeenParked = Strings.tr("Localizable", "yourAccounHasBeenParked", fallback: "Your old account has been parked. You can now log in to your new account.")
    /// Text of the alert after opening the recovery link to reset pass being logged.
    public static let youRecoveryKeyIsGoingTo = Strings.tr("Localizable", "youRecoveryKeyIsGoingTo", fallback: "Your Recovery key is going to be used to reset your password. Please enter your new password.")
    /// 
    public static let yourPasswordHasBeenReset = Strings.tr("Localizable", "yourPasswordHasBeenReset", fallback: "Your password has been reset. Please log in to your account now.")
    /// Message that is shown when the user click on 'Cancel your account' to confirm that he's aware that his data will be deleted.
    public static let youWillLooseAllData = Strings.tr("Localizable", "youWillLooseAllData", fallback: "You will lose all data associated with this account. Are you sure you want to proceed?")
    /// Alert text that explains what means confirming the action 'Leave'
    public static let youWillNoLongerHaveAccessToThisConversation = Strings.tr("Localizable", "youWillNoLongerHaveAccessToThisConversation", fallback: "You will no longer have access to this conversation")
    public enum BodyWarnYouMustActImmediatelyToSaveYourData {
      /// Over Disk Quota of must act immediately to save your data
      public static let warnBody = Strings.tr("Localizable", "<body><warn>You must act immediately to save your data.</warn><body>", fallback: "<body><warn>You must act immediately to save your data.</warn><body>")
    }
    public enum BodyYouHaveWarnWarnLeftToUpgrade {
      /// Over Disk Quota warning message to tell user to how long left before upgrading
      public static func body(_ p1: Any) -> String {
        return Strings.tr("Localizable", "<body>You have <warn>%@</warn> left to upgrade.</body>", String(describing: p1), fallback: "<body>You have <warn>%@</warn> left to upgrade.</body>")
      }
    }
    public enum ParagraphWeHaveContactedYouByEmailToBBOnBBButYouStillHaveFilesTakingUpBBInYourMEGAAccountWhichRequiresYouToContactSupportForACustomPlan {
      /// Over Disk Quota warning message to give customer subscription plan upgrade advice according to cloud space used and subject to deletion deadline and warning dates.
      public static func paragraph(_ p1: Any, _ p2: Any, _ p3: Any, _ p4: Any) -> String {
        return Strings.tr("Localizable", "<paragraph>We have contacted you by email to <b>%@</b> on <b>%@</b> but you still have %@ files taking up <b>%@</b> in your MEGA account, which requires you to contact support for a custom plan.</paragraph>", String(describing: p1), String(describing: p2), String(describing: p3), String(describing: p4), fallback: "<paragraph>We have contacted you by email to <b>%@</b> on <b>%@</b> but you still have %@ files taking up <b>%@</b> in your MEGA account, which requires you to contact support for a custom plan.</paragraph>")
      }
    }
    public enum ParagraphWeHaveContactedYouByEmailToBBOnBBButYouStillHaveFilesTakingUpBBInYourMEGAAccountWhichRequiresYouToUpgradeToBB {
      /// Over Disk Quota warning message to give customer subscription plan upgrade advice according to cloud space used and subject to deletion deadline and warning dates.
      public static func paragraph(_ p1: Any, _ p2: Any, _ p3: Any, _ p4: Any, _ p5: Any) -> String {
        return Strings.tr("Localizable", "<paragraph>We have contacted you by email to <b>%@</b> on <b>%@</b> but you still have %@ files taking up <b>%@</b> in your MEGA account, which requires you to upgrade to <b>%@</b>.</paragraph>", String(describing: p1), String(describing: p2), String(describing: p3), String(describing: p4), String(describing: p5), fallback: "<paragraph>We have contacted you by email to <b>%@</b> on <b>%@</b> but you still have %@ files taking up <b>%@</b> in your MEGA account, which requires you to upgrade to <b>%@</b>.</paragraph>")
      }
    }
    public enum AddYourPhoneNumberToMEGA {
      /// Description to encourage users to add phone number to their accounts when there are not achievements
      public static let thisMakesItEasierForYourContactsToFindYouOnMEGA = Strings.tr("Localizable", "Add your phone number to MEGA. This makes it easier for your contacts to find you on MEGA.", fallback: "Add your phone number to MEGA. This makes it easier for your contacts to find you on MEGA.")
    }
    public enum AllCurrentFilesWillRemain {
      /// A warning note about deleting all file versions in the settings section.
      public static let onlyHistoricVersionsOfYourFilesWillBeDeleted = Strings.tr("Localizable", "All current files will remain. Only historic versions of your files will be deleted.", fallback: "All current files will remain. Only historic versions of your files will be deleted.")
    }
    public enum AnErrorHasOccurred {
      /// Message show when the history of a chat hasn’t been successfully deleted
      public static let theChatHistoryHasNotBeenSuccessfullyCleared = Strings.tr("Localizable", "An error has occurred. The chat history has not been successfully cleared", fallback: "An error has occurred. The chat history hasn’t been cleared")
    }
    public enum CameraUploadsIsAnEssentialFeatureForAnyMobileDeviceAndWeHaveGotYouCovered {
      /// Description shown in a page of the onboarding screens explaining the camera uploads feature
      public static let createYourAccountNow = Strings.tr("Localizable", "Camera Uploads is an essential feature for any mobile device and we have got you covered. Create your account now.", fallback: "Camera uploads is an essential feature for any mobile device and we have got you covered. Create your account now.")
    }
    public enum CompressionQualityWhenToTranscodeHEVCVideosToH {
      /// Footer for video compression quality
      public static let _264Format = Strings.tr("Localizable", "Compression quality when to transcode HEVC videos to H.264 format.", fallback: "Compression quality when HEVC videos are transcoded to H.264 format.")
    }
    public enum CouldnTLoad {
      /// Explanation when loading voice message error
      public static let redTapToRetryRED = Strings.tr("Localizable", "Couldn't load. [RED]Tap to retry[/RED]", fallback: "Couldn’t load. [RED]Tap to retry[/RED]")
    }
    public enum DeleteAllMessagesAndFilesSharedInThisConversationFromBothParties {
      /// Text show under the setting 'Clear Chat History' to explain what will happen if used
      public static let thisActionIsIrreversible = Strings.tr("Localizable", "Delete all messages and files shared in this conversation from both parties. This action is irreversible", fallback: "Delete all messages and files shared in this conversation. This action is irreversible.")
    }
    public enum EmailAlreadySent {
      /// Error text shown when requesting email for email verification within 10 minutes
      public static let pleaseWaitAFewMinutesBeforeTryingAgain = Strings.tr("Localizable", "Email already sent. Please wait a few minutes before trying again.", fallback: "Email already sent. Please wait a few minutes before trying again.")
    }
    public enum EnableOrDisableFileVersioningForYourEntireAccount {
      /// Subtitle of the option to enable or disable file versioning on Settings section
      public static let brYouMayStillReceiveFileVersionsFromSharedFoldersIfYourContactsHaveThisEnabled = Strings.tr("Localizable", "Enable or disable file versioning for your entire account.[Br]You may still receive file versions from shared folders if your contacts have this enabled.", fallback: "Enable or disable file versioning for your entire account.\nDisabling file versioning does not prevent your contacts from creating new versions in shared folders.")
    }
    public enum Error {
      /// Message show when a call cannot be established because there are too many participants in the group call
      public static let noMoreParticipantsAreAllowedInThisGroupCall = Strings.tr("Localizable", "Error. No more participants are allowed in this group call.", fallback: "You are not allowed to join this call as it has reached the maximum number of participants.")
      /// Message show when a user cannot activate the video in a group call because the max number of videos has been reached
      public static let noMoreVideoAreAllowedInThisGroupCall = Strings.tr("Localizable", "Error. No more video are allowed in this group call.", fallback: "You are not allowed to enable video as this call has reached the maximum number of participants using video.")
    }
    public enum FreeUpSomeSpaceByDeletingAppsYouNoLongerUseOrLargeVideoFilesInYourGallery {
      /// Dialog description for the no enough device storage screen
      public static func youCanManageYourStorageIn(_ p1: Any) -> String {
        return Strings.tr("Localizable", "Free up some space by deleting apps you no longer use or large video files in your gallery. You can manage your storage in %@", String(describing: p1), fallback: "Free up some space by deleting apps you no longer use or large video files in your gallery. You can manage your storage in %@")
      }
    }
    public enum GetFreeWhenYouAddYourPhoneNumber {
      /// Free storage description to encourage users to add phone number to their accounts
      public static func thisMakesItEasierForYourContactsToFindYouOnMEGA(_ p1: Any) -> String {
        return Strings.tr("Localizable", "Get free %@ when you add your phone number. This makes it easier for your contacts to find you on MEGA.", String(describing: p1), fallback: "Get %@ free when you add your phone number. This makes it easier for your contacts to find you on MEGA.")
      }
    }
    public enum MEGANeedsAMinimumOf {
      public enum FreeUpSomeSpaceByDeletingAppsYouNoLongerUseOrLargeVideoFilesInYourGallery {
        /// Message shown when you try to downlonad files bigger than the available memory.
        public static func youCanAlsoManageWhatMEGAStoresOnYourDevice(_ p1: Any) -> String {
          return Strings.tr("Localizable", "MEGA needs a minimum of %@. Free up some space by deleting apps you no longer use or large video files in your gallery. You can also manage what MEGA stores on your device.", String(describing: p1), fallback: "MEGA needs a minimum of %@. Free up some space by deleting apps you no longer use or large video files in your gallery. You can also manage what MEGA stores on your device.")
        }
      }
    }
    public enum NowYouCanChooseToConvertTheHEIFHEVCPhotosAndVideosToTheMostCompatibleJPEGH {
      /// A messge for camera upload v2 migration
      public static let _264Formats = Strings.tr("Localizable", "Now you can choose to convert the HEIF/HEVC photos and videos to the most compatible JPEG/H.264 formats.", fallback: "Now you can choose to convert HEIC/HEVC photos and videos to the more widely compatible JPEG/H.264 formats.")
    }
    public enum OurEndToEndEncryptionSystemRequiresAUniqueKeyAutomaticallyGeneratedForThisFile {
      /// Export links dialog -> Keys tip about links and keys.
      public static let aLinkWithThisKeyIsCreatedByDefaultButYouCanExportTheDecryptionKeySeparatelyForAnAddedLayerOfSecurity = Strings.tr("Localizable", "Our end-to-end encryption system requires a unique key automatically generated for this file. A link with this key is created by default, but you can export the decryption key separately for an added layer of security.", fallback: "Our zero-knowledge encryption system requires a unique key automatically generated for this file or folder. A link with this key is created by default, but you can export the decryption key separately for an added layer of security.")
    }
    public enum PleaseGoToThePrivacySectionInYourDeviceSSetting {
      /// Hint shown to the users, when they want to use the Location Services but they are disabled or restricted for MEGA
      public static let enableLocationServicesAndSetMEGAToWhileUsingTheAppOrAlways = Strings.tr("Localizable", "Please go to the Privacy section in your device’s Setting. Enable Location Services and set MEGA to While Using the App or Always.", fallback: "Please go to the Privacy section in your device’s Settings. Enable Location Services and set MEGA to While Using the App or Always.")
    }
    public enum TheMEGAAppMayNotWorkAsExpectedWithoutTheRequiredPermissions {
      /// Message warning the user about the risk of not setting up permissions
      public static let areYouSure = Strings.tr("Localizable", "The MEGA app may not work as expected without the required permissions. Are you sure?", fallback: "The MEGA App may not work as expected without the required permissions. Are you sure?")
    }
    public enum TheRubbishBinCanBeCleanedForYouAutomatically {
      /// New server-side rubbish-bin cleaning scheduler description (for PRO users)
      public static let theMinimumPeriodIs7Days = Strings.tr("Localizable", "The Rubbish Bin can be cleaned for you automatically. The minimum period is 7 days.", fallback: "The Rubbish bin can be emptied for you automatically. The minimum period is 7 days.")
    }
    public enum TheRubbishBinIsCleanedForYouAutomatically {
      /// New server-side rubbish-bin cleaning scheduler description (for Free users)
      public static let theMinimumPeriodIs7DaysAndYourMaximumPeriodIs30Days = Strings.tr("Localizable", "The Rubbish Bin is cleaned for you automatically. The minimum period is 7 days and your maximum period is 30 days.", fallback: "The Rubbish bin is emptied for you automatically. The minimum period is 7 days and the maximum period is 30 days.")
    }
    public enum ThereHasBeenAProblemProcessingYourPayment {
      /// Details shown when a Business account is expired. Details for the administrator of the Business account
      public static let megaIsLimitedToViewOnlyUntilThisIssueHasBeenFixedInADesktopWebBrowser = Strings.tr("Localizable", "There has been a problem processing your payment. MEGA is limited to view only until this issue has been fixed in a desktop web browser.", fallback: "Your Business account has been deactivated due to payment failure. You won’t be able to access the data stored in your account. To make a payment and reactivate your subscription, log in to MEGA through a browser.")
    }
    public enum ThereHasBeenAProblemWithYourLastPayment {
      /// When logging in during the grace period, the administrator of the Business account will be notified that their payment is overdue, indicating that they need to access MEGA using a desktop browser for more information
      public static let pleaseAccessMEGAUsingADesktopBrowserForMoreInformation = Strings.tr("Localizable", "There has been a problem with your last payment. Please access MEGA using a desktop browser for more information.", fallback: "There has been a problem with your last payment. Please access MEGA using a desktop browser for more information.")
    }
    public enum ThereIsAnActiveCall {
      /// Message shown in a chat room when there is an active call
      public static let tapToJoin = Strings.tr("Localizable", "There is an active call. Tap to join.", fallback: "There is an active call. Tap to join.")
    }
    public enum ThereIsAnActiveGroupCall {
      /// Message shown in a chat room when there is an active group call
      public static let tapToJoin = Strings.tr("Localizable", "There is an active group call. Tap to join.", fallback: "There is an active group call. Tap to join.")
    }
    public enum ThisLinkIsNotRelatedToThisAccount {
      /// Error message shown when opening a link with an account that not corresponds to the link
      public static let pleaseLogInWithTheCorrectAccount = Strings.tr("Localizable", "This link is not related to this account. Please log in with the correct account.", fallback: "This link is not related to this account. Please log in with the correct account.")
    }
    public enum ThisLinkWasSharedWithoutADecryptionKey {
      /// Message shown when a link is shared with separated key
      public static let doYouWantToShareItsKey = Strings.tr("Localizable", "This link was shared without a decryption key. Do you want to share its key?", fallback: "This link was shared without a decryption key. Do you want to share its key?")
    }
    public enum ThisWillRemoveYourAssociatedPhoneNumberFromYourAccount {
      /// Message for action to remove the registered phone number.
      public static let ifYouLaterChooseToAddAPhoneNumberYouWillBeRequiredToVerifyIt = Strings.tr("Localizable", "This will remove your associated phone number from your account. If you later choose to add a phone number you will be required to verify it.", fallback: "This will remove your associated phone number from your account. If you later choose to add a phone number you will be required to verify it.")
    }
    public enum WeRecommendH {
      /// Footer for HEVC format section
      public static let _264AsItsTheMostCompatibleFormatForVideos = Strings.tr("Localizable", "We recommend H.264, as its the most compatible format for videos.", fallback: "We recommend H.264, as it is the most compatible format for videos.")
    }
    public enum WhenFileVersioningIsDisabledTheCurrentVersionWillBeReplacedWithTheNewVersionOnceAFileIsUpdatedAndYourChangesToTheFileWillNoLongerBeRecorded {
      /// A confirmation message when the user chooses to disable file versioning.
      public static let areYouSureYouWantToDisableFileVersioning = Strings.tr("Localizable", "When file versioning is disabled, the current version will be replaced with the new version once a file is updated (and your changes to the file will no longer be recorded). Are you sure you want to disable file versioning?", fallback: "When file versioning is disabled, the current version will be replaced with the new version once a file is updated (and your changes to the file will no longer be recorded). Are you sure you want to disable file versioning?")
    }
    public enum WrongCode {
      /// Error message that will show to user when user entered invalid verification code
      public static let pleaseTryAgainOrResend = Strings.tr("Localizable", "Wrong code. Please try again or resend.", fallback: "Wrong code. Please try again or resend.")
    }
    public enum YouAreAboutToDeleteTheVersionHistoriesOfAllFiles {
      public enum AnyFileVersionSharedToYouFromAContactWillNeedToBeDeletedByThem {
        /// Text of the dialog to delete all the file versions of the account
        public static let brBrPleaseNoteThatTheCurrentFilesWillNotBeDeleted = Strings.tr("Localizable", "You are about to delete the version histories of all files. Any file version shared to you from a contact will need to be deleted by them.[Br][Br]Please note that the current files will not be deleted.", fallback: "You are about to delete the version histories of all files. Any file version shared to you from a contact will need to be deleted by them.\n\nPlease note that the current files will not be deleted.")
      }
    }
    public enum YouCanNowSelectWhichSectionTheAppOpensAtLaunch {
      /// Dialog description for the change launch tab screen
      public static let chooseTheOneThatBetterSuitsYourNeedsWhetherItSChatCloudDriveOrHome = Strings.tr("Localizable", "You can now select which section the app opens at launch. Choose the one that better suits your needs, whether it’s Chat, Cloud Drive, or Home.", fallback: "You can now select which section the app opens at launch. Choose the one that better suits your needs, whether it’s Chat, Cloud drive, or Home.")
    }
    public enum YouDoNotHaveEnoughStorageToUploadCamera {
      public enum FreeUpSpaceByDeletingUnneededAppsVideosOrMusic {
        /// Detail for local storage full situation
        public static func youCanManageYourStorageIn(_ p1: Any) -> String {
          return Strings.tr("Localizable", "You do not have enough storage to upload camera. Free up space by deleting unneeded apps, videos or music. You can manage your storage in %@", String(describing: p1), fallback: "You do not have enough storage for further camera uploads. Free up space by deleting unneeded apps, videos or music. You can manage your storage in %@")
        }
      }
    }
    public enum YouDoNotHaveThePermissionsRequiredToRevertThisFile {
      public enum InOrderToContinueWeCanCreateANewFileWithTheRevertedData {
        /// Confirmation dialog shown to user when they try to revert a node in an incoming ReadWrite share.
        public static let wouldYouLikeToProceed = Strings.tr("Localizable", "You do not have the permissions required to revert this file. In order to continue, we can create a new file with the reverted data. Would you like to proceed?", fallback: "You do not have the permissions required to revert this file. In order to continue, we can create a new file with the reverted data. Would you like to proceed?")
      }
    }
    public enum YouNeedAnAuthenticatorAppToEnable2FAOnMEGA {
      /// Alert text shown when enabling Two-Factor Authentication when you don't have a two factor authentication app installed on the device and tap on the question mark
      public static let youCanDownloadAndInstallTheGoogleAuthenticatorDuoMobileAuthyOrMicrosoftAuthenticatorAppForYourPhoneOrTablet = Strings.tr("Localizable", "You need an authenticator app to enable 2FA on MEGA. You can download and install the Google Authenticator, Duo Mobile, Authy or Microsoft Authenticator app for your phone or tablet.", fallback: "You need an authenticator app to enable 2FA on MEGA. You can download and install the Google authenticator, Duo Mobile, Authy or Microsoft authenticator app for your phone or tablet.")
    }
    public enum YourAccountHasBeenDisabledByYourAdministrator {
      /// Error message appears to sub-users of a business account when they try to login and they are disabled.
      public static let pleaseContactYourBusinessAccountAdministratorForFurtherDetails = Strings.tr("Localizable", "Your account has been disabled by your administrator. Please contact your business account administrator for further details.", fallback: "Your account has been deactivated by your administrator. Please contact your Business account administrator for further details.")
    }
    public enum YourAccountHasBeenRemovedByYourAdministrator {
      /// An error message which appears to sub-users of a business account when they try to login and they are deleted.
      public static let pleaseContactYourBusinessAccountAdministratorForFurtherDetails = Strings.tr("Localizable", "Your account has been removed by your administrator. Please contact your business account administrator for further details.", fallback: "Your account has been removed by your administrator. Please contact your Business account administrator for further details.")
    }
    public enum YourAccountHasBeenSuspendedTemporarilyDueToPotentialAbuse {
      /// Description to unblock account by verifying phone number
      public static let pleaseVerifyYourPhoneNumberToUnlockYourAccount = Strings.tr("Localizable", "Your account has been suspended temporarily due to potential abuse. Please verify your phone number to unlock your account.", fallback: "Your account has been locked temporarily due to potential abuse. Please verify your phone number to unlock your account.")
    }
    public enum YourAccountIsCurrentlyBSuspendedB {
      /// A dialog message which is shown to sub-users of expired business accounts.
      public static let youCanOnlyBrowseYourData = Strings.tr("Localizable", "Your account is currently [B]suspended[/B]. You can only browse your data.", fallback: "Your account is currently [B]suspended[/B]. You can only browse your data.")
    }
    public enum YourConfirmationLinkIsNoLongerValid {
      /// 
      public static let yourAccountMayAlreadyBeActivatedOrYouMayHaveCancelledYourRegistration = Strings.tr("Localizable", "Your confirmation link is no longer valid. Your account may already be activated or you may have cancelled your registration.", fallback: "Your confirmation link is no longer valid. Your account may already be activated or you may have cancelled your registration.")
    }
    public enum A1SABChangedTheMessageClearingTimeToBA2SAB {
      /// System message displayed to all chat participants when one of them enables retention history
      public static func b(_ p1: UnsafePointer<CChar>, _ p2: UnsafePointer<CChar>) -> String {
        return Strings.tr("Localizable", "[A]%1$s[/A][B] changed the message clearing time to[/B][A] %2$s[/A][B].[/B]", p1, p2, fallback: "[A]%1$s[/A][B] changed the message clearing time to[/B][A] %2$s[/A][B].[/B]")
      }
    }
    public enum A1SABDisabledMessageClearing {
      /// System message that is shown to all chat participants upon disabling the Retention history.
      public static func b(_ p1: UnsafePointer<CChar>) -> String {
        return Strings.tr("Localizable", "[A]%1$s[/A][B] disabled message clearing.[/B]", p1, fallback: "[A]%1$s[/A][B] disabled message clearing.[/B]")
      }
    }
    public enum AGroupCallEndedAC {
      /// When an active goup call is ended, shows the duration
      public static let durationC = Strings.tr("Localizable", "[A]Group call ended[/A][C]. Duration: [/C]", fallback: "[A]Group call ended[/A][C]. Duration: [/C]")
    }
    public enum Account {
      /// Text listed that includes the amount of storage that a user gets with a certain package. For example: '2 TB Storage'.
      public static func storageQuota(_ p1: Any) -> String {
        return Strings.tr("Localizable", "account.storageQuota", String(describing: p1), fallback: "%@ storage")
      }
      public enum Achievement {
        public enum Complete {
          public enum ValidBonusExpiry {
            public enum Detail {
              /// Plural format key: "%#@days@"
              public static func subtitle(_ p1: Int) -> String {
                return Strings.tr("Localizable", "account.achievement.complete.validBonusExpiry.detail.subtitle", p1, fallback: "Plural format key: \"%#@days@\"")
              }
            }
          }
          public enum ValidDays {
            /// Plural format key: "%#@days@"
            public static func subtitle(_ p1: Int) -> String {
              return Strings.tr("Localizable", "account.achievement.complete.validDays.subtitle", p1, fallback: "Plural format key: \"%#@days@\"")
            }
          }
        }
        public enum DesktopApp {
          /// Cell title shown on the achievements view for install MEGA desktop app achievement
          public static let title = Strings.tr("Localizable", "account.achievement.desktopApp.title", fallback: "Install the MEGA Desktop App")
          public enum Complete {
            public enum Explaination {
              /// Explanation label shown on the achievements view for complete install MEGA desktop app achievement, %@ is a placeholder.
              public static func label(_ p1: Any) -> String {
                return Strings.tr("Localizable", "account.achievement.desktopApp.complete.explaination.label", String(describing: p1), fallback: "You have received %@ storage space for installing the MEGA Desktop App.")
              }
            }
          }
          public enum Incomplete {
            public enum Explaination {
              /// Explanation label shown on the achievements view for incomplete install MEGA desktop app achievement, %@ is a placeholder.
              public static func label(_ p1: Any) -> String {
                return Strings.tr("Localizable", "account.achievement.desktopApp.incomplete.explaination.label", String(describing: p1), fallback: "When you install the MEGA Desktop App you get %@ of complimentary storage space, valid for 365 days. The MEGA Desktop App is available for Windows, macOS and most Linux distributions.")
              }
            }
          }
        }
        public enum Incomplete {
          /// Subtitle of the incomplete achievement, %@ is a placeholder.
          public static func subtitle(_ p1: Any) -> String {
            return Strings.tr("Localizable", "account.achievement.incomplete.subtitle", String(describing: p1), fallback: "%@ of storage. Valid for 365 days.")
          }
        }
        public enum MobileApp {
          /// Cell title shown on the achievements view for install MEGA mobile app achievement
          public static let title = Strings.tr("Localizable", "account.achievement.mobileApp.title", fallback: "Install the MEGA Mobile App")
          public enum Complete {
            public enum Explaination {
              /// Explanation label shown on the achievements view for complete install MEGA mobile app achievement, %@ is a placeholder.
              public static func label(_ p1: Any) -> String {
                return Strings.tr("Localizable", "account.achievement.mobileApp.complete.explaination.label", String(describing: p1), fallback: "You have received %@ storage space for installing the MEGA mobile app.")
              }
            }
          }
          public enum Incomplete {
            public enum Explaination {
              /// Explanation label shown on the achievements view for incomplete install MEGA mobile app achievement, %@ is a placeholder.
              public static func label(_ p1: Any) -> String {
                return Strings.tr("Localizable", "account.achievement.mobileApp.incomplete.explaination.label", String(describing: p1), fallback: "When you install the MEGA Mobile App you get %@ of complimentary storage space, valid for 365 days. The MEGA Mobile App is available for iOS and Android. ")
              }
            }
          }
        }
        public enum PhoneNumber {
          public enum Complete {
            public enum Explaination {
              /// Explanation Label shown on the achievements view for complete add phone number achievement, %@ is a placeholder.
              public static func label(_ p1: Any) -> String {
                return Strings.tr("Localizable", "account.achievement.phoneNumber.complete.explaination.label", String(describing: p1), fallback: "You have received %@ storage space for adding your phone number.")
              }
            }
          }
          public enum Incomplete {
            public enum Explaination {
              /// Explanation Label shown on the achievements view for incomplete add phone number achievement, %@ is a placeholder.
              public static func label(_ p1: Any) -> String {
                return Strings.tr("Localizable", "account.achievement.phoneNumber.incomplete.explaination.label", String(describing: p1), fallback: "When you add your phone number you get %@ of complimentary storage space, valid for 365 days.")
              }
            }
          }
        }
        public enum Referral {
          /// Subtitle of the referral achievement introduction, %@ is a placeholder.
          public static func subtitle(_ p1: Any) -> String {
            return Strings.tr("Localizable", "account.achievement.referral.subtitle", String(describing: p1), fallback: "%@ of storage for each referral. \nValid for 365 days.")
          }
          /// Cell title shown on the achievements view for referral achievement
          public static let title = Strings.tr("Localizable", "account.achievement.referral.title", fallback: "Invite your friends")
        }
        public enum ReferralBonus {
          /// Cell title shown on the achievements view for referral achievement
          public static let title = Strings.tr("Localizable", "account.achievement.referralBonus.title", fallback: "Referral bonuses")
        }
        public enum Registration {
          /// Cell title shown on the achievements view for registration achievement
          public static let title = Strings.tr("Localizable", "account.achievement.registration.title", fallback: "Registration bonus")
          public enum Explanation {
            /// Label shown on the achievements view for complete registration achievement, %@ is a placeholder.
            public static func label(_ p1: Any) -> String {
              return Strings.tr("Localizable", "account.achievement.registration.explanation.label", String(describing: p1), fallback: "You have received %@ storage space as your free registration bonus.")
            }
          }
        }
      }
      public enum ChangeEmail {
        /// Hint text to display user's current email
        public static let currentEmail = Strings.tr("Localizable", "account.changeEmail.currentEmail", fallback: "Current email address")
      }
      public enum ChangePassword {
        public enum Error {
          /// Account, Change Password view. Error shown when you type your current password.
          public static let currentPassword = Strings.tr("Localizable", "account.changePassword.error.currentPassword", fallback: "You have entered your current password.")
        }
      }
      public enum CreateAccount {
        /// Message for login option on Create Account screen
        public static let alreadyHaveAnAccount = Strings.tr("Localizable", "account.createAccount.alreadyHaveAnAccount", fallback: "Already have an account?")
      }
      public enum Delete {
        public enum Subscription {
          /// Dialog message shown before deleting an account with active Google play subscription
          public static let googlePlay = Strings.tr("Localizable", "account.delete.subscription.googlePlay", fallback: "You have an active MEGA subscription with Google. You must cancel it separately in Google Play, as MEGA is not able to cancel it for you. Visit our Help Centre for more information.")
          /// Dialog message shown before deleting an account with active Huawei AppGallery subscription
          public static let huaweiAppGallery = Strings.tr("Localizable", "account.delete.subscription.huaweiAppGallery", fallback: "You have an active MEGA subscription with Huawei. You must cancel it separately at Huawei AppGallery, as MEGA is not able to cancel it for you. Visit our Help Centre for more information.")
          /// Dialog message shown before deleting an account with active iTunes subscription
          public static let itunes = Strings.tr("Localizable", "account.delete.subscription.itunes", fallback: "You have an active MEGA subscription with Apple. You must cancel it separately at Subscriptions, as MEGA is not able to cancel it for you. Visit our Help Centre for more information.")
          /// Dialog title shown before deleting an account with active subscription
          public static let title = Strings.tr("Localizable", "account.delete.subscription.title", fallback: "Active subscription")
          /// Dialog message shown before deleting an account with active webclient subscription
          public static let webClient = Strings.tr("Localizable", "account.delete.subscription.webClient", fallback: "This is the last step to delete your account. Both your account and subscription will be deleted and you will permanently lose all the data stored in the cloud. Please enter your password below.")
          public enum GooglePlay {
            /// Dialog button title which triggers the action to visit Google play
            public static let visit = Strings.tr("Localizable", "account.delete.subscription.googlePlay.visit", fallback: "Visit Google Play")
          }
          public enum HuaweiAppGallery {
            /// Dialog button title which triggers the action to visit Huawei app gallery
            public static let visit = Strings.tr("Localizable", "account.delete.subscription.huaweiAppGallery.visit", fallback: "Visit AppGallery")
          }
          public enum Itunes {
            /// Dialog button title which triggers the action to visit AppStore Subscriptions
            public static let manage = Strings.tr("Localizable", "account.delete.subscription.itunes.manage", fallback: "Manage subscriptions")
          }
        }
      }
      public enum Expired {
        public enum ProFlexi {
          /// Content message of expired Pro Flexi account view
          public static let message = Strings.tr("Localizable", "account.expired.proFlexi.message", fallback: "Your Pro Flexi account has been deactivated due to payment failure or you’ve cancelled your subscription. You won’t be able to access the data stored in your account. To make a payment and reactivate your subscription, log in to MEGA through a browser.")
          /// Content title of expired Pro Flexi account view
          public static let title = Strings.tr("Localizable", "account.expired.proFlexi.title", fallback: "Account deactivated")
        }
      }
      public enum Login {
        /// Message on login screen for Create Account
        public static let newToMega = Strings.tr("Localizable", "account.login.newToMega", fallback: "New to MEGA?")
      }
      public enum Profile {
        public enum Avatar {
          /// Button that allows the user to upload a photo, e.g. his avatar photo
          public static let uploadPhoto = Strings.tr("Localizable", "account.profile.avatar.uploadPhoto", fallback: "Upload photo")
        }
      }
      public enum Storage {
        /// Text listed that includes the amount of storage that a free user gets: '20GB+ Storage'
        public static let freePlan = Strings.tr("Localizable", "account.storage.freePlan", fallback: "[B]20 GB+[/B] Storage")
        public enum StorageUsed {
          /// Account Storage title label of used storage size
          public static let title = Strings.tr("Localizable", "account.storage.storageUsed.title", fallback: "Storage used")
        }
        public enum TransferUsed {
          /// Account Storage title label of used transfer size
          public static let title = Strings.tr("Localizable", "account.storage.transferUsed.title", fallback: "Transfer used")
        }
      }
      public enum Suspension {
        public enum Message {
          /// Error message when trying to login and the account is blocked due to copyright violation
          public static let copyright = Strings.tr("Localizable", "account.suspension.message.copyright", fallback: "Your MEGA account has been suspended due to repeated allegations of copyright infringements. This means you cannot access your account or data within it.\n\nCheck your email for more information on how to file a counter-notice.")
          /// Error message when trying to login and the account is blocked due to any type of suspension, but copyright suspension
          public static let nonCopyright = Strings.tr("Localizable", "account.suspension.message.nonCopyright", fallback: "Your account was terminated due to a breach of MEGA’s Terms of Service.\n\nYou will not be able to regain access to your stored data or be authorised to register a new MEGA account.")
        }
      }
      public enum TransferQuota {
        /// Text listed that explain that a free user gets a limited amount of transfer quota.
        public static let freePlan = Strings.tr("Localizable", "account.transferQuota.freePlan", fallback: "[B]Limited[/B] transfer")
        /// Text listed that includes the amount of transfer quota a user gets per month with a certain package. For example: '8 TB Transfer'.
        public static func perMonth(_ p1: Any) -> String {
          return Strings.tr("Localizable", "account.transferQuota.perMonth", String(describing: p1), fallback: "%@ transfer")
        }
      }
      public enum Upgrade {
        public enum AlreadyHaveACancellableSubscription {
          /// Dialog message shown to allow the user to cancel their current subscription activated from another platform and continue with the purchase.
          public static let message = Strings.tr("Localizable", "account.upgrade.alreadyHaveACancellableSubscription.message", fallback: "Do you want to cancel your current subscription and continue with the purchase?")
        }
        public enum AlreadyHaveASubscription {
          /// Dialog message shown when a user tries to purchase a subscriptions while having a subscription activated from another platform.
          public static let message = Strings.tr("Localizable", "account.upgrade.alreadyHaveASubscription.message", fallback: "You have previously subscribed to a Pro plan with Google Play or AppGallery. Please manually cancel your subscription with them inside Google Play or the Huawei AppGallery on your device and then retry.")
          /// Dialog title shown when a user tries to purchase a subscription while having a subscription activated from another platform.
          public static let title = Strings.tr("Localizable", "account.upgrade.alreadyHaveASubscription.title", fallback: "You already have an active subscription")
        }
        public enum NotAvailableWithCurrentPlan {
          /// Error message shown when a user tries to purchase plan that is not available with their current plan
          public static let message = Strings.tr("Localizable", "account.upgrade.notAvailableWithCurrentPlan.message", fallback: "Not available with your current plan")
        }
      }
      public enum UpgradeSecurity {
        /// Upgrade security alert screen title. For cryptographic security upgrade which will be shown only once per account.
        public static let title = Strings.tr("Localizable", "account.upgradeSecurity.title", fallback: "Account security upgrade")
        public enum Button {
          /// Upgrade security alert screen button title. For cryptographic security upgrade which will be shown only once per account.
          public static let title = Strings.tr("Localizable", "account.upgradeSecurity.button.title", fallback: "OK, got it")
        }
        public enum Message {
          /// Plural format key: "%#@folderNames@"
          public static func sharedFolderNames(_ p1: Int) -> String {
            return Strings.tr("Localizable", "account.upgradeSecurity.message.sharedFolderNames", p1, fallback: "Plural format key: \"%#@folderNames@\"")
          }
          /// Upgrade security alert screen message. For cryptographic security upgrade which will be shown only once per account.
          public static let upgrade = Strings.tr("Localizable", "account.upgradeSecurity.message.upgrade", fallback: "We’re upgrading your account’s security. You should see this message only once. If you’ve seen it before, first make sure it has been for this account and not for another MEGA account you have.\n\nIf you’re sure and it’s the second time you’re seeing this message for this account, stop using this account.")
        }
      }
    }
    public enum AlbumLink {
      public enum Alert {
        public enum Message {
          /// Album failed to save to cloud drive alert message
          public static func albumFailedToSaveToCloudDrive(_ p1: Any) -> String {
            return Strings.tr("Localizable", "albumLink.alert.message.albumFailedToSaveToCloudDrive", String(describing: p1), fallback: "“%@” can’t be saved to Cloud drive. Try again later and if the problem continues, contact the person who shared the link with you.")
          }
          /// Album saved to cloud drive alert message
          public static func albumSavedToCloudDrive(_ p1: Any) -> String {
            return Strings.tr("Localizable", "albumLink.alert.message.albumSavedToCloudDrive", String(describing: p1), fallback: "“%@” saved to Cloud drive")
          }
          /// Plural format key: "%#@count@"
          public static func filesSaveToCloudDrive(_ p1: Int) -> String {
            return Strings.tr("Localizable", "albumLink.alert.message.filesSaveToCloudDrive", p1, fallback: "Plural format key: \"%#@count@\"")
          }
        }
        public enum RenameAlbum {
          /// Rename public album alert message
          public static func message(_ p1: Any) -> String {
            return Strings.tr("Localizable", "albumLink.alert.renameAlbum.message", String(describing: p1), fallback: "An album named “%@” already exists in your Albums. Enter a new name for the album you’re saving.")
          }
          /// Rename public album alert title
          public static let title = Strings.tr("Localizable", "albumLink.alert.renameAlbum.title", fallback: "Rename album")
        }
      }
      public enum ImportFailed {
        public enum StorageQuotaWillExceed {
          public enum Alert {
            /// Importing albums Failed modal because storage quota would exceed alert detail
            public static let detail = Strings.tr("Localizable", "albumLink.importFailed.storageQuotaWillExceed.alert.detail", fallback: "You don’t have enough storage to save this album to your Cloud drive. Upgrade now to get more storage.")
            /// Importing albums Failed modal because storage quota would exceed alert title
            public static let title = Strings.tr("Localizable", "albumLink.importFailed.storageQuotaWillExceed.alert.title", fallback: "Cannot save album")
          }
        }
      }
      public enum InvalidAlbum {
        public enum Alert {
          /// Alert dismiss button title for invalid album link
          public static let dissmissButtonTitle = Strings.tr("Localizable", "albumLink.invalidAlbum.alert.dissmissButtonTitle", fallback: "OK, got it")
          /// Alert message for invalid album link
          public static let message = Strings.tr("Localizable", "albumLink.invalidAlbum.alert.message", fallback: "The link to the album has been removed or the album has been deleted. Contact the person who shared the link with you.")
          /// Alert title for invalid album link
          public static let title = Strings.tr("Localizable", "albumLink.invalidAlbum.alert.title", fallback: "Cannot access album")
        }
      }
    }
    public enum AutoAway {
      /// Footer text to explain the meaning of the functionaly 'Auto-away' of your chat status.
      public static let footerDescription = Strings.tr("Localizable", "autoAway.footerDescription", fallback: "Set status as Away after [X] of inactivity.")
    }
    public enum Backups {
      /// Backups title
      public static let title = Strings.tr("Localizable", "backups.title", fallback: "Backups")
      public enum Empty {
        public enum State {
          /// No backups and old inbox files in the account description message
          public static let description = Strings.tr("Localizable", "backups.empty.state.description", fallback: "This is where your backed up files and folders are stored. Your backed up items are “read-only” to protect them from being accidentally modified in your Cloud drive.\nYou can back up items from your computer to MEGA using our desktop app.")
          /// No backups and old inbox files in the account message
          public static let message = Strings.tr("Localizable", "backups.empty.state.message", fallback: "No items in backups")
        }
      }
    }
    public enum Call {
      public enum Duration {
        /// Plural format key: "%#@hour@"
        public static func hour(_ p1: Int) -> String {
          return Strings.tr("Localizable", "call.duration.hour", p1, fallback: "Plural format key: \"%#@hour@\"")
        }
        /// Plural format key: "%#@minute@"
        public static func minute(_ p1: Int) -> String {
          return Strings.tr("Localizable", "call.duration.minute", p1, fallback: "Plural format key: \"%#@minute@\"")
        }
        /// Plural format key: "%#@second@"
        public static func second(_ p1: Int) -> String {
          return Strings.tr("Localizable", "call.duration.second", p1, fallback: "Plural format key: \"%#@second@\"")
        }
        public enum HourAndMinute {
          /// Plural format key: "%#@hour@"
          public static func hour(_ p1: Int) -> String {
            return Strings.tr("Localizable", "call.duration.hourAndMinute.hour", p1, fallback: "Plural format key: \"%#@hour@\"")
          }
          /// Plural format key: "%#@minute@"
          public static func minute(_ p1: Int) -> String {
            return Strings.tr("Localizable", "call.duration.hourAndMinute.minute", p1, fallback: "Plural format key: \"%#@minute@\"")
          }
        }
      }
    }
    public enum CameraUploads {
      public enum Albums {
        /// Plural format key: "%#@count@"
        public static func addedItemTo(_ p1: Int) -> String {
          return Strings.tr("Localizable", "cameraUploads.albums.addedItemTo", p1, fallback: "Plural format key: \"%#@count@\"")
        }
        /// Used as a hud message in album content screen.
        public static let albumCoverUpdated = Strings.tr("Localizable", "cameraUploads.albums.albumCoverUpdated", fallback: "Album cover updated")
        /// Plural format key: "%#@count@"
        public static func delete(_ p1: Int) -> String {
          return Strings.tr("Localizable", "cameraUploads.albums.delete", p1, fallback: "Plural format key: \"%#@count@\"")
        }
        /// Plural format key: "%#@count@"
        public static func deleteAlbumMessage(_ p1: Int) -> String {
          return Strings.tr("Localizable", "cameraUploads.albums.deleteAlbumMessage", p1, fallback: "Plural format key: \"%#@count@\"")
        }
        /// Plural format key: "%#@count@"
        public static func deleteAlbumSuccess(_ p1: Int) -> String {
          return Strings.tr("Localizable", "cameraUploads.albums.deleteAlbumSuccess", p1, fallback: "Plural format key: \"%#@count@\"")
        }
        /// Plural format key: "%#@count@"
        public static func deleteAlbumTitle(_ p1: Int) -> String {
          return Strings.tr("Localizable", "cameraUploads.albums.deleteAlbumTitle", p1, fallback: "Plural format key: \"%#@count@\"")
        }
        /// Plural format key: "%#@count@"
        public static func removedItemFrom(_ p1: Int) -> String {
          return Strings.tr("Localizable", "cameraUploads.albums.removedItemFrom", p1, fallback: "Plural format key: \"%#@count@\"")
        }
        /// Plural format key: "%#@count@"
        public static func removeShareLinkAlertConfirmButtonTitle(_ p1: Int) -> String {
          return Strings.tr("Localizable", "cameraUploads.albums.removeShareLinkAlertConfirmButtonTitle", p1, fallback: "Plural format key: \"%#@count@\"")
        }
        /// Plural format key: "%#@count@"
        public static func removeShareLinkAlertMessage(_ p1: Int) -> String {
          return Strings.tr("Localizable", "cameraUploads.albums.removeShareLinkAlertMessage", p1, fallback: "Plural format key: \"%#@count@\"")
        }
        /// Plural format key: "%#@count@"
        public static func removeShareLinkAlertTitle(_ p1: Int) -> String {
          return Strings.tr("Localizable", "cameraUploads.albums.removeShareLinkAlertTitle", p1, fallback: "Plural format key: \"%#@count@\"")
        }
        /// Plural format key: "%#@count@"
        public static func removeShareLinkSuccessMessage(_ p1: Int) -> String {
          return Strings.tr("Localizable", "cameraUploads.albums.removeShareLinkSuccessMessage", p1, fallback: "Plural format key: \"%#@count@\"")
        }
        /// Used as a context menu item on album content screen.
        public static let selectAlbumCover = Strings.tr("Localizable", "cameraUploads.albums.selectAlbumCover", fallback: "Select album cover")
        /// Albums title within CU tab
        public static let title = Strings.tr("Localizable", "cameraUploads.albums.title", fallback: "Albums")
        public enum AddItems {
          public enum Alert {
            public enum LimitReached {
              /// Plural format key: "%#@count@"
              public static func message(_ p1: Int) -> String {
                return Strings.tr("Localizable", "cameraUploads.albums.addItems.alert.limitReached.message", p1, fallback: "Plural format key: \"%#@count@\"")
              }
              /// Alert title shown when adding photos once photo selection limit reached.
              public static let title = Strings.tr("Localizable", "cameraUploads.albums.addItems.alert.limitReached.title", fallback: "Cannot select more")
            }
          }
        }
        public enum Create {
          /// Used in add content album view.
          public static func addItemsTo(_ p1: Any) -> String {
            return Strings.tr("Localizable", "cameraUploads.albums.create.addItemsTo", String(describing: p1), fallback: "Add items to “%@”")
          }
          public enum Alert {
            /// Used in create album popup system album name validation
            public static let albumNameNotAllowed = Strings.tr("Localizable", "cameraUploads.albums.create.alert.albumNameNotAllowed", fallback: "This album name is not allowed")
            /// Used in create album popup album name validation
            public static let enterDifferentName = Strings.tr("Localizable", "cameraUploads.albums.create.alert.enterDifferentName", fallback: "Enter a different name.")
            /// Used in create album popup album name validation
            public static let enterNewName = Strings.tr("Localizable", "cameraUploads.albums.create.alert.enterNewName", fallback: "Enter a new name.")
            /// Used in create album popup.
            public static let placeholder = Strings.tr("Localizable", "cameraUploads.albums.create.alert.placeholder", fallback: "New album")
            /// Used in create album popup.
            public static let title = Strings.tr("Localizable", "cameraUploads.albums.create.alert.title", fallback: "Enter album name")
            /// Used in create album popup user album name validation
            public static let userAlbumExists = Strings.tr("Localizable", "cameraUploads.albums.create.alert.userAlbumExists", fallback: "An album with this name already exists.")
          }
        }
        public enum CreateAlbum {
          /// Create album title
          public static let title = Strings.tr("Localizable", "cameraUploads.albums.createAlbum.title", fallback: "Create album")
        }
        public enum Empty {
          /// Used in empty album view.
          public static let title = Strings.tr("Localizable", "cameraUploads.albums.empty.title", fallback: "Empty album")
        }
        public enum Favourites {
          /// Favourites album title
          public static let title = Strings.tr("Localizable", "cameraUploads.albums.favourites.title", fallback: "Favourites")
        }
        public enum Gif {
          /// Gif album title
          public static let title = Strings.tr("Localizable", "cameraUploads.albums.gif.title", fallback: "GIFs")
        }
        public enum MyAlbum {
          /// My album title
          public static let title = Strings.tr("Localizable", "cameraUploads.albums.myAlbum.title", fallback: "My albums")
        }
        public enum Raw {
          /// Raw album title
          public static let title = Strings.tr("Localizable", "cameraUploads.albums.raw.title", fallback: "RAW")
        }
        public enum RemovePhotos {
          public enum Alert {
            /// Used as a alert title when removing album photos.
            public static let title = Strings.tr("Localizable", "cameraUploads.albums.removePhotos.alert.title", fallback: "Remove from album?")
          }
        }
        public enum SharedAlbum {
          /// Shared album title
          public static let title = Strings.tr("Localizable", "cameraUploads.albums.sharedAlbum.title", fallback: "Shared albums")
        }
      }
      public enum Timeline {
        /// Timeline title within CU tab
        public static let title = Strings.tr("Localizable", "cameraUploads.timeline.title", fallback: "Timeline")
        public enum AllMedia {
          public enum Empty {
            /// Timeline empty with all media filter enable
            public static let title = Strings.tr("Localizable", "cameraUploads.timeline.allMedia.empty.title", fallback: "No media found")
          }
        }
        public enum Filter {
          /// Choose type headline within filter UI
          public static let chooseType = Strings.tr("Localizable", "cameraUploads.timeline.filter.chooseType", fallback: "Choose type")
          /// Filter UI remember preferences option
          public static let rememberPreferences = Strings.tr("Localizable", "cameraUploads.timeline.filter.rememberPreferences", fallback: "Remember preferences")
          /// Show items from headline within filter UI
          public static let showItemsFrom = Strings.tr("Localizable", "cameraUploads.timeline.filter.showItemsFrom", fallback: "Show items from:")
          public enum Location {
            /// Filter UI media location option
            public static let allLocations = Strings.tr("Localizable", "cameraUploads.timeline.filter.location.allLocations", fallback: "All locations")
            /// Filter UI media location option
            public static let cameraUploads = Strings.tr("Localizable", "cameraUploads.timeline.filter.location.cameraUploads", fallback: "Camera uploads")
            /// Filter UI media location option
            public static let cloudDrive = Strings.tr("Localizable", "cameraUploads.timeline.filter.location.cloudDrive", fallback: "Cloud drive")
          }
          public enum MediaType {
            /// Filter UI media type option
            public static let allMedia = Strings.tr("Localizable", "cameraUploads.timeline.filter.mediaType.allMedia", fallback: "All media")
            /// Filter UI media type option
            public static let images = Strings.tr("Localizable", "cameraUploads.timeline.filter.mediaType.images", fallback: "Images")
            /// Filter UI media type option
            public static let videos = Strings.tr("Localizable", "cameraUploads.timeline.filter.mediaType.videos", fallback: "Videos")
          }
        }
      }
      public enum VideoUploads {
        /// Video Uploads title
        public static let title = Strings.tr("Localizable", "cameraUploads.videoUploads.title", fallback: "Video uploads")
      }
      public enum Warning {
        /// Banner message on Camera Uploads that warns user that they have limited access to photos
        public static let limitedAccessToPhotoMessage = Strings.tr("Localizable", "cameraUploads.warning.limitedAccessToPhotoMessage", fallback: "⚠ MEGA has limited access to your photo library and cannot backup all of your photos. Tap to change permissions.")
      }
    }
    public enum Chat {
      /// Button title for incoming call with `initial`, `joining` and `userNoPresent` status
      public static let joinCall = Strings.tr("Localizable", "chat.joinCall", fallback: "Join call")
      /// Title for chats section
      public static let title = Strings.tr("Localizable", "chat.title", fallback: "Chat")
      public enum AddToChatMenu {
        /// Menu option from the `Add` section that allows the user to share files from Files app
        public static let filesApp = Strings.tr("Localizable", "chat.addToChatMenu.filesApp", fallback: "Files")
        /// Menu option from the `Add` section that allows the user to share files from scanning
        public static let scan = Strings.tr("Localizable", "chat.addToChatMenu.scan", fallback: "Scan")
      }
      public enum AutoAway {
        /// Plural format key: "%#@hour@"
        public static func hour(_ p1: Int) -> String {
          return Strings.tr("Localizable", "chat.autoAway.hour", p1, fallback: "Plural format key: \"%#@hour@\"")
        }
        /// Plural format key: "%#@minute@"
        public static func minute(_ p1: Int) -> String {
          return Strings.tr("Localizable", "chat.autoAway.minute", p1, fallback: "Plural format key: \"%#@minute@\"")
        }
        public enum Label {
          /// Plural format key: "%#@hour@"
          public static func hour(_ p1: Int) -> String {
            return Strings.tr("Localizable", "chat.autoAway.label.hour", p1, fallback: "Plural format key: \"%#@hour@\"")
          }
          /// Plural format key: "%#@minute@"
          public static func minute(_ p1: Int) -> String {
            return Strings.tr("Localizable", "chat.autoAway.label.minute", p1, fallback: "Plural format key: \"%#@minute@\"")
          }
        }
      }
      public enum BackButton {
        public enum OneToOne {
          /// Back button menu item title visible when navigating back to 1:1 chat  .
          public static func menu(_ p1: Any) -> String {
            return Strings.tr("Localizable", "chat.backButton.oneToOne.menu", String(describing: p1), fallback: "Chat with %@")
          }
        }
      }
      public enum Call {
        public enum QuickAction {
          /// Camera button title to toggle camera on calls.
          public static let camera = Strings.tr("Localizable", "chat.call.quickAction.camera", fallback: "Camera")
        }
        public enum WaitingRoom {
          public enum Alert {
            public enum Button {
              /// Call waiting room alert button to admit access
              public static let admit = Strings.tr("Localizable", "chat.call.waitingRoom.alert.button.admit", fallback: "Admit")
              /// Call waiting room alert button to allow access to everyone
              public static let admitAll = Strings.tr("Localizable", "chat.call.waitingRoom.alert.button.admitAll", fallback: "Admit all")
              /// Call waiting room alert button to allow access
              public static let cancel = Strings.tr("Localizable", "chat.call.waitingRoom.alert.button.cancel", fallback: "Cancel")
              /// Call waiting room alert button to deny access
              public static let confirmDeny = Strings.tr("Localizable", "chat.call.waitingRoom.alert.button.confirmDeny", fallback: "Deny entry")
              /// Call waiting room alert button to deny access
              public static let deny = Strings.tr("Localizable", "chat.call.waitingRoom.alert.button.deny", fallback: "Deny")
              /// Call waiting room alert button to open waiting room UI
              public static let seeWaitingRoom = Strings.tr("Localizable", "chat.call.waitingRoom.alert.button.seeWaitingRoom", fallback: "See waiting room")
            }
            public enum Message {
              /// Call waiting room alert message text to confirm deny access from host
              public static func denyAcces(_ p1: Any) -> String {
                return Strings.tr("Localizable", "chat.call.waitingRoom.alert.message.denyAcces", String(describing: p1), fallback: "Deny %@ entry?")
              }
              /// Call waiting room alert message text to notify host that someone is waiting to join
              public static func one(_ p1: Any) -> String {
                return Strings.tr("Localizable", "chat.call.waitingRoom.alert.message.one", String(describing: p1), fallback: "%@ is waiting to join the call")
              }
              /// Call waiting room alert message text to notify host that several participants are waiting to join
              public static func several(_ p1: Any) -> String {
                return Strings.tr("Localizable", "chat.call.waitingRoom.alert.message.several", String(describing: p1), fallback: "%@ participants are waiting to join the call")
              }
            }
            public enum OutsideCallUI {
              public enum Message {
                /// Call waiting room alert message text to notify host that someone is waiting to join a call (call UI is not visible)
                public static func one(_ p1: Any, _ p2: Any) -> String {
                  return Strings.tr("Localizable", "chat.call.waitingRoom.alert.outsideCallUI.message.one", String(describing: p1), String(describing: p2), fallback: "%@ is waiting to join “%@”")
                }
                /// Call waiting room alert message text to notify host that several participants are waiting to join a call (call UI is not visible)
                public static func several(_ p1: Any, _ p2: Any) -> String {
                  return Strings.tr("Localizable", "chat.call.waitingRoom.alert.outsideCallUI.message.several", String(describing: p1), String(describing: p2), fallback: "%@ participants are waiting to join “%@”")
                }
              }
            }
          }
        }
      }
      public enum CallInProgress {
        /// Message shown in a chat room for a call in progress displaying the duration of the call
        public static func tapToReturnToCall(_ p1: Any) -> String {
          return Strings.tr("Localizable", "chat.callInProgress.tapToReturnToCall", String(describing: p1), fallback: "Tap to return to call %@")
        }
      }
      public enum Chats {
        public enum EmptyState {
          /// Description for empty chats tab
          public static let description = Strings.tr("Localizable", "chat.chats.emptyState.description", fallback: "Chat securely and privately, with anyone and on any device, knowing that no one can read your chats, not even MEGA.")
          /// Ttile for empty chats tab
          public static let title = Strings.tr("Localizable", "chat.chats.emptyState.title", fallback: "Start chatting now")
          public enum Button {
            /// Text button for empty chats tab
            public static let title = Strings.tr("Localizable", "chat.chats.emptyState.button.title", fallback: "New chat")
          }
        }
      }
      public enum IntroductionHeader {
        public enum Privacy {
          /// Text description for chat privacy communication
          public static let description = Strings.tr("Localizable", "chat.introductionHeader.privacy.description", fallback: "MEGA protects your communications with our zero-knowledge encryption system providing essential safety assurances:")
        }
      }
      public enum Link {
        /// Chat: Message shown when the chat link was removed successfully
        public static let linkRemoved = Strings.tr("Localizable", "chat.link.linkRemoved", fallback: "Link removed")
      }
      public enum Listing {
        public enum Description {
          public enum MeetingCreated {
            /// Chat Listing - row description for the created meeting
            public static func message(_ p1: Any) -> String {
              return Strings.tr("Localizable", "chat.listing.description.meetingCreated.message", String(describing: p1), fallback: "%@: created a meeting")
            }
          }
        }
        public enum SectionHeader {
          public enum PastMeetings {
            /// Chat Meetings tab - Section header title for the chat listing screen
            public static let title = Strings.tr("Localizable", "chat.listing.sectionHeader.pastMeetings.title", fallback: "Past meetings")
          }
        }
      }
      public enum ManageHistory {
        public enum Clearing {
          public enum Custom {
            public enum Option {
              /// Plural format key: "%#@day@"
              public static func day(_ p1: Int) -> String {
                return Strings.tr("Localizable", "chat.manageHistory.clearing.custom.option.day", p1, fallback: "Plural format key: \"%#@day@\"")
              }
              /// Plural format key: "%#@hour@"
              public static func hour(_ p1: Int) -> String {
                return Strings.tr("Localizable", "chat.manageHistory.clearing.custom.option.hour", p1, fallback: "Plural format key: \"%#@hour@\"")
              }
              /// Plural format key: "%#@month@"
              public static func month(_ p1: Int) -> String {
                return Strings.tr("Localizable", "chat.manageHistory.clearing.custom.option.month", p1, fallback: "Plural format key: \"%#@month@\"")
              }
              /// Plural format key: "%#@week@"
              public static func week(_ p1: Int) -> String {
                return Strings.tr("Localizable", "chat.manageHistory.clearing.custom.option.week", p1, fallback: "Plural format key: \"%#@week@\"")
              }
              /// Plural format key: "%#@year@"
              public static func year(_ p1: Int) -> String {
                return Strings.tr("Localizable", "chat.manageHistory.clearing.custom.option.year", p1, fallback: "Plural format key: \"%#@year@\"")
              }
            }
          }
        }
        public enum Message {
          /// Text show under the setting 'History Retention' to explain what is the custom value configured. This value is represented by '%1'. The possible values go from 1 hour, to days, weeks or months, up to 1 year.
          public static func deleteMessageOlderThanCustomValue(_ p1: Any) -> String {
            return Strings.tr("Localizable", "chat.manageHistory.message.deleteMessageOlderThanCustomValue", String(describing: p1), fallback: "Automatically delete messages older than %@")
          }
        }
      }
      public enum Map {
        /// Menu option from the `Add` section that allows the user to share Location
        public static let location = Strings.tr("Localizable", "chat.map.location", fallback: "Location")
        public enum Location {
          /// Error message shown when enabling geolocation failed
          public static func enableGeolocationFailedError(_ p1: Any) -> String {
            return Strings.tr("Localizable", "chat.map.location.enableGeolocationFailedError", String(describing: p1), fallback: "Enable geolocation failed. Error: %@")
          }
        }
      }
      public enum Match {
        /// Label to desing a file matching
        public static let file = Strings.tr("Localizable", "chat.match.file", fallback: "File")
      }
      public enum Meetings {
        public enum EmptyState {
          /// Description for empty meetings tab
          public static let description = Strings.tr("Localizable", "chat.meetings.emptyState.description", fallback: "Talk securely and privately on audio or video calls with friends and colleagues around the world.")
          /// Ttile for empty meetings tab
          public static let title = Strings.tr("Localizable", "chat.meetings.emptyState.title", fallback: "Start a meeting")
          public enum Button {
            /// Text button for empty meetings tab
            public static let title = Strings.tr("Localizable", "chat.meetings.emptyState.button.title", fallback: "New meeting")
          }
        }
      }
      public enum Message {
        /// Chat: This is the placeholder text for text view when keyboard is shown
        public static let placeholder = Strings.tr("Localizable", "chat.message.placeholder", fallback: "Message…")
        /// Plural format key: "%#@count@"
        public static func unreadMessage(_ p1: Int) -> String {
          return Strings.tr("Localizable", "chat.message.unreadMessage", p1, fallback: "Plural format key: \"%#@count@\"")
        }
        public enum ChangedRole {
          /// A log message in a chat to display that a participant's permission was changed to host role and by whom. This message begins with the user's name who receive the permission change [A]. [B] will be replaced with the person who did it. Please keep the [A], [B] they will be replaced at runtime. Text between [S] and [/S] will have heavier font weight. For example: Alice Jones was changed to host role by John Smith.
          public static let host = Strings.tr("Localizable", "chat.message.changedRole.host", fallback: "[A] was changed to [S]host role[/S] by [B]")
          /// A log message in a chat to display that a participant's permission was changed to read-only and by whom. This message begins with the user's name who receive the permission change [A]. [B] will be replaced with the person who did it. Please keep [A] and [B], they will be replaced at runtime. Text between [S] and [/S] will have heavier font weight. For example: Alice Jones was changed to read-only by John Smith.
          public static let readOnly = Strings.tr("Localizable", "chat.message.changedRole.readOnly", fallback: "[A] was changed to [S]read-only[/S] by [B]")
          /// A log message in a chat to display that a participant's permission was changed to standard role and by whom. This message begins with the user's name who receive the permission change [A]. [B] will be replaced with the person who did it. Please keep [A] and [B] they will be replaced at runtime. Text between [S] and [/S] will have heavier font weight. For example: Alice Jones was changed to standard role by John Smith.
          public static let standard = Strings.tr("Localizable", "chat.message.changedRole.standard", fallback: "[A] was changed to [S]standard role[/S] by [B]")
        }
      }
      public enum Photos {
        /// Description shown in chat screen if the user didn't allow access to photos
        public static let allowPhotoAccessMessage = Strings.tr("Localizable", "chat.photos.allowPhotoAccessMessage", fallback: "To share photos and videos, grant MEGA access to your gallery")
      }
      public enum Selector {
        /// Chat section selector tab for chats
        public static let chat = Strings.tr("Localizable", "chat.selector.chat", fallback: "Chats")
        /// Chat section selector tab for meetings
        public static let meeting = Strings.tr("Localizable", "chat.selector.meeting", fallback: "Meetings")
      }
      public enum SendLocation {
        public enum Map {
          /// Type of data displayed in a map view. A satellite image of the area with road and road name information layered on top.
          public static let hybrid = Strings.tr("Localizable", "chat.sendLocation.map.hybrid", fallback: "Hybrid")
          /// Type of data displayed in a map view. Satellite imagery of the area.
          public static let satellite = Strings.tr("Localizable", "chat.sendLocation.map.satellite", fallback: "Satellite")
          /// Type of data displayed in a map view. Standard imagery of the area.
          public static let standard = Strings.tr("Localizable", "chat.sendLocation.map.standard", fallback: "Standard")
        }
      }
      public enum Status {
        public enum Duration {
          /// Plural format key: "%#@minute@"
          public static func minute(_ p1: Int) -> String {
            return Strings.tr("Localizable", "chat.status.duration.minute", p1, fallback: "Plural format key: \"%#@minute@\"")
          }
        }
      }
    }
    public enum CloudDrive {
      public enum Browser {
        /// List option shown on the details of a file or folder after the user has copied it
        public static let paste = Strings.tr("Localizable", "cloudDrive.browser.paste", fallback: "Paste")
        public enum SaveToCloudDrive {
          /// Browser save to cloud drive select button title
          public static let title = Strings.tr("Localizable", "cloudDrive.browser.saveToCloudDrive.title", fallback: "Save to Cloud drive")
        }
      }
      public enum Info {
        public enum Node {
          /// Title label of a node property.
          public static let location = Strings.tr("Localizable", "cloudDrive.info.node.location", fallback: "Location")
        }
      }
      public enum MediaDiscovery {
        /// Exit Text on Media Discovery Navigation Bar
        public static let exit = Strings.tr("Localizable", "cloudDrive.mediaDiscovery.exit", fallback: "Exit")
      }
      public enum Menu {
        public enum MediaDiscovery {
          /// Menu option from the `Add` section that displays all media files under current folder
          public static let title = Strings.tr("Localizable", "cloudDrive.menu.mediaDiscovery.title", fallback: "Media discovery")
        }
      }
      public enum NodeInfo {
        /// Show the node owner's name. The %@ is the owner's name
        public static func owner(_ p1: Any) -> String {
          return Strings.tr("Localizable", "cloudDrive.nodeInfo.owner", String(describing: p1), fallback: "%@ (owner)")
        }
      }
      public enum ScanDocument {
        /// Default title given to the document created when you use the option 'Scan Document' in the app
        public static func defaultName(_ p1: Any) -> String {
          return Strings.tr("Localizable", "cloudDrive.scanDocument.defaultName", String(describing: p1), fallback: "Scan %@")
        }
      }
      public enum Sort {
        /// A menu item in the left panel drop down menu to allow sorting by label.
        public static let label = Strings.tr("Localizable", "cloudDrive.sort.label", fallback: "Label")
      }
      public enum Upload {
        /// Tapping on this button open Files.app and allow users select files to upload them to MEGA
        public static let importFromFiles = Strings.tr("Localizable", "cloudDrive.upload.importFromFiles", fallback: "Import from Files")
      }
    }
    public enum Contact {
      public enum Invite {
        /// Text to send as SMS message to user contacts inviting them to MEGA
        public static let message = Strings.tr("Localizable", "contact.invite.message", fallback: "You have a MEGA Chat request waiting. Register an account on MEGA and get 20 GB free lifetime storage.")
      }
    }
    public enum ContactInfo {
      public enum BackButton {
        /// Name of the screen of contact info shown when back button is long pressed
        public static let menu = Strings.tr("Localizable", "contactInfo.backButton.menu", fallback: "Contact info")
      }
    }
    public enum Device {
      public enum Center {
        /// Device Center title
        public static let title = Strings.tr("Localizable", "device.center.title", fallback: "Device centre")
        public enum Backup {
          public enum BackupStopped {
            public enum Status {
              /// Device Center backup backup stopped status
              public static let message = Strings.tr("Localizable", "device.center.backup.backupStopped.status.message", fallback: "Backup stopped")
            }
          }
          public enum Blocked {
            public enum Status {
              /// Device Center backup blocked status
              public static let message = Strings.tr("Localizable", "device.center.backup.blocked.status.message", fallback: "Blocked")
            }
          }
          public enum Disabled {
            public enum Status {
              /// Device Center backup disabled status
              public static let message = Strings.tr("Localizable", "device.center.backup.disabled.status.message", fallback: "Disabled")
            }
          }
          public enum Error {
            public enum Status {
              /// Device Center backup error status
              public static let message = Strings.tr("Localizable", "device.center.backup.error.status.message", fallback: "Error")
            }
          }
          public enum Initialising {
            public enum Status {
              /// Device Center backup initialising status
              public static let message = Strings.tr("Localizable", "device.center.backup.initialising.status.message", fallback: "Initialising…")
            }
          }
          public enum NoCameraUploads {
            public enum Status {
              /// Device Center backup no camera uploads status
              public static let message = Strings.tr("Localizable", "device.center.backup.noCameraUploads.status.message", fallback: "No camera uploads")
            }
          }
          public enum Offline {
            public enum Status {
              /// Device Center backup offline status
              public static let message = Strings.tr("Localizable", "device.center.backup.offline.status.message", fallback: "Offline")
            }
          }
          public enum OutOfQuota {
            public enum Status {
              /// Device Center backup out of quota status
              public static let message = Strings.tr("Localizable", "device.center.backup.outOfQuota.status.message", fallback: "Out of quota")
            }
          }
          public enum Paused {
            public enum Status {
              /// Device Center backup paused status
              public static let message = Strings.tr("Localizable", "device.center.backup.paused.status.message", fallback: "Paused")
            }
          }
          public enum Scanning {
            public enum Status {
              /// Device Center backup scanning status
              public static let message = Strings.tr("Localizable", "device.center.backup.scanning.status.message", fallback: "Scanning…")
            }
          }
          public enum UpToDate {
            public enum Status {
              /// Device Center backup up to date status
              public static let message = Strings.tr("Localizable", "device.center.backup.upToDate.status.message", fallback: "Up to date")
            }
          }
          public enum Updating {
            public enum Status {
              /// Device Center backup updating status
              public static let message = Strings.tr("Localizable", "device.center.backup.updating.status.message", fallback: "Updating…")
            }
          }
        }
        public enum Current {
          public enum Device {
            /// Device Center list current device title
            public static let title = Strings.tr("Localizable", "device.center.current.device.title", fallback: "This device")
          }
        }
        public enum Default {
          public enum Device {
            /// Default device name in case the device name cannot be obtained
            public static let title = Strings.tr("Localizable", "device.center.default.device.title", fallback: "Unknown device")
          }
        }
        public enum Other {
          public enum Devices {
            /// Device Center list other devices title
            public static let title = Strings.tr("Localizable", "device.center.other.devices.title", fallback: "Other devices")
          }
        }
        public enum Show {
          public enum In {
            public enum Backups {
              public enum Action {
                /// Show in Backups section action title
                public static let title = Strings.tr("Localizable", "device.center.show.in.backups.action.title", fallback: "Show in Backups")
              }
            }
            public enum Cloud {
              public enum Drive {
                public enum Action {
                  /// Show in Cloud Drive section action title
                  public static let title = Strings.tr("Localizable", "device.center.show.in.cloud.drive.action.title", fallback: "Show in Cloud drive")
                }
              }
            }
          }
        }
      }
    }
    public enum Dialog {
      public enum Add {
        public enum Items {
          public enum Backup {
            public enum Action {
              /// Add items to a backup folder action title
              public static let title = Strings.tr("Localizable", "dialog.add.items.backup.action.title", fallback: "Add")
            }
            public enum Folder {
              public enum Warning {
                /// Add new items to a backup folder warning message
                public static let message = Strings.tr("Localizable", "dialog.add.items.backup.folder.warning.message", fallback: "Adding items to this folder changes the backup destination. The backup will be turned off for safety. Is this what you want to do? Backups can be re-enabled with the MEGA Desktop App.")
                /// Add new items to a backup folder warning title. %@ is a folder
                public static func title(_ p1: Any) -> String {
                  return Strings.tr("Localizable", "dialog.add.items.backup.folder.warning.title", String(describing: p1), fallback: "Add Item to “%@”")
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
              /// Change the default backup location warning message
              public static let message = Strings.tr("Localizable", "dialog.backup.folder.location.warning.message", fallback: "Moving this folder changes the backup destination. The backup will be turned off for safety. Is this what you want to do? Backups can be re-enabled with the MEGA Desktop App.")
              /// Change the default backup location warning title. %@ is a folder
              public static func title(_ p1: Any) -> String {
                return Strings.tr("Localizable", "dialog.backup.folder.location.warning.title", String(describing: p1), fallback: "Move “%@”")
              }
            }
          }
        }
        public enum Setup {
          /// Backup setup warning message
          public static let message = Strings.tr("Localizable", "dialog.backup.setup.message", fallback: "Use our desktop app to ensure your backup folder is synchronised with your MEGA Cloud.")
          /// Backup setup warning title
          public static let title = Strings.tr("Localizable", "dialog.backup.setup.title", fallback: "Set up Backup")
        }
        public enum Warning {
          public enum Confirm {
            /// Backup warning confirmation message. %@ is an action: move backup, delete backup, disable backup
            public static func message(_ p1: Any) -> String {
              return Strings.tr("Localizable", "dialog.backup.warning.confirm.message", String(describing: p1), fallback: "Please type “%@” to confirm this action")
            }
          }
        }
      }
      public enum CallAttempt {
        /// Detail message shown when you try to call someone that is not you contact in MEGA. The [X] placeholder will be replaced on runtime for the email of the user
        public static let contactNotInMEGA = Strings.tr("Localizable", "dialog.callAttempt.contactNotInMEGA", fallback: "Your contact [X] is not on MEGA. In order to call through MEGA’s encrypted chat you need to invite your contact")
      }
      public enum Confirmation {
        public enum Error {
          /// Backup action confirmation error message
          public static let message = Strings.tr("Localizable", "dialog.confirmation.error.message", fallback: "Text entered does not match")
        }
      }
      public enum Cookies {
        /// Cookie dialog button label.
        public static let accept = Strings.tr("Localizable", "dialog.cookies.accept", fallback: "Accept Cookies")
        /// Cookie dialog text.
        public static let description = Strings.tr("Localizable", "dialog.cookies.description", fallback: "We use cookies and similar technologies solely for the purposes of providing you with the services you request from MEGA, or for analytics and gathering performance data. We don’t use cookies for ad tracking or sharing any personal information about you with third parties.")
        public enum Title {
          /// Cookie dialog title
          public static let yourPrivacy = Strings.tr("Localizable", "dialog.cookies.title.yourPrivacy", fallback: "Your privacy")
        }
      }
      public enum Delete {
        public enum Backup {
          /// Delete a backup folder placeholder for a textfield
          public static let placeholder = Strings.tr("Localizable", "dialog.delete.backup.placeholder", fallback: "delete backup")
          public enum Action {
            /// Delete a backup folder action title
            public static let title = Strings.tr("Localizable", "dialog.delete.backup.action.title", fallback: "Move to Rubbish bin")
          }
          public enum Folder {
            public enum Warning {
              /// Delete the default backup folder warning message
              public static let message = Strings.tr("Localizable", "dialog.delete.backup.folder.warning.message", fallback: "Are you sure you want to delete your backup folder and disable backup you set?")
              /// Delete the default backup folder warning title. %@ is a folder
              public static func title(_ p1: Any) -> String {
                return Strings.tr("Localizable", "dialog.delete.backup.folder.warning.title", String(describing: p1), fallback: "Move “%@” to Rubbish bin")
              }
            }
          }
        }
        public enum Root {
          public enum Backup {
            public enum Folder {
              public enum Warning {
                /// Delete the default backup folder warning message
                public static let message = Strings.tr("Localizable", "dialog.delete.root.backup.folder.warning.message", fallback: "You are deleting your backups folder. This will remove all the backups you have set. Are you sure you want to do this?")
              }
            }
          }
        }
      }
      public enum Disable {
        public enum Backup {
          /// Add items to a backup folder placeholder for a textfield
          public static let placeholder = Strings.tr("Localizable", "dialog.disable.backup.placeholder", fallback: "disable backup")
        }
      }
      public enum InviteContact {
        /// Detail message shown when a contact has been invited. The [X] placeholder will be replaced on runtime for the email of the invited user
        public static let outgoingContactRequest = Strings.tr("Localizable", "dialog.inviteContact.outgoingContactRequest", fallback: "The user [X] has been invited and will appear in your contact list once accepted.")
      }
      public enum Move {
        public enum Backup {
          /// Change the location of a backup folder placeholder for a textfield
          public static let placeholder = Strings.tr("Localizable", "dialog.move.backup.placeholder", fallback: "move backup")
        }
      }
      public enum Root {
        public enum Backup {
          public enum Folder {
            public enum Location {
              public enum Warning {
                /// Change the default backup location warning message
                public static let message = Strings.tr("Localizable", "dialog.root.backup.folder.location.warning.message", fallback: "You are changing a default backup folder location. This may affect your ability to find your backup folder. Please remember where it is located so that you can find it in the future.")
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
                  /// Alert the user when trying to share several backup and non-backup folders
                  public static let message = Strings.tr("Localizable", "dialog.share.backup.non.backup.folders.warning.message", fallback: "Some folders shared are backup folders and read-only. Do you wish to continue?")
                }
              }
            }
          }
        }
      }
      public enum ShareOwnerStorageQuota {
        /// An error message which is shown when we want to share a file with somebody who has used all the storage space in their MEGA account.
        public static let message = Strings.tr("Localizable", "dialog.shareOwnerStorageQuota.message", fallback: "The file cannot be sent as the target user is over their storage quota.")
      }
      public enum Storage {
        public enum AlmostFull {
          /// Informs the user that they’ve almost reached the full capacity of their Cloud Drive for a Free account. @% is placeholder.
          public static func detail(_ p1: Any, _ p2: Any) -> String {
            return Strings.tr("Localizable", "dialog.storage.almostFull.detail", String(describing: p1), String(describing: p2), fallback: "Your Cloud drive is almost full. Upgrade now to a Pro account and get up to %@ TB (%@ GB) of cloud storage space.")
          }
        }
        public enum Odq {
          /// Over Disk Quota detail message informing the user that they've reached the full capacity of their accounts.
          public static let detail = Strings.tr("Localizable", "dialog.storage.odq.detail", fallback: "Your Cloud storage is full. Please upgrade to a MEGA Pro plan to increase your storage space and enjoy additional benefits. If you remain over your storage limit and do not upgrade or delete some data your account may get locked. Please see the emails we sent you for more information.")
          /// Title of Over Disk Quota dialog
          public static let title = Strings.tr("Localizable", "dialog.storage.odq.title", fallback: "Please upgrade")
        }
        public enum Paywall {
          public enum Final {
            /// Over Disk Quota paywall final detail message.
            public static let detail = Strings.tr("Localizable", "dialog.storage.paywall.final.detail", fallback: "<paragraph>Your data will be deleted tomorrow if your account has not been upgraded.</paragraph>")
            /// Over Disk Quota paywall final title.
            public static let title = Strings.tr("Localizable", "dialog.storage.paywall.final.title", fallback: "Your data is at risk!")
            /// Over Disk Quota paywall, final warning label.
            public static let warning = Strings.tr("Localizable", "dialog.storage.paywall.final.warning", fallback: "<body><warn>Upgrade today if you wish to keep your data.</warn></body>")
          }
          public enum NotFinal {
            /// Over Disk Quota paywall not final detail message.
            public static func detail(_ p1: Any, _ p2: Any, _ p3: Any, _ p4: Any) -> String {
              return Strings.tr("Localizable", "dialog.storage.paywall.notFinal.detail", String(describing: p1), String(describing: p2), String(describing: p3), String(describing: p4), fallback: "<paragraph>Unfortunately, you have not taken action in the <b>%@</b> since our emails were sent to <b>%@</b>, on <b>%@</b>. You are still using <b>%@</b> storage, which is over your free limit. Please see the emails we have sent you for more information on what you need to do.</paragraph>")
            }
            /// Over Disk Quota paywall not final title.
            public static let title = Strings.tr("Localizable", "dialog.storage.paywall.notFinal.title", fallback: "Account locked")
            /// Over Disk Quota paywall, not final warning label.
            public static func warning(_ p1: Any) -> String {
              return Strings.tr("Localizable", "dialog.storage.paywall.notFinal.warning", String(describing: p1), fallback: "<body>Upgrade within <warn>%@</warn> to avoid your data getting deleted.</body>")
            }
          }
        }
      }
      public enum TurnOnNotifications {
        public enum Button {
          /// Title of the button to open Settings
          public static let primary = Strings.tr("Localizable", "dialog.turnOnNotifications.button.primary", fallback: "Open Settings")
        }
        public enum Label {
          /// The description of Turn on Notifications view
          public static let description = Strings.tr("Localizable", "dialog.turnOnNotifications.label.description", fallback: "This way, you will see new messages on your device instantly.")
          /// Fourth step to turn on notifications
          public static let stepFour = Strings.tr("Localizable", "dialog.turnOnNotifications.label.stepFour", fallback: "4. Turn on <b>Allow notifications</b>")
          /// First step to turn on notifications
          public static let stepOne = Strings.tr("Localizable", "dialog.turnOnNotifications.label.stepOne", fallback: "1. Open <b>Settings</b>")
          /// Third step to turn on notifications
          public static let stepThree = Strings.tr("Localizable", "dialog.turnOnNotifications.label.stepThree", fallback: "3. Tap <b>MEGA</b>")
          /// Second step to turn on notifications
          public static let stepTwo = Strings.tr("Localizable", "dialog.turnOnNotifications.label.stepTwo", fallback: "2. Tap <b>Notifications</b>")
          /// The title of Turn on Notifications view
          public static let title = Strings.tr("Localizable", "dialog.turnOnNotifications.label.title", fallback: "Turn on notifications")
        }
      }
    }
    public enum Dnd {
      public enum Duration {
        /// Plural format key: "%#@hour@"
        public static func hour(_ p1: Int) -> String {
          return Strings.tr("Localizable", "dnd.duration.hour", p1, fallback: "Plural format key: \"%#@hour@\"")
        }
        /// Plural format key: "%#@minute@"
        public static func minute(_ p1: Int) -> String {
          return Strings.tr("Localizable", "dnd.duration.minute", p1, fallback: "Plural format key: \"%#@minute@\"")
        }
      }
    }
    public enum Extensions {
      public enum OpenApp {
        /// Text shown in extensions to notify users that they have to open the application first
        public static let message = Strings.tr("Localizable", "extensions.OpenApp.Message", fallback: "Open the MEGA app and log in to continue.")
      }
      public enum Share {
        public enum Destination {
          public enum Section {
            /// Plural format key: "%#@file@"
            public static func files(_ p1: Int) -> String {
              return Strings.tr("Localizable", "extensions.share.destination.section.files", p1, fallback: "Plural format key: \"%#@file@\"")
            }
          }
        }
      }
    }
    public enum FileProviderExtension {
      public enum Action {
        /// Context menu action seen from native files application when selecting a file that's also present on MEGA
        public static let `open` = Strings.tr("Localizable", "fileProviderExtension.action.open", fallback: "Open in MEGA")
      }
    }
    public enum General {
      /// Text show to highlight that you can choose a different option
      public static let choose = Strings.tr("Localizable", "general.choose", fallback: "Select")
      /// Title of one of the Settings sections where you can see the MEGA's 'Cookie Policy'
      public static let cookiePolicy = Strings.tr("Localizable", "general.cookiePolicy", fallback: "Cookie Policy")
      /// Title of one of the Settings sections where you can see the MEGA's 'Cookie Settings'
      public static let cookieSettings = Strings.tr("Localizable", "general.cookieSettings", fallback: "Cookie settings")
      /// Text for the action of downloading an item to the offline section
      public static let downloadToOffline = Strings.tr("Localizable", "general.downloadToOffline", fallback: "Make available offline")
      /// Button title which, if tapped, will trigger the action to export something from MEGA with the objective of sharing it outside of the app
      public static let export = Strings.tr("Localizable", "general.export", fallback: "Export")
      /// Text for the popup displayed when you try to download file to photos while file is already being downloaded
      public static let fileIsBeingDownloaded = Strings.tr("Localizable", "general.fileIsBeingDownloaded", fallback: "File is already being downloaded")
      /// Button title which triggers the action to join meeting as Guest
      public static let joinMeetingAsGuest = Strings.tr("Localizable", "general.joinMeetingAsGuest", fallback: "Join meeting as guest")
      /// Label shown when users lost the internet connection
      public static let noIntenerConnection = Strings.tr("Localizable", "general.NoIntenerConnection", fallback: "Unable to connect to the Internet. Please check your connection and try again.")
      /// Title for a button to send a file to a chat
      public static let sendToChat = Strings.tr("Localizable", "general.sendToChat", fallback: "Send to chat")
      /// Button title which, if tapped, will trigger the action of sharing with the contact or contacts selected
      public static let share = Strings.tr("Localizable", "general.share", fallback: "Share")
      public enum Button {
        /// Button title to see the available bonus
        public static let getBonus = Strings.tr("Localizable", "general.button.getBonus", fallback: "Get bonus")
      }
      public enum ChooseLabel {
        /// Context menu item which allows to mark folders with own color label
        public static let title = Strings.tr("Localizable", "general.chooseLabel.title", fallback: "Label…")
      }
      public enum Error {
        /// Error message shown when trying to rename or create a folder with characters that are not allowed. The %@ will be replaced with the list of invalid characters. For example: The following characters are not allowed: " * / : < > ? \ |
        public static func charactersNotAllowed(_ p1: Any) -> String {
          return Strings.tr("Localizable", "general.error.charactersNotAllowed", String(describing: p1), fallback: "The following characters are not allowed: %@")
        }
      }
      public enum Filetype {
        /// File extensions: .3dm and .3gp. Commercial names should be stay on English
        public static let _3DModel = Strings.tr("Localizable", "general.filetype.3DModel", fallback: "3D model")
        /// File extension: .3ds. Commercial names should be stay on English
        public static let _3ds = Strings.tr("Localizable", "general.filetype.3ds", fallback: "3D scene")
        /// File extension: .3g2. Commercial names should be stay on English
        public static let _3g2 = Strings.tr("Localizable", "general.filetype.3g2", fallback: "Multimedia")
        /// File extension: .7z. Commercial names should be stay on English
        public static let _7z = Strings.tr("Localizable", "general.filetype.7z", fallback: "7-Zip compressed")
        /// File extension: .ans. Commercial names should be stay on English
        public static let ans = Strings.tr("Localizable", "general.filetype.ans", fallback: "ANSI text file")
        /// File extension: .apk. Commercial names should be stay on English
        public static let apk = Strings.tr("Localizable", "general.filetype.apk", fallback: "Android app")
        /// File extension: .app. Commercial names should be stay on English
        public static let app = Strings.tr("Localizable", "general.filetype.app", fallback: "macOS app")
        /// File extension: .ascii. Commercial names should be stay on English
        public static let ascii = Strings.tr("Localizable", "general.filetype.ascii", fallback: "ASCII text")
        /// File extension: .asf. Commercial names should be stay on English
        public static let asf = Strings.tr("Localizable", "general.filetype.asf", fallback: "Streaming video")
        /// File extension: .asx. Is not a commercial name, but a file format name.
        public static let asx = Strings.tr("Localizable", "general.filetype.asx", fallback: "Advanced stream")
        /// File extension: .aif and .aiff. Is not a commercial name, but a standard
        public static let audioInterchange = Strings.tr("Localizable", "general.filetype.audioInterchange", fallback: "Audio interchange")
        /// File extension: .avi. Name of a multimedia container format
        public static let avi = Strings.tr("Localizable", "general.filetype.avi", fallback: "A/V interleave")
        /// File extension: .bat. "DOS" is not a commercial name, but the acronym for disk operating system. "Batch" is common noun
        public static let bat = Strings.tr("Localizable", "general.filetype.bat", fallback: "DOS batch")
        /// File extension: .bay. Commercial names should be stay on English
        public static let bay = Strings.tr("Localizable", "general.filetype.bay", fallback: "Casio RAW image")
        /// File extension: .bmp. Commercial names should be stay on English
        public static let bmp = Strings.tr("Localizable", "general.filetype.bmp", fallback: "Bitmap image")
        /// File extension: .bz2. Commercial names should be stay on English
        public static let bz2 = Strings.tr("Localizable", "general.filetype.bz2", fallback: "UNIX compressed")
        /// File extension: .c. Commercial names should be stay on English
        public static let c = Strings.tr("Localizable", "general.filetype.c", fallback: "C/C++ source code")
        /// File extension. Commercial names should be stay on English
        public static let cdr = Strings.tr("Localizable", "general.filetype.cdr", fallback: "CorelDRAW image")
        /// File extension: .cgi. Is not a commercial name, but the name of an interface specification. "script" is common noun.
        public static let cgi = Strings.tr("Localizable", "general.filetype.cgi", fallback: "CGI script")
        /// File extension: .class. Commercial names should be stay on English
        public static let `class` = Strings.tr("Localizable", "general.filetype.class", fallback: "Java class")
        /// File extension: .com. Commercial names should be stay on English
        public static let com = Strings.tr("Localizable", "general.filetype.com", fallback: "DOS command")
        /// File extension: .tbz and .tgz. Commercial names should be stay on English
        public static let compressed = Strings.tr("Localizable", "general.filetype.compressed", fallback: "Compressed")
        /// File extensions: .cc, .cpp and .cxx. Commercial names should be stay on English
        public static let cpp = Strings.tr("Localizable", "general.filetype.cpp", fallback: "C++ source code")
        /// File extension: .css. Commercial names should be stay on English
        public static let css = Strings.tr("Localizable", "general.filetype.css", fallback: "CSS style sheet")
        /// File extensions: .accdb, .db, .dbf and .pdb. Commercial names should be stay on English
        public static let database = Strings.tr("Localizable", "general.filetype.database", fallback: "Database")
        /// File extension: .dhtml. Is not a commercial name. "dynamic" is an adjective
        public static let dhtml = Strings.tr("Localizable", "general.filetype.dhtml", fallback: "Dynamic HTML")
        /// File extension: .dll. Is not a commercial name. "dynamic" is the name of concept
        public static let dll = Strings.tr("Localizable", "general.filetype.dll", fallback: "Dynamic link library")
        /// File extension: .dxf. Commercial names should be stay on English
        public static let dxf = Strings.tr("Localizable", "general.filetype.dxf", fallback: "DXF image")
        /// File extension: .eps. Commercial names should be stay on English
        public static let eps = Strings.tr("Localizable", "general.filetype.eps", fallback: "EPS image")
        /// File extension: .exe. Commercial names should be stay on English
        public static let exe = Strings.tr("Localizable", "general.filetype.exe", fallback: "Executable")
        /// File extension: .flac. Commercial names should be stay on English
        public static let flac = Strings.tr("Localizable", "general.filetype.flac", fallback: "Lossless audio")
        /// File extension: .flv. Commercial names should be stay on English
        public static let flv = Strings.tr("Localizable", "general.filetype.flv", fallback: "Flash video")
        /// File extension: .fnt. Commercial names should be stay on English
        public static let fnt = Strings.tr("Localizable", "general.filetype.fnt", fallback: "Windows font")
        /// File extension: .fon. Commercial names should be stay on English
        public static let fon = Strings.tr("Localizable", "general.filetype.fon", fallback: "Font")
        /// File extension: .gadget. Commercial names should be stay on English
        public static let gadget = Strings.tr("Localizable", "general.filetype.gadget", fallback: "Windows gadget")
        /// File extension: .gif. Commercial names should be stay on English
        public static let gif = Strings.tr("Localizable", "general.filetype.gif", fallback: "GIF image")
        /// File extension: .gpx. Commercial names should be stay on English
        public static let gpx = Strings.tr("Localizable", "general.filetype.gpx", fallback: "GPS exchange")
        /// File extension: .gz. Commercial names should be stay on English
        public static let gz = Strings.tr("Localizable", "general.filetype.gz", fallback: "GNU compressed")
        /// File extensions: .h and .hpp. Commercial names should be stay on English
        public static let header = Strings.tr("Localizable", "general.filetype.header", fallback: "Header")
        /// File extensions: .htm and .html. Commercial names should be stay on English
        public static let htmlDocument = Strings.tr("Localizable", "general.filetype.htmlDocument", fallback: "HTML document")
        /// File extension: .iff. Commercial names should be stay on English
        public static let iff = Strings.tr("Localizable", "general.filetype.iff", fallback: "Interchange file format")
        /// File extension: .iso. Commercial names should be stay on English
        public static let iso = Strings.tr("Localizable", "general.filetype.iso", fallback: "ISO image")
        /// File extension: .jar. Commercial names should be stay on English
        public static let jar = Strings.tr("Localizable", "general.filetype.jar", fallback: "Java archive")
        /// File extension: .java. Commercial names should be stay on English
        public static let java = Strings.tr("Localizable", "general.filetype.java", fallback: "Java code")
        /// File extensions: .jpg and .jpeg. Commercial names should be stay on English
        public static let jpeg = Strings.tr("Localizable", "general.filetype.jpeg", fallback: "JPEG image")
        /// File extension: .log. Commercial names should be stay on English
        public static let log = Strings.tr("Localizable", "general.filetype.log", fallback: "Log")
        /// File extension: .3mu. Commercial names should be stay on English
        public static let m3u = Strings.tr("Localizable", "general.filetype.m3u", fallback: "Media playlist")
        /// File extension: .m4a. Commercial names should be stay on English
        public static let m4a = Strings.tr("Localizable", "general.filetype.m4a", fallback: "MPEG-4 audio")
        /// File extension: .max. Commercial names should be stay on English
        public static let max = Strings.tr("Localizable", "general.filetype.max", fallback: "3ds Max scene")
        /// File extension: .mdb. Commercial names should be stay on English
        public static let mdb = Strings.tr("Localizable", "general.filetype.mdb", fallback: "MS Access")
        /// File extensions: .mid and .midi. Commercial names should be stay on English
        public static let mid = Strings.tr("Localizable", "general.filetype.mid", fallback: "MIDI audio")
        /// File extension: .mkv. Commercial names should be stay on English
        public static let mkv = Strings.tr("Localizable", "general.filetype.mkv", fallback: "MKV video")
        /// File extension: .mov. Commercial names should be stay on English
        public static let mov = Strings.tr("Localizable", "general.filetype.mov", fallback: "QuickTime movie")
        /// File extension: .mp3. Commercial names should be stay on English
        public static let mp3 = Strings.tr("Localizable", "general.filetype.mp3", fallback: "MP3 audio")
        /// File extension: .mp4. Commercial names should be stay on English
        public static let mp4 = Strings.tr("Localizable", "general.filetype.mp4", fallback: "MP4 video")
        /// File extensions: .mpeg and .mpg. Commercial names should be stay on English
        public static let mpeg = Strings.tr("Localizable", "general.filetype.mpeg", fallback: "MPEG movie")
        /// File extension: .msi. Commercial names should be stay on English
        public static let msi = Strings.tr("Localizable", "general.filetype.msi", fallback: "MS installer")
        /// File extension: .otf. Commercial names should be stay on English
        public static let otf = Strings.tr("Localizable", "general.filetype.otf", fallback: "OpenType font")
        /// File extension: .pages. Commercial names should be stay on English
        public static let pages = Strings.tr("Localizable", "general.filetype.pages", fallback: "Pages")
        /// File extension: .pdf. Commercial names should be stay on English
        public static let pdf = Strings.tr("Localizable", "general.filetype.pdf", fallback: "PDF document")
        /// File extension: .php, .php3, .php4 and .php5. Commercial names should be stay on English
        public static let php = Strings.tr("Localizable", "general.filetype.php", fallback: "PHP code")
        /// File extension: .pl. Is not a commercial name. "script" is a common noun
        public static let pl = Strings.tr("Localizable", "general.filetype.pl", fallback: "Perl script")
        /// File extension: .pls. Commercial names should be stay on English
        public static let pls = Strings.tr("Localizable", "general.filetype.pls", fallback: "Audio playlist")
        /// File extension: .png. Commercial names should be stay on English
        public static let png = Strings.tr("Localizable", "general.filetype.png", fallback: "PNG image")
        /// File extension: .pcast. Commercial names should be stay on English
        public static let podcast = Strings.tr("Localizable", "general.filetype.podcast", fallback: "Podcast")
        /// File extension: .py. Is not a commercial name. "script" is a common noun
        public static let py = Strings.tr("Localizable", "general.filetype.py", fallback: "Python script")
        /// File extension: .rar. Commercial names should be stay on English
        public static let rar = Strings.tr("Localizable", "general.filetype.rar", fallback: "RAR compressed")
        /// File extensions: .3fr, .arw, .cr2, .dcr, .fff, .mef, .mrw, .nef, .orf, .pef and .rwl. Commercial names should be stay on English
        public static let rawImage = Strings.tr("Localizable", "general.filetype.rawImage", fallback: "RAW image")
        /// File extension: .rtf. Commercial names should be stay on English
        public static let rtf = Strings.tr("Localizable", "general.filetype.rtf", fallback: "Rich text")
        /// File extension: .rw2. Commercial names should be stay on English
        public static let rw2 = Strings.tr("Localizable", "general.filetype.rw2", fallback: "Panasonic RAW image")
        /// File extension: .sh. Is not a commercial name. "shell" is a common noun
        public static let sh = Strings.tr("Localizable", "general.filetype.sh", fallback: "Bash shell")
        /// File extension: .shmtl. Commercial names should be stay on English
        public static let shtml = Strings.tr("Localizable", "general.filetype.shtml", fallback: "Server HTML")
        /// File extension: .sitx. Commercial names should be stay on English
        public static let sitx = Strings.tr("Localizable", "general.filetype.sitx", fallback: "X compressed")
        /// File extensions: .gsheet, .ods and .ots. Commercial names should be stay on English
        public static let spreadsheet = Strings.tr("Localizable", "general.filetype.spreadsheet", fallback: "Spreadsheet")
        /// File extension: .sql. Commercial names should be stay on English
        public static let sql = Strings.tr("Localizable", "general.filetype.sql", fallback: "SQL statements")
        /// File extension: .srf. Commercial names should be stay on English
        public static let srf = Strings.tr("Localizable", "general.filetype.srf", fallback: "Sony RAW image")
        /// File extension: .srt. Commercial names should be stay on English
        public static let subtitle = Strings.tr("Localizable", "general.filetype.subtitle", fallback: "Subtitle")
        /// File extension: .swf. Commercial names should be stay on English
        public static let swf = Strings.tr("Localizable", "general.filetype.swf", fallback: "Flash movie")
        /// File extension: .tar. Commercial names should be stay on English
        public static let tar = Strings.tr("Localizable", "general.filetype.tar", fallback: "Archive")
        /// File extensions: .txt and .odt. Commercial names should be stay on English
        public static let textDocument = Strings.tr("Localizable", "general.filetype.textDocument", fallback: "Text document")
        /// File extension: .tga. Is not a commercial name. "graphic" is a common noun
        public static let tga = Strings.tr("Localizable", "general.filetype.tga", fallback: "TARGA graphic")
        /// File extension: .tif. Commercial names should be stay on English
        public static let tif = Strings.tr("Localizable", "general.filetype.tif", fallback: "TIF image")
        /// File extension: .tiff. Commercial names should be stay on English
        public static let tiff = Strings.tr("Localizable", "general.filetype.tiff", fallback: "TIFF image")
        /// File extension: .ttf. Commercial names should be stay on English
        public static let ttf = Strings.tr("Localizable", "general.filetype.ttf", fallback: "TrueType font")
        /// File extension: .svg and .svgz. Commercial names should be stay on English
        public static let vectorImage = Strings.tr("Localizable", "general.filetype.vectorImage", fallback: "Vector Image")
        /// File extension: .wav. Commercial names should be stay on English
        public static let wav = Strings.tr("Localizable", "general.filetype.wav", fallback: "Wave audio")
        /// File extension: .webm. Commercial names should be stay on English
        public static let webm = Strings.tr("Localizable", "general.filetype.webm", fallback: "WebM video")
        /// File extension: .wma. Commercial names should be stay on English
        public static let wma = Strings.tr("Localizable", "general.filetype.wma", fallback: "WM audio")
        /// File extension: .wmv. Commercial names should be stay on English
        public static let wmv = Strings.tr("Localizable", "general.filetype.wmv", fallback: "WM video")
        /// File extension: .dotx. Commercial names should be stay on English
        public static let wordTemplate = Strings.tr("Localizable", "general.filetype.wordTemplate", fallback: "MS Word template")
        /// File extension: .xml. Commercial names should be stay on English
        public static let xml = Strings.tr("Localizable", "general.filetype.xml", fallback: "XML document")
        /// File extension: .zip. Commercial names should be stay on English
        public static let zip = Strings.tr("Localizable", "general.filetype.zip", fallback: "ZIP archive")
      }
      public enum Format {
        /// Plural format key: "%#@count@"
        public static func itemsSelected(_ p1: Int) -> String {
          return Strings.tr("Localizable", "general.format.itemsSelected", p1, fallback: "Plural format key: \"%#@count@\"")
        }
        public enum Count {
          /// Plural format key: "%#@file@"
          public static func file(_ p1: Int) -> String {
            return Strings.tr("Localizable", "general.format.count.file", p1, fallback: "Plural format key: \"%#@file@\"")
          }
          /// Plural format key: "%#@folder@"
          public static func folder(_ p1: Int) -> String {
            return Strings.tr("Localizable", "general.format.count.folder", p1, fallback: "Plural format key: \"%#@folder@\"")
          }
          /// Plural format key: "%#@item@"
          public static func items(_ p1: Int) -> String {
            return Strings.tr("Localizable", "general.format.count.items", p1, fallback: "Plural format key: \"%#@item@\"")
          }
          public enum FolderAndFile {
            /// Plural format key: "%#@file@"
            public static func file(_ p1: Int) -> String {
              return Strings.tr("Localizable", "general.format.count.folderAndFile.file", p1, fallback: "Plural format key: \"%#@file@\"")
            }
            /// Plural format key: "%#@folder@"
            public static func folder(_ p1: Int) -> String {
              return Strings.tr("Localizable", "general.format.count.folderAndFile.folder", p1, fallback: "Plural format key: \"%#@folder@\"")
            }
          }
        }
        public enum RetentionPeriod {
          /// Plural format key: "%#@day@"
          public static func day(_ p1: Int) -> String {
            return Strings.tr("Localizable", "general.format.retentionPeriod.day", p1, fallback: "Plural format key: \"%#@day@\"")
          }
          /// Plural format key: "%#@hour@"
          public static func hour(_ p1: Int) -> String {
            return Strings.tr("Localizable", "general.format.retentionPeriod.hour", p1, fallback: "Plural format key: \"%#@hour@\"")
          }
          /// Plural format key: "%#@month@"
          public static func month(_ p1: Int) -> String {
            return Strings.tr("Localizable", "general.format.retentionPeriod.month", p1, fallback: "Plural format key: \"%#@month@\"")
          }
          /// Plural format key: "%#@week@"
          public static func week(_ p1: Int) -> String {
            return Strings.tr("Localizable", "general.format.retentionPeriod.week", p1, fallback: "Plural format key: \"%#@week@\"")
          }
          /// Plural format key: "%#@year@"
          public static func year(_ p1: Int) -> String {
            return Strings.tr("Localizable", "general.format.retentionPeriod.year", p1, fallback: "Plural format key: \"%#@year@\"")
          }
        }
        public enum RubbishBin {
          /// Plural format key: "%#@days@"
          public static func days(_ p1: Int) -> String {
            return Strings.tr("Localizable", "general.format.rubbishBin.days", p1, fallback: "Plural format key: \"%#@days@\"")
          }
        }
      }
      public enum MenuAction {
        /// Title for action that allows user to delete files or folders permanently from Rubbish Bin
        public static let deletePermanently = Strings.tr("Localizable", "general.menuAction.deletePermanently", fallback: "Delete permanently")
        /// Title for files or folders action that allows user to 'Move to Rubbish Bin'
        public static let moveToRubbishBin = Strings.tr("Localizable", "general.menuAction.moveToRubbishBin", fallback: "Move to Rubbish bin")
        public enum ExportFile {
          /// Plural format key: "%#@file@"
          public static func title(_ p1: Int) -> String {
            return Strings.tr("Localizable", "general.menuAction.exportFile.title", p1, fallback: "Plural format key: \"%#@file@\"")
          }
        }
        public enum ManageLink {
          /// Plural format key: "%#@link@"
          public static func title(_ p1: Int) -> String {
            return Strings.tr("Localizable", "general.menuAction.manageLink.title", p1, fallback: "Plural format key: \"%#@link@\"")
          }
        }
        public enum RemoveLink {
          /// Plural format key: "%#@link@"
          public static func title(_ p1: Int) -> String {
            return Strings.tr("Localizable", "general.menuAction.removeLink.title", p1, fallback: "Plural format key: \"%#@link@\"")
          }
          public enum DoubleCheck {
            public enum Warning {
              /// Plural format key: "%#@link@"
              public static func message(_ p1: Int) -> String {
                return Strings.tr("Localizable", "general.menuAction.removeLink.doubleCheck.warning.message", p1, fallback: "Plural format key: \"%#@link@\"")
              }
              /// Plural format key: "%#@link@"
              public static func title(_ p1: Int) -> String {
                return Strings.tr("Localizable", "general.menuAction.removeLink.doubleCheck.warning.title", p1, fallback: "Plural format key: \"%#@link@\"")
              }
            }
          }
          public enum Message {
            /// Plural format key: "%#@link@"
            public static func success(_ p1: Int) -> String {
              return Strings.tr("Localizable", "general.menuAction.removeLink.message.success", p1, fallback: "Plural format key: \"%#@link@\"")
            }
          }
        }
        public enum ShareFolder {
          /// Plural format key: "%#@folder@"
          public static func title(_ p1: Int) -> String {
            return Strings.tr("Localizable", "general.menuAction.shareFolder.title", p1, fallback: "Plural format key: \"%#@folder@\"")
          }
        }
        public enum ShareLink {
          /// Plural format key: "%#@link@"
          public static func title(_ p1: Int) -> String {
            return Strings.tr("Localizable", "general.menuAction.shareLink.title", p1, fallback: "Plural format key: \"%#@link@\"")
          }
        }
        public enum VerifyContact {
          /// Context menu item. Allows the user to verify contacts of the shared folder. The %@ placeholder will be replaced with the contact's name
          public static func title(_ p1: Any) -> String {
            return Strings.tr("Localizable", "general.menuAction.verifyContact.title", String(describing: p1), fallback: "Approve %@")
          }
        }
      }
      public enum SaveToPhotos {
        /// Plural format key: "%#@count@"
        public static func started(_ p1: Int) -> String {
          return Strings.tr("Localizable", "general.saveToPhotos.started", p1, fallback: "Plural format key: \"%#@count@\"")
        }
      }
      public enum Security {
        /// Name for the recovery key file
        public static let recoveryKeyFile = Strings.tr("Localizable", "general.security.recoveryKeyFile", fallback: "MEGA-RECOVERYKEY")
      }
      public enum TextEditor {
        public enum Hud {
          /// Hud info message when edit large text file.
          public static let uneditableLargeFile = Strings.tr("Localizable", "general.textEditor.hud.uneditableLargeFile", fallback: "File is too large and cannot be edited.")
          /// Hud info message when read unknown encode file.
          public static let unknownEncode = Strings.tr("Localizable", "general.textEditor.hud.unknownEncode", fallback: "File could not be edited due to unknown content encoding.")
        }
      }
    }
    public enum Help {
      public enum ReportIssue {
        /// Label to indicate the user that needs to describe the issue through the text edit field of bug report form.
        public static let describe = Strings.tr("Localizable", "help.reportIssue.describe", fallback: "Please clearly describe the issue you encountered. The more details you provide, the easier it will be for us to resolve. Your submission will be reviewed by our development team.")
        /// Title of the dialog button to discard a report.
        public static let discardReport = Strings.tr("Localizable", "help.reportIssue.discardReport", fallback: "Discard report")
        /// Switch to confirm the attachment and upload of log files generated by iOS to our support team.
        public static let sendLogFile = Strings.tr("Localizable", "help.reportIssue.sendLogFile", fallback: "Send log file")
        /// Title of the dialog used to send bug reports to support team.
        public static let title = Strings.tr("Localizable", "help.reportIssue.title", fallback: "Report issue")
        /// Title to indicate that the bug report is being uploaded to our support team.
        public static let uploadingLogFile = Strings.tr("Localizable", "help.reportIssue.uploadingLogFile", fallback: "Uploading log file")
        public enum AttachLogFiles {
          /// Alert message to confirm if the users want to attach log files generated by iOS to our support team.
          public static let message = Strings.tr("Localizable", "help.reportIssue.attachLogFiles.message", fallback: "Do you want to attach diagnostic log files to assist with debug?")
          /// Alert title to confirm if the users want to attach log files generated by iOS to our support team.
          public static let title = Strings.tr("Localizable", "help.reportIssue.attachLogFiles.title", fallback: "Attach log files")
        }
        public enum Creating {
          public enum Cancel {
            /// Confirmation message shown when the user is trying to cancel the ongoing upload report.
            public static let message = Strings.tr("Localizable", "help.reportIssue.creating.cancel.message", fallback: "This issue will not be reported if you cancel uploading it.")
            /// Confirmation title shown when the user is trying to cancel the ongoing upload report.
            public static let title = Strings.tr("Localizable", "help.reportIssue.creating.cancel.title", fallback: "Are you sure you want to cancel uploading your reported issue?")
          }
        }
        public enum DescribeIssue {
          /// Placeholder to indicate the user that needs to describe the issue through the text edit field of bug report form.
          public static let placeholder = Strings.tr("Localizable", "help.reportIssue.describeIssue.placeholder", fallback: "Describe the issue")
        }
        public enum Fail {
          /// Error message shown when some error occurs during uploading a bug report.
          public static let message = Strings.tr("Localizable", "help.reportIssue.fail.message", fallback: "Unable to submit your report. Please try again.")
        }
        public enum Success {
          /// Confirmation message shown when a bug report is successfully uploaded.
          public static let message = Strings.tr("Localizable", "help.reportIssue.success.message", fallback: "Thanks. We’ll look into this issue and a member of our team will get back to you.")
          /// Confirmation title shown when a bug report is successfully uploaded.
          public static let title = Strings.tr("Localizable", "help.reportIssue.success.title", fallback: "Thanks for your feedback")
        }
      }
    }
    public enum Home {
      public enum Favourites {
        /// Title of Favourites explorer view card on Home
        public static let title = Strings.tr("Localizable", "home.favourites.title", fallback: "Favourites")
      }
      public enum Images {
        /// Photo Explorer Screen: No images in the account
        public static let empty = Strings.tr("Localizable", "home.images.empty", fallback: "No images found")
        /// Image title for the photo explorer
        public static let title = Strings.tr("Localizable", "home.images.title", fallback: "Images")
      }
      public enum Recent {
        /// Label that indicates who uploaded a file into a recents bucket. %@ is a placeholder for a name, eg: Haley
        public static func createdByLabel(_ p1: Any) -> String {
          return Strings.tr("Localizable", "home.recent.createdByLabel", String(describing: p1), fallback: "Created by %@")
        }
        /// Label that indicates who modified a file into a recents bucket. %@ is a placeholder for a name, eg: Haley
        public static func modifiedByLabel(_ p1: Any) -> String {
          return Strings.tr("Localizable", "home.recent.modifiedByLabel", String(describing: p1), fallback: "Modified by %@")
        }
        /// Title for a recent action bucket with multiple files. %@ will be replaced by the filename of the first file in the bucket. %ld will be replaced by the total number of other files in the bucket.
        public static func multipleFileTitle(_ p1: Any, _ p2: Int) -> String {
          return Strings.tr("Localizable", "home.recent.multipleFileTitle", String(describing: p1), p2, fallback: "“%@” and %ld more")
        }
      }
    }
    public enum InAppPurchase {
      public enum Error {
        public enum Alert {
          /// Button that redirect you to the main page of your Account in the App Store
          public static let primaryButtonTitle = Strings.tr("Localizable", "inAppPurchase.error.alert.primaryButtonTitle", fallback: "App Store settings")
          public enum Title {
            /// Alert title shown when a selected plan is not available at that moment on the App store
            public static let notAvailable = Strings.tr("Localizable", "inAppPurchase.error.alert.title.notAvailable", fallback: "This In-App Purchase item is not available in the App Store at this time. Please verify payment settings for your Apple ID.")
          }
        }
      }
      public enum ProductDetail {
        public enum Navigation {
          /// A label which shows the user's current PRO plan.
          public static let currentPlan = Strings.tr("Localizable", "inAppPurchase.productDetail.navigation.currentPlan", fallback: "Current plan")
        }
      }
      public enum Upgrade {
        public enum Label {
          /// Text shown on the upgrade account page above the current PRO plan subscription
          public static let currentPlan = Strings.tr("Localizable", "inAppPurchase.upgrade.label.currentPlan", fallback: "Current plan:")
        }
      }
    }
    public enum Inapp {
      public enum Notifications {
        public enum Meetings {
          /// In App notification for meetings
          public static let header = Strings.tr("Localizable", "inapp.notifications.meetings.header", fallback: "Meetings")
        }
        public enum ScheduledMeetings {
          public enum OneOff {
            public enum Cancelled {
              /// In app notification description for one off cancelled meeting
              public static let description = Strings.tr("Localizable", "inapp.notifications.scheduledMeetings.oneOff.cancelled.description", fallback: "[B][Email] cancelled[/B] the meeting scheduled for")
            }
            public enum DayChanged {
              /// In app notification description representing the day was changed for one off meeting
              public static let description = Strings.tr("Localizable", "inapp.notifications.scheduledMeetings.oneOff.dayChanged.description", fallback: "[B][Email] updated[/B] the meeting date to")
            }
            public enum DescriptionFieldUpdate {
              /// In app notification description for scheduled meeting description field update
              public static let description = Strings.tr("Localizable", "inapp.notifications.scheduledMeetings.oneOff.descriptionFieldUpdate.description", fallback: "[B][Email] updated[/B] the meeting description")
            }
            public enum MulitpleFieldsUpdate {
              /// In app notification description for scheduled meeting when multiple fields updated for one off meeting
              public static let description = Strings.tr("Localizable", "inapp.notifications.scheduledMeetings.oneOff.mulitpleFieldsUpdate.description", fallback: "[B][Email] updated[/B] the meeting to")
            }
            public enum New {
              /// In app notification description for one off new meeting invitation
              public static let description = Strings.tr("Localizable", "inapp.notifications.scheduledMeetings.oneOff.new.description", fallback: "[B][Email] invited[/B] you to a meeting scheduled for:")
            }
            public enum TimeChanged {
              /// In app notification description representing the time was changed for one off meeting
              public static let description = Strings.tr("Localizable", "inapp.notifications.scheduledMeetings.oneOff.timeChanged.description", fallback: "[B][Email] updated[/B] the meeting time to")
            }
          }
          public enum Recurring {
            public enum Cancelled {
              /// In app notification description for cancelled recurring meeting
              public static let description = Strings.tr("Localizable", "inapp.notifications.scheduledMeetings.recurring.cancelled.description", fallback: "[B][Email] cancelled[/B] the meeting and all its occurrences")
            }
            public enum DayChanged {
              /// In app notification description when date field is updated for recurring meeting.
              public static let description = Strings.tr("Localizable", "inapp.notifications.scheduledMeetings.recurring.dayChanged.description", fallback: "[B][Email] updated[/B] the recurring meeting date to")
            }
            public enum DescriptionFieldUpdate {
              /// In app notification description for description Field update in recurring meeting.
              public static let description = Strings.tr("Localizable", "inapp.notifications.scheduledMeetings.recurring.descriptionFieldUpdate.description", fallback: "[B][Email] updated[/B] the recurring meeting description")
            }
            public enum MulitpleFieldsUpdate {
              /// In app notification description for multiple fields update in recurring meeting.
              public static let description = Strings.tr("Localizable", "inapp.notifications.scheduledMeetings.recurring.mulitpleFieldsUpdate.description", fallback: "[B][Email] updated[/B] the meeting to")
            }
            public enum New {
              /// In app notification description for recurring new meeting invitation.
              public static let description = Strings.tr("Localizable", "inapp.notifications.scheduledMeetings.recurring.new.description", fallback: "[B][Email][/B] invited you to a recurring meeting scheduled for:")
            }
            public enum OccurrenceCancelled {
              /// In app notification description when an occurence is cancelled in a recurring meeting.
              public static let description = Strings.tr("Localizable", "inapp.notifications.scheduledMeetings.recurring.occurrenceCancelled.description", fallback: "[B][Email] cancelled[/B] the occurrence scheduled for")
            }
            public enum OccurrenceUpdated {
              /// In app notification description when an occurence is updated in a recurring meeting.
              public static let description = Strings.tr("Localizable", "inapp.notifications.scheduledMeetings.recurring.occurrenceUpdated.description", fallback: "[B][Email] updated[/B] an occurrence to")
            }
            public enum TimeChanged {
              /// In app notification description when time field is updated for recurring meeting.
              public static let description = Strings.tr("Localizable", "inapp.notifications.scheduledMeetings.recurring.timeChanged.description", fallback: "[B][Email] updated[/B] the recurring meeting time to")
            }
          }
          public enum TitleUpdate {
            /// In app notification description for scheduled meeting title update.
            public static let description = Strings.tr("Localizable", "inapp.notifications.scheduledMeetings.titleUpdate.description", fallback: "[B][Email] updated[/B] the meeting name from “[PreviousTitle]” to [B]“[UpdatedTitle]”[/B]")
          }
          public enum WeekDay {
            public enum MidSentence {
              public enum Fri {
                /// In app notification description text representing the meeting repeats every friday. This text is used in the middle of the sentence.
                public static let title = Strings.tr("Localizable", "inapp.notifications.scheduledMeetings.weekDay.midSentence.fri.title", fallback: "Fri")
              }
              public enum Mon {
                /// In app notification description text representing the meeting repeats every monday. This text is used in the middle of the sentence.
                public static let title = Strings.tr("Localizable", "inapp.notifications.scheduledMeetings.weekDay.midSentence.mon.title", fallback: "Mon")
              }
              public enum Sat {
                /// In app notification description text representing the meeting repeats every saturday. This text is used in the middle of the sentence.
                public static let title = Strings.tr("Localizable", "inapp.notifications.scheduledMeetings.weekDay.midSentence.sat.title", fallback: "Sat")
              }
              public enum Sun {
                /// In app notification description text representing the meeting repeats every sunday. This text is used in the middle of the sentence.
                public static let title = Strings.tr("Localizable", "inapp.notifications.scheduledMeetings.weekDay.midSentence.sun.title", fallback: "Sun")
              }
              public enum Thu {
                /// In app notification description text representing the meeting repeats every thursday. This text is used in the middle of the sentence.
                public static let title = Strings.tr("Localizable", "inapp.notifications.scheduledMeetings.weekDay.midSentence.thu.title", fallback: "Thu")
              }
              public enum Tue {
                /// In app notification description text representing the meeting repeats every tuesday. This text is used in the middle of the sentence.
                public static let title = Strings.tr("Localizable", "inapp.notifications.scheduledMeetings.weekDay.midSentence.tue.title", fallback: "Tue")
              }
              public enum Wed {
                /// In app notification description text representing the meeting repeats every wednesday. This text is used in the middle of the sentence.
                public static let title = Strings.tr("Localizable", "inapp.notifications.scheduledMeetings.weekDay.midSentence.wed.title", fallback: "Wed")
              }
            }
            public enum SentenceStart {
              public enum Fri {
                /// In app notification description text representing the meeting repeats every friday. This text is used at the start of the sentence.
                public static let title = Strings.tr("Localizable", "inapp.notifications.scheduledMeetings.weekDay.sentenceStart.fri.title", fallback: "Fri")
              }
              public enum Mon {
                /// In app notification description text representing the meeting repeats every monday. This text is used at the start of the sentence.
                public static let title = Strings.tr("Localizable", "inapp.notifications.scheduledMeetings.weekDay.sentenceStart.mon.title", fallback: "Mon")
              }
              public enum Sat {
                /// In app notification description text representing the meeting repeats every saturday. This text is used at the start of the sentence.
                public static let title = Strings.tr("Localizable", "inapp.notifications.scheduledMeetings.weekDay.sentenceStart.sat.title", fallback: "Sat")
              }
              public enum Sun {
                /// In app notification description text representing the meeting repeats every sunday. This text is used at the start of the sentence.
                public static let title = Strings.tr("Localizable", "inapp.notifications.scheduledMeetings.weekDay.sentenceStart.sun.title", fallback: "Sun")
              }
              public enum Thu {
                /// In app notification description text representing the meeting repeats every thursday. This text is used at the start of the sentence.
                public static let title = Strings.tr("Localizable", "inapp.notifications.scheduledMeetings.weekDay.sentenceStart.thu.title", fallback: "Thu")
              }
              public enum Tue {
                /// In app notification description text representing the meeting repeats every tuesday. This text is used at the start of the sentence.
                public static let title = Strings.tr("Localizable", "inapp.notifications.scheduledMeetings.weekDay.sentenceStart.tue.title", fallback: "Tue")
              }
              public enum Wed {
                /// In app notification description text representing the meeting repeats every wednesday. This text is used at the start of the sentence.
                public static let title = Strings.tr("Localizable", "inapp.notifications.scheduledMeetings.weekDay.sentenceStart.wed.title", fallback: "Wed")
              }
            }
          }
        }
      }
    }
    public enum Invite {
      public enum ContactLink {
        public enum Share {
          /// Text title showed when users share the contact link
          public static let title = Strings.tr("Localizable", "invite.contactLink.share.title", fallback: "Send invitation")
        }
      }
    }
    public enum Media {
      public enum Audio {
        public enum PlaybackContinuation {
          public enum Dialog {
            /// Description of Audio Player dialog for Playback Continuation
            public static func description(_ p1: Any, _ p2: Any) -> String {
              return Strings.tr("Localizable", "media.audio.playbackContinuation.dialog.description", String(describing: p1), String(describing: p2), fallback: "“%@” will resume from %@.")
            }
            /// Restart option for Audio Player dialog for Playback Continuation
            public static let restart = Strings.tr("Localizable", "media.audio.playbackContinuation.dialog.restart", fallback: "Restart")
            /// Resume option for Audio Player dialog for Playback Continuation
            public static let resume = Strings.tr("Localizable", "media.audio.playbackContinuation.dialog.resume", fallback: "Resume")
            /// Title of Audio Player dialog for Playback Continuation
            public static let title = Strings.tr("Localizable", "media.audio.playbackContinuation.dialog.title", fallback: "Resume audio?")
          }
        }
        public enum Playlist {
          public enum Section {
            public enum Next {
              /// Title of section Next on Audio Playlist
              public static let title = Strings.tr("Localizable", "media.audio.playlist.section.next.title", fallback: "Next")
            }
          }
        }
      }
      public enum Photo {
        public enum Browser {
          /// Plural format key: "%#@total@"
          public static func indexOfTotalFiles(_ p1: Int) -> String {
            return Strings.tr("Localizable", "media.photo.browser.indexOfTotalFiles", p1, fallback: "Plural format key: \"%#@total@\"")
          }
        }
      }
      public enum PhotoLibrary {
        public enum Category {
          public enum All {
            /// Title of Photo's All date tab
            public static let title = Strings.tr("Localizable", "media.photoLibrary.category.all.title", fallback: "All")
          }
          public enum Days {
            /// Title of Photo's Days tab
            public static let title = Strings.tr("Localizable", "media.photoLibrary.category.days.title", fallback: "Days")
          }
          public enum Months {
            /// Title of Photo's Months tab
            public static let title = Strings.tr("Localizable", "media.photoLibrary.category.months.title", fallback: "Months")
          }
          public enum Years {
            /// Title of Photo's Years tab
            public static let title = Strings.tr("Localizable", "media.photoLibrary.category.years.title", fallback: "Years")
          }
        }
      }
      public enum Quality {
        /// Automatic quality option used on Chat Image uploads. Indicating that the image quality will be determine by MEGA.
        public static let automatic = Strings.tr("Localizable", "media.quality.automatic", fallback: "Automatic")
        /// Best quality option for exporting file in Scan document.
        public static let best = Strings.tr("Localizable", "media.quality.best", fallback: "Best")
        /// High quality option used on CU and Chat Video uploads.
        public static let high = Strings.tr("Localizable", "media.quality.high", fallback: "High")
        /// Low quality option used on CU and Chat Video uploads and exporting file in Scan Document.
        public static let low = Strings.tr("Localizable", "media.quality.low", fallback: "Low")
        /// Medium quality option used on CU and Chat Video uploads and exporting file in Scan Document.
        public static let medium = Strings.tr("Localizable", "media.quality.medium", fallback: "Medium")
        /// Optimised quality option used on Chat Images. Indicating that the image will be optimised.
        public static let optimised = Strings.tr("Localizable", "media.quality.optimised", fallback: "Optimised")
        /// Original quality option used on CU Videos and Chat's image and video uploads. Indicating that the media quality will be the same.
        public static let original = Strings.tr("Localizable", "media.quality.original", fallback: "Original")
      }
    }
    public enum Meetings {
      /// Message to inform the local user is having a bad quality network with someone in the current group call
      public static let poorConnection = Strings.tr("Localizable", "meetings.poorConnection", fallback: "Bad connection")
      public enum Action {
        /// Action of a call/meeting to rename it
        public static let rename = Strings.tr("Localizable", "meetings.action.rename", fallback: "Rename meeting")
        /// Action of a call/meeting to share its link
        public static let shareLink = Strings.tr("Localizable", "meetings.action.shareLink", fallback: "Share meeting link")
      }
      public enum AddContacts {
        public enum AllContactsAdded {
          /// Contacts selection screen: Button title for the alert that is shown when all the contacts are already added to the chatRoom
          public static let confirmationButtonTitle = Strings.tr("Localizable", "meetings.addContacts.allContactsAdded.confirmationButtonTitle", fallback: "Invite")
          /// Contacts selection screen: Alert message shown when all the contacts are already added to the chatRoom
          public static let description = Strings.tr("Localizable", "meetings.addContacts.allContactsAdded.description", fallback: "You’ve already added all your contacts to this chat.\nIf you want to add more participants, first invite them to your contact list.")
          /// Contacts selection screen: Alert title shown when all the contacts are already added to the chatRoom
          public static let title = Strings.tr("Localizable", "meetings.addContacts.allContactsAdded.title", fallback: "All contacts added")
        }
        public enum AllowNonHost {
          /// Add contacts: Message to allow non host to add contacts in the group chat and meeting
          public static let message = Strings.tr("Localizable", "meetings.addContacts.allowNonHost.message", fallback: "Allow non-hosts to add participants")
        }
        public enum ZeroContactsAvailable {
          /// Contacts selection screen: Alert message shown when no contacts are available to be added to the chatRoom
          public static let description = Strings.tr("Localizable", "meetings.addContacts.zeroContactsAvailable.description", fallback: "You have no contacts to add to this chat. If you want to add participants, first invite them to your contact list.")
          /// Contacts selection screen: Alert title shown when no contacts are available to be added to the chatRoom
          public static let title = Strings.tr("Localizable", "meetings.addContacts.zeroContactsAvailable.title", fallback: "No contacts")
        }
      }
      public enum Alert {
        /// Shown when an invalid/inexisting/not-available-anymore meeting link is opened.
        public static let end = Strings.tr("Localizable", "meetings.alert.end", fallback: "Meeting ended")
        /// Meeting ended Alert button -- View Meeting Chat history.
        public static let meetingchat = Strings.tr("Localizable", "meetings.alert.meetingchat", fallback: "View chat history")
        public enum End {
          /// Shown description when an invalid/inexisting/not-available-anymore meeting link is opened.
          public static let description = Strings.tr("Localizable", "meetings.alert.end.description", fallback: "The meeting you’re trying to join has already ended. You can still view the meeting chat history.")
        }
      }
      public enum Create {
        /// Text button for init a Meeting.
        public static let newMeeting = Strings.tr("Localizable", "meetings.create.newMeeting", fallback: "New meeting")
      }
      public enum CreateMeeting {
        /// Meeting Title
        public static func defaultMeetingName(_ p1: Any) -> String {
          return Strings.tr("Localizable", "meetings.createMeeting.defaultMeetingName", String(describing: p1), fallback: "%@’s meeting")
        }
        /// Start meeting button title
        public static let startMeeting = Strings.tr("Localizable", "meetings.createMeeting.startMeeting", fallback: "Start meeting")
      }
      public enum DisplayInMainView {
        /// Menu title in meetings that allows to switch to main view for a participant.
        public static let title = Strings.tr("Localizable", "meetings.displayInMainView.title", fallback: "Display in main view")
      }
      public enum EndCall {
        /// Button and title text that ends the meeting for all
        public static let endForAllButtonTitle = Strings.tr("Localizable", "meetings.endCall.endForAllButtonTitle", fallback: "End call for all")
        public enum EndForAllAlert {
          /// Button title - tapping on the button dismiss without ending the call.
          public static let cancel = Strings.tr("Localizable", "meetings.endCall.endForAllAlert.cancel", fallback: "No")
          /// Button title - tapping on the button will end the call.
          public static let confirm = Strings.tr("Localizable", "meetings.endCall.endForAllAlert.confirm", fallback: "Yes")
          /// Description of the popup that ends the meeting for all
          public static let description = Strings.tr("Localizable", "meetings.endCall.endForAllAlert.description", fallback: "This will end the call for all participants.")
          /// Title of the popup that ends the meeting for all
          public static let title = Strings.tr("Localizable", "meetings.endCall.endForAllAlert.title", fallback: "End call for all?")
        }
      }
      public enum EndCallDialog {
        /// Meetings end call dialog description
        public static let description = Strings.tr("Localizable", "meetings.endCallDialog.description", fallback: "Call will automatically end in 2 mins unless you want to stay on it.")
        /// Meetings end call dialog button title
        public static let endCallNowButtonTitle = Strings.tr("Localizable", "meetings.endCallDialog.endCallNowButtonTitle", fallback: "End call now")
        /// Meetings end call dialog Stay on call button title
        public static let stayOnCallButtonTitle = Strings.tr("Localizable", "meetings.endCallDialog.stayOnCallButtonTitle", fallback: "Stay on call")
        /// Meetings end call dialog title
        public static let title = Strings.tr("Localizable", "meetings.endCallDialog.title", fallback: "You’re the only one here")
      }
      public enum EndForAll {
        /// Label for end a group chat or meeting when the user is moderator
        public static let buttonTitle = Strings.tr("Localizable", "meetings.endForAll.buttonTitle", fallback: "End for all")
      }
      public enum EnterMeetingLink {
        /// Title for Enter Meeting Link.
        public static let title = Strings.tr("Localizable", "meetings.enterMeetingLink.title", fallback: "Enter meeting link")
      }
      public enum Incompatibility {
        /// This message is shown when calling and the receiver is not picking up the call
        public static let warningMessage = Strings.tr("Localizable", "meetings.incompatibility.warningMessage", fallback: "We are upgrading MEGA Chat. Your calls might not be connected due to version incompatibility unless all parties update their MEGA Apps to the latest version.")
      }
      public enum Info {
        /// Title for chat notifications option in meeting info
        public static let chatNotifications = Strings.tr("Localizable", "meetings.info.chatNotifications", fallback: "Chat notifications")
        /// Label to introduce meeting info description field
        public static let descriptionLabel = Strings.tr("Localizable", "meetings.info.descriptionLabel", fallback: "Description")
        /// The button title that allows the user to leave a ad hoc meeting.
        public static let leaveMeeting = Strings.tr("Localizable", "meetings.info.leaveMeeting", fallback: "Leave meeting")
        /// Title for manage chat history option in meeting info
        public static let manageChatHistory = Strings.tr("Localizable", "meetings.info.manageChatHistory", fallback: "Manage chat history")
        /// Title for manage meeting history option in meeting info
        public static let manageMeetingHistory = Strings.tr("Localizable", "meetings.info.manageMeetingHistory", fallback: "Manage meeting history")
        /// Label to indicate the user about the activation of a meeting link
        public static let meetingLink = Strings.tr("Localizable", "meetings.info.meetingLink", fallback: "Meeting link")
        /// Title for meeting notifications option in meeting info
        public static let meetingNotifications = Strings.tr("Localizable", "meetings.info.meetingNotifications", fallback: "Meeting notifications")
        /// Meeting Notifications DND: Title bar message for the dnd activate options
        public static let muteMeetingNotificationsFor = Strings.tr("Localizable", "meetings.info.muteMeetingNotificationsFor", fallback: "Mute meeting notifications for")
        /// The title of a menu button which allows users to rename a meeting.
        public static let renameMeeting = Strings.tr("Localizable", "meetings.info.renameMeeting", fallback: "Rename meeting")
        /// Title for share chat link option in meeting info
        public static let shareChatLink = Strings.tr("Localizable", "meetings.info.shareChatLink", fallback: "Share chat link")
        /// Title for shared files option in meeting info
        public static let sharedFiles = Strings.tr("Localizable", "meetings.info.sharedFiles", fallback: "Shared files")
        /// Title for share meeting link option in meeting info
        public static let shareMeetingLink = Strings.tr("Localizable", "meetings.info.shareMeetingLink", fallback: "Share meeting link")
        public enum KeyRotation {
          /// Description for enable encryption key rotation option in meeting info
          public static let description = Strings.tr("Localizable", "meetings.info.keyRotation.description", fallback: "Key rotation is slightly more secure, but doesn’t allow you to create a chat link and hides past messages from new participants.")
          /// Title for enable encryption key rotation option in meeting info
          public static let title = Strings.tr("Localizable", "meetings.info.keyRotation.title", fallback: "Enable encryption key rotation")
        }
        public enum ManageMeetingHistory {
          /// The button or alert title to delete the history of a meeting.
          public static let clearMeetingHistory = Strings.tr("Localizable", "meetings.info.manageMeetingHistory.clearMeetingHistory", fallback: "Clear meeting history")
          /// The alert message to delete the history of a meeting.
          public static let clearMeetingHistoryMessage = Strings.tr("Localizable", "meetings.info.manageMeetingHistory.clearMeetingHistoryMessage", fallback: "Are you sure you want to clear the full message history of this meeting?")
          /// Message show when the history of a meeting has been successfully deleted
          public static let meetingHistoryHasBeenCleared = Strings.tr("Localizable", "meetings.info.manageMeetingHistory.meetingHistoryHasBeenCleared", fallback: "Meeting history cleared")
        }
        public enum Participants {
          /// Button title to load more participants in meeting info view
          public static let seeAll = Strings.tr("Localizable", "meetings.info.participants.seeAll", fallback: "See all")
          /// Button title to see less participants in meeting info view
          public static let seeLess = Strings.tr("Localizable", "meetings.info.participants.seeLess", fallback: "See less")
          /// Button title to load more participants in meeting info view
          public static let seeMore = Strings.tr("Localizable", "meetings.info.participants.seeMore", fallback: "See more")
        }
        public enum ShareMeetingLink {
          /// Text explaining users how the meeting links work.
          public static let explainLink = Strings.tr("Localizable", "meetings.info.shareMeetingLink.explainLink", fallback: "Anyone with this link can join the meeting and view the meeting chat")
        }
        public enum ShareOptions {
          /// Title for a button to send a file to a chat
          public static let sendToChat = Strings.tr("Localizable", "meetings.info.shareOptions.sendToChat", fallback: "Send to chat")
          /// Label to inform user about privacy of sharing a chat link
          public static let title = Strings.tr("Localizable", "meetings.info.shareOptions.title", fallback: "Anyone with this link can join the meeting and view the meeting chat.")
          public enum ShareLink {
            /// HUD message to inform user that the link is in the clipboard
            public static let linkCopied = Strings.tr("Localizable", "meetings.info.shareOptions.shareLink.linkCopied", fallback: "Copied link to clipboard")
          }
        }
      }
      public enum JoinMeeting {
        /// Message description when the user enters a invalid meeting URL
        public static let description = Strings.tr("Localizable", "meetings.joinMeeting.description", fallback: "Unable to join the meeting. Please check the link is valid.")
        /// Message header when the user enters a invalid meeting URL
        public static let header = Strings.tr("Localizable", "meetings.joinMeeting.header", fallback: "Invalid meeting URL")
      }
      public enum JoinMega {
        /// Encourage Guest User to Join Mega Screen Navigation Bar Title
        public static let title = Strings.tr("Localizable", "meetings.joinMega.title", fallback: "Join MEGA")
        public enum Paragraph1 {
          /// Guest user join Mega: paragraph 1 description
          public static let description = Strings.tr("Localizable", "meetings.joinMega.paragraph1.description", fallback: "Join the largest secure cloud storage and collaboration platform in the world.")
          /// Guest user join Mega: paragraph 1 title
          public static let title = Strings.tr("Localizable", "meetings.joinMega.paragraph1.title", fallback: "Your privacy matters")
        }
        public enum Paragraph2 {
          /// Guest user join Mega: paragraph 2 description
          public static let description = Strings.tr("Localizable", "meetings.joinMega.paragraph2.description", fallback: "Sign up now and enjoy advanced collaboration features for free.")
          /// Guest user join Mega: paragraph 2 title
          public static let title = Strings.tr("Localizable", "meetings.joinMega.paragraph2.title", fallback: "Get 20 GB for free")
        }
      }
      public enum LeaveCall {
        /// Label for hang a group chat or meeting when the user is moderator
        public static let buttonTitle = Strings.tr("Localizable", "meetings.leaveCall.buttonTitle", fallback: "Leave")
      }
      public enum Link {
        public enum Guest {
          /// Button text to join a meeting for the logged in user
          public static let joinButtonText = Strings.tr("Localizable", "meetings.link.guest.joinButtonText", fallback: "Join as guest")
        }
        public enum LoggedInUser {
          /// Button text to join a meeting for the logged in user
          public static let joinButtonText = Strings.tr("Localizable", "meetings.link.loggedInUser.joinButtonText", fallback: "Join meeting")
        }
      }
      public enum Message {
        /// Message to inform the local user that someone has joined the current group call
        public static func joinedCall(_ p1: Any) -> String {
          return Strings.tr("Localizable", "meetings.message.joinedCall", String(describing: p1), fallback: "%@ joined the call")
        }
        /// Message to inform the local user that someone has left the current group call
        public static func leftCall(_ p1: Any) -> String {
          return Strings.tr("Localizable", "meetings.message.leftCall", String(describing: p1), fallback: "%@ left the call")
        }
        /// Message shown when the user is the only one left in the meeting
        public static let noOtherParticipants = Strings.tr("Localizable", "meetings.message.noOtherParticipants", fallback: "You are the only one here…")
        /// Message shown when a meeting starts and user is waiting other users to join
        public static let waitingOthers = Strings.tr("Localizable", "meetings.message.waitingOthers", fallback: "Waiting for others to join…")
      }
      public enum New {
        /// Error text shown when trying to create or join a new meeting given that the user is already in another meeting
        public static let anotherAlreadyExistsError = Strings.tr("Localizable", "meetings.new.anotherAlreadyExistsError", fallback: "Another call in progress. Please end your current call before making another.")
        public enum AnotherAlreadyExistsError {
          /// Button option when trying to join a new meeting given that the user is already in another meeting
          public static let endAndJoin = Strings.tr("Localizable", "meetings.new.anotherAlreadyExistsError.endAndJoin", fallback: "End and join")
        }
      }
      public enum Notification {
        /// Meetings: Notification message to be shown to the user when the timer is set and call is going to end after the timer duration
        public static func endCallTimerDuration(_ p1: Any) -> String {
          return Strings.tr("Localizable", "meetings.notification.EndCallTimerDuration", String(describing: p1), fallback: "Call will end in %@")
        }
        /// Meetings: Notification message to be shown when more than 2 people are joining the call at the same time. The second %@ would display the number in spell out format.
        public static func moreThanTwoUsersJoined(_ p1: Any, _ p2: Any) -> String {
          return Strings.tr("Localizable", "meetings.notification.moreThanTwoUsersJoined", String(describing: p1), String(describing: p2), fallback: "%@ and %@ others joined")
        }
        /// Meetings: Notification message to be shown when more than 2 people are leaving the call at the same time. The second %@ would display the number in spell out format.
        public static func moreThanTwoUsersLeft(_ p1: Any, _ p2: Any) -> String {
          return Strings.tr("Localizable", "meetings.notification.moreThanTwoUsersLeft", String(describing: p1), String(describing: p2), fallback: "%@ and %@ others left the call")
        }
        /// Meetings: Notification message to be shown when one person joins the call.
        public static func singleUserJoined(_ p1: Any) -> String {
          return Strings.tr("Localizable", "meetings.notification.singleUserJoined", String(describing: p1), fallback: "%@ joined")
        }
        /// Meetings: Notification message to be shown when one person leaves the call.
        public static func singleUserLeft(_ p1: Any) -> String {
          return Strings.tr("Localizable", "meetings.notification.singleUserLeft", String(describing: p1), fallback: "%@ left the call")
        }
        /// Meetings: Notification message to be shown when two people join the call at the same time
        public static func twoUsersJoined(_ p1: Any, _ p2: Any) -> String {
          return Strings.tr("Localizable", "meetings.notification.twoUsersJoined", String(describing: p1), String(describing: p2), fallback: "%@ and %@ joined")
        }
        /// Meetings: Notification message to be shown when two people are leaving the call at the same time
        public static func twoUsersLeft(_ p1: Any, _ p2: Any) -> String {
          return Strings.tr("Localizable", "meetings.notification.twoUsersLeft", String(describing: p1), String(describing: p2), fallback: "%@ and %@ left the call")
        }
      }
      public enum Notifications {
        /// Message shown when the user privilege is changed to moderator
        public static let moderatorPrivilege = Strings.tr("Localizable", "meetings.notifications.moderatorPrivilege", fallback: "You are the new host")
      }
      public enum Panel {
        /// Contacts selection screen header: Invite contacts to meetings
        public static let inviteParticipants = Strings.tr("Localizable", "meetings.panel.InviteParticipants", fallback: "Invite participants")
        /// Meetings: Floating panel participants count header
        public static func participantsCount(_ p1: Int) -> String {
          return Strings.tr("Localizable", "meetings.panel.ParticipantsCount", p1, fallback: "Participants (%d)")
        }
        /// Meetings: Floating panel share link option
        public static let shareLink = Strings.tr("Localizable", "meetings.panel.shareLink", fallback: "Share link")
      }
      public enum Participant {
        /// Meetings: Action on a meeting that change participant's role to moderator
        public static let makeModerator = Strings.tr("Localizable", "meetings.participant.makeModerator", fallback: "Make host")
        /// Meetings: Floating panel participants listing indication if a participant is moderator
        public static let moderator = Strings.tr("Localizable", "meetings.participant.moderator", fallback: "Host")
        /// Meetings: Action on a meeting that remove participant's moderator role
        public static let removeModerator = Strings.tr("Localizable", "meetings.participant.removeModerator", fallback: "Remove as host")
      }
      public enum QuickAction {
        /// This is the button text for flipping the front and back camera in the floating panel for meetings
        public static let flip = Strings.tr("Localizable", "meetings.quickAction.flip", fallback: "Switch")
        /// This is the button text for enabling the loud speaker in the floating panel for meetings
        public static let speaker = Strings.tr("Localizable", "meetings.quickAction.speaker", fallback: "Speaker")
      }
      public enum Reconnecting {
        /// Title shown when the user lost the connection in a call/meeting, and the app is unable to reconnect after 30 seconds.
        public static let failed = Strings.tr("Localizable", "meetings.reconnecting.failed", fallback: "Unable to reconnect")
        /// Title shown when the user lost the connection in a call/meeting, and the app will try to reconnect the user again.
        public static let title = Strings.tr("Localizable", "meetings.reconnecting.title", fallback: "Reconnecting")
      }
      public enum ScheduleMeeting {
        /// Schedule meeting add participants field
        public static let addParticipants = Strings.tr("Localizable", "meetings.scheduleMeeting.addParticipants", fallback: "Add participants")
        /// Schedule meeting cancel button
        public static let cancel = Strings.tr("Localizable", "meetings.scheduleMeeting.cancel", fallback: "Cancel")
        /// Schedule meeting create button
        public static let create = Strings.tr("Localizable", "meetings.scheduleMeeting.create", fallback: "Create")
        /// Schedule meeting description field placeholder
        public static let description = Strings.tr("Localizable", "meetings.scheduleMeeting.description", fallback: "Add description")
        /// Schedule meeting end field
        public static let end = Strings.tr("Localizable", "meetings.scheduleMeeting.end", fallback: "Ends")
        /// Schedule meeting link field
        public static let link = Strings.tr("Localizable", "meetings.scheduleMeeting.link", fallback: "Meeting link")
        /// Schedule meeting creation complete
        public static let meetingCreated = Strings.tr("Localizable", "meetings.scheduleMeeting.meetingCreated", fallback: "Meeting created")
        /// Schedule meeting open invite field
        public static let openInvite = Strings.tr("Localizable", "meetings.scheduleMeeting.openInvite", fallback: "Allow non-hosts to add participants")
        /// Schedule meeting recurrence field
        public static let recurrence = Strings.tr("Localizable", "meetings.scheduleMeeting.recurrence", fallback: "Recurrence")
        /// Schedule meeting send calendar invite field
        public static let sendCalendarInvite = Strings.tr("Localizable", "meetings.scheduleMeeting.sendCalendarInvite", fallback: "Send calendar invite")
        /// Schedule meeting start field
        public static let start = Strings.tr("Localizable", "meetings.scheduleMeeting.start", fallback: "Starts")
        /// Schedule meeting view title
        public static let title = Strings.tr("Localizable", "meetings.scheduleMeeting.title", fallback: "Schedule meeting")
        /// Schedule meeting update button
        public static let update = Strings.tr("Localizable", "meetings.scheduleMeeting.update", fallback: "Update")
        /// Schedule meeting waiting room setting title
        public static let waitingRoom = Strings.tr("Localizable", "meetings.scheduleMeeting.waitingRoom", fallback: "Waiting room")
        public enum CalendarInvite {
          /// Schedule meeting calendar invite description
          public static let description = Strings.tr("Localizable", "meetings.scheduleMeeting.calendarInvite.description", fallback: "Email a calendar invite to participants so they can add the meeting to their calendars.")
        }
        public enum Create {
          public enum Daily {
            /// This text is shown to the user while creating a scheduled meeting. User can choose between Daily, weekly and Monthly options.
            public static let optionTitle = Strings.tr("Localizable", "meetings.scheduleMeeting.create.daily.optionTitle", fallback: "Daily")
          }
          public enum EndRecurrence {
            /// End Recurrence option title in creating schedule meeting screen.
            public static let title = Strings.tr("Localizable", "meetings.scheduleMeeting.create.endRecurrence.title", fallback: "End recurrence")
            public enum Option {
              /// End Recurrence never option title in creating schedule meeting screen.
              public static let never = Strings.tr("Localizable", "meetings.scheduleMeeting.create.endRecurrence.option.never", fallback: "Never")
              /// End Recurrence on date option title in creating schedule meeting screen.
              public static let onDate = Strings.tr("Localizable", "meetings.scheduleMeeting.create.endRecurrence.option.onDate", fallback: "On date")
            }
          }
          public enum Frequency {
            /// Create Schedule Meeting: The text is shown along with the selected frequency which can either be Daily, Weekly and Monthly.
            public static let optionTitle = Strings.tr("Localizable", "meetings.scheduleMeeting.create.frequency.optionTitle", fallback: "Frequency")
            public enum Picker {
              /// Create Schedule Meeting: This text is used as a accessibility label for frequency picker.
              public static let accessibilityLabel = Strings.tr("Localizable", "meetings.scheduleMeeting.create.frequency.picker.accessibilityLabel", fallback: "Select a frequency")
            }
          }
          public enum Interval {
            /// Create Schedule Meeting: The text is shown along with the selected interval.
            public static let optionTitle = Strings.tr("Localizable", "meetings.scheduleMeeting.create.interval.optionTitle", fallback: "Every")
            public enum Picker {
              /// Create Schedule Meeting: This text is used as a accessibility label for interval picker.
              public static let accessibilityLabel = Strings.tr("Localizable", "meetings.scheduleMeeting.create.interval.picker.accessibilityLabel", fallback: "Select a monthly interval")
            }
          }
          public enum Monthly {
            /// This text is shown to the user while creating a scheduled meeting. User can choose between Daily, weekly and Monthly options.
            public static let optionTitle = Strings.tr("Localizable", "meetings.scheduleMeeting.create.monthly.optionTitle", fallback: "Monthly")
            public enum Calendar {
              /// Create Schedule Meeting: Month custom option - header title for the calendar
              public static let headerTitle = Strings.tr("Localizable", "meetings.scheduleMeeting.create.monthly.calendar.headerTitle", fallback: "Each")
            }
            public enum WeekNumber {
              /// Create Schedule Meeting: Month custom option - fifth week option text
              public static let fifth = Strings.tr("Localizable", "meetings.scheduleMeeting.create.monthly.weekNumber.fifth", fallback: "fifth")
              /// Create Schedule Meeting: Month custom option - first week option text
              public static let first = Strings.tr("Localizable", "meetings.scheduleMeeting.create.monthly.weekNumber.first", fallback: "first")
              /// Create Schedule Meeting: Month custom option - fourth week option text
              public static let fourth = Strings.tr("Localizable", "meetings.scheduleMeeting.create.monthly.weekNumber.fourth", fallback: "fourth")
              /// Create Schedule Meeting: Month custom option - second week option text
              public static let second = Strings.tr("Localizable", "meetings.scheduleMeeting.create.monthly.weekNumber.second", fallback: "second")
              /// Create Schedule Meeting: Month custom option - third week option text
              public static let third = Strings.tr("Localizable", "meetings.scheduleMeeting.create.monthly.weekNumber.third", fallback: "third")
            }
            public enum WeekNumberAndWeekDay {
              /// Create Schedule Meeting: Month custom option - header title for choosing the week number and week day
              public static let headerTitle = Strings.tr("Localizable", "meetings.scheduleMeeting.create.monthly.weekNumberAndWeekDay.headerTitle", fallback: "On the…")
            }
          }
          public enum MonthlyRecurrenceOption {
            public enum DayThirtyFirstSelected {
              /// Create Schedule Meeting: Footnote shown to the user when the day selected is 31 of the month and the recurrence option is monthly.
              public static let footNote = Strings.tr("Localizable", "meetings.scheduleMeeting.create.monthlyRecurrenceOption.DayThirtyFirstSelected.footNote", fallback: "Some months don’t have 31 days. For these months, the occurrence will be scheduled for the last day of the month.")
            }
            public enum DayThirtySelected {
              /// Create Schedule Meeting: Footnote shown to the user when the day selected is 30 of the month and the recurrence option is monthly.
              public static let footNote = Strings.tr("Localizable", "meetings.scheduleMeeting.create.monthlyRecurrenceOption.DayThirtySelected.footNote", fallback: "Some months don’t have 30 days. For these months, the occurrence will be scheduled for the last day of the month.")
            }
            public enum DayTwentyNineSelected {
              /// Create Schedule Meeting: Footnote shown to the user when the day selected is 29 of the month and the recurrence option is monthly.
              public static let footNote = Strings.tr("Localizable", "meetings.scheduleMeeting.create.monthlyRecurrenceOption.DayTwentyNineSelected.footNote", fallback: "Some months don’t have 29 days. For these months, the occurrence will be scheduled for the last day of the month.")
            }
          }
          public enum RecurrenceOptionScreen {
            /// Recurrence option custom shown in the recurrence options screen while creating the schedule meeting.
            public static let custom = Strings.tr("Localizable", "meetings.scheduleMeeting.create.recurrenceOptionScreen.custom", fallback: "Custom")
            /// Recurrence option daily shown in the recurrence options screen while creating the schedule meeting.
            public static let daily = Strings.tr("Localizable", "meetings.scheduleMeeting.create.recurrenceOptionScreen.daily", fallback: "Every day")
            /// Recurrence option monthly shown in the recurrence options screen while creating the schedule meeting.
            public static let monthly = Strings.tr("Localizable", "meetings.scheduleMeeting.create.recurrenceOptionScreen.monthly", fallback: "Every month")
            /// Navigation title of the recurrence options screen while creating the schedule meeting.
            public static let navigationTitle = Strings.tr("Localizable", "meetings.scheduleMeeting.create.recurrenceOptionScreen.navigationTitle", fallback: "Recurrence")
            /// Recurrence option never shown in the recurrence options screen while creating the schedule meeting.
            public static let never = Strings.tr("Localizable", "meetings.scheduleMeeting.create.recurrenceOptionScreen.never", fallback: "Never")
            /// Recurrence option weekly shown in the recurrence options screen while creating the schedule meeting.
            public static let weekly = Strings.tr("Localizable", "meetings.scheduleMeeting.create.recurrenceOptionScreen.weekly", fallback: "Every week")
          }
          public enum SelectedRecurrence {
            public enum Daily {
              /// Plural format key: "%#@count@"
              public static func customInterval(_ p1: Int) -> String {
                return Strings.tr("Localizable", "meetings.scheduleMeeting.create.selectedRecurrence.daily.customInterval", p1, fallback: "Plural format key: \"%#@count@\"")
              }
            }
            public enum Weekly {
              /// Create Schedule Meeting: Schedule meeting repeats all days in a week. This text is shown in the main screen that shows all the options along with the selected recurrence option.
              public static let everyDay = Strings.tr("Localizable", "meetings.scheduleMeeting.create.selectedRecurrence.weekly.everyDay", fallback: "Daily")
            }
          }
          public enum SelectedRecurrenceOption {
            /// Recurrence option daily shown in the creating the schedule meeting screen as the selected option.
            public static let daily = Strings.tr("Localizable", "meetings.scheduleMeeting.create.selectedRecurrenceOption.daily", fallback: "Daily")
            /// Recurrence option monthly shown in the creating the schedule meeting screen as the selected option.
            public static let monthly = Strings.tr("Localizable", "meetings.scheduleMeeting.create.selectedRecurrenceOption.monthly", fallback: "Monthly")
            /// Recurrence option never shown in the creating the schedule meeting screen as the selected option.
            public static let never = Strings.tr("Localizable", "meetings.scheduleMeeting.create.selectedRecurrenceOption.never", fallback: "Never")
            /// Recurrence option weekly shown in the creating the schedule meeting screen as the selected option.
            public static let weekly = Strings.tr("Localizable", "meetings.scheduleMeeting.create.selectedRecurrenceOption.weekly", fallback: "Weekly")
          }
          public enum WeekDay {
            public enum Picker {
              /// Create Schedule Meeting: This text is used as a accessibility label for week day picker.
              public static let accessibilityLabel = Strings.tr("Localizable", "meetings.scheduleMeeting.create.weekDay.picker.accessibilityLabel", fallback: "Select a day of the week")
            }
          }
          public enum WeekNumber {
            public enum Picker {
              /// Create Schedule Meeting: This text is used as a accessibility label for week number picker.
              public static let accessibilityLabel = Strings.tr("Localizable", "meetings.scheduleMeeting.create.weekNumber.picker.accessibilityLabel", fallback: "Select a weekly interval")
            }
          }
          public enum Weekly {
            /// This text is shown to the user while creating a scheduled meeting. User can choose between Daily, weekly and Monthly options.
            public static let optionTitle = Strings.tr("Localizable", "meetings.scheduleMeeting.create.weekly.optionTitle", fallback: "Weekly")
          }
        }
        public enum CreateMeetingTip {
          /// Create meeting tip view message
          public static let message = Strings.tr("Localizable", "meetings.scheduleMeeting.createMeetingTip.message", fallback: "You can now schedule one-off and recurring meetings.")
          /// Create meeting tip view title
          public static let title = Strings.tr("Localizable", "meetings.scheduleMeeting.createMeetingTip.title", fallback: "Schedule meeting")
        }
        public enum Description {
          /// Schedule meeting description error
          public static let lenghtError = Strings.tr("Localizable", "meetings.scheduleMeeting.description.lenghtError", fallback: "Enter up to 3,000 characters")
        }
        public enum DiscardChanges {
          /// Schedule meeting discard changes cancellation
          public static let cancel = Strings.tr("Localizable", "meetings.scheduleMeeting.discardChanges.cancel", fallback: "Keep editing")
          /// Schedule meeting discard changes confirmation
          public static let confirm = Strings.tr("Localizable", "meetings.scheduleMeeting.discardChanges.confirm", fallback: "Discard changes")
          /// Schedule meeting discard changes title
          public static let title = Strings.tr("Localizable", "meetings.scheduleMeeting.discardChanges.title", fallback: "Discard changes or keep editing?")
        }
        public enum Link {
          /// Schedule meeting end field
          public static let description = Strings.tr("Localizable", "meetings.scheduleMeeting.link.description", fallback: "Anyone with this link can join the meeting and view the meeting chat.")
        }
        public enum MeetingName {
          /// Schedule meeting name error
          public static let lenghtError = Strings.tr("Localizable", "meetings.scheduleMeeting.meetingName.lenghtError", fallback: "Enter up to 30 characters")
          /// Schedule meeting name field placeholder
          public static let placeholder = Strings.tr("Localizable", "meetings.scheduleMeeting.meetingName.placeholder", fallback: "Meeting name")
        }
        public enum Notification {
          public enum MeetingStarts {
            public enum Button {
              /// Push notification: Button title to be shown when the meeting is about to start.
              public static let join = Strings.tr("Localizable", "meetings.scheduleMeeting.notification.meetingStarts.button.join", fallback: "Join")
              /// Push notification: Button title to be shown when the meeting is about to start.
              public static let message = Strings.tr("Localizable", "meetings.scheduleMeeting.notification.meetingStarts.button.message", fallback: "Message")
            }
          }
          public enum MeetingStartsInFifteenMins {
            /// Push notification message to be shown when the meeting is about to start in 15 min.
            public static let message = Strings.tr("Localizable", "meetings.scheduleMeeting.notification.meetingStartsInFifteenMins.message", fallback: "Meeting starts in 15 minutes")
          }
          public enum MeetingStartsNow {
            /// Push notification message to be shown when the meeting is about to start now.
            public static let message = Strings.tr("Localizable", "meetings.scheduleMeeting.notification.meetingStartsNow.message", fallback: "Meeting starts now")
          }
        }
        public enum Occurrence {
          public enum UpdateSuccessfull {
            /// Schedule meeting update: Success message shown when the schedule meeeting occurrence is updated successfully.
            public static let popupMessage = Strings.tr("Localizable", "meetings.scheduleMeeting.occurrence.updateSuccessfull.popupMessage", fallback: "Meeting occurrence updated")
          }
        }
        public enum RecurringMeetingTip {
          /// Recurring meeting tip view message
          public static let message = Strings.tr("Localizable", "meetings.scheduleMeeting.recurringMeetingTip.message", fallback: "You can view, cancel, or edit any occurrence of a recurring meeting by tapping and holding the meeting and selecting Occurrences.")
          /// Recurring meeting tip view message bold text
          public static let occurrences = Strings.tr("Localizable", "meetings.scheduleMeeting.recurringMeetingTip.occurrences", fallback: "Occurrences")
          /// Recurring meeting tip view title
          public static let title = Strings.tr("Localizable", "meetings.scheduleMeeting.recurringMeetingTip.title", fallback: "Manage recurring meetings")
        }
        public enum StartMeetingTip {
          /// Start meeting tip view message
          public static let message = Strings.tr("Localizable", "meetings.scheduleMeeting.startMeetingTip.message", fallback: "You can start the meeting before its scheduled time by tapping “Start meeting” in the meeting room.")
          /// Start meeting tip view message bold text
          public static let startMeeting = Strings.tr("Localizable", "meetings.scheduleMeeting.startMeetingTip.startMeeting", fallback: "Start meeting")
          /// Start meeting tip view title
          public static let title = Strings.tr("Localizable", "meetings.scheduleMeeting.startMeetingTip.title", fallback: "Start meeting")
        }
        public enum TipView {
          /// Scheduled meeting tip view dismiss action button title
          public static let gotIt = Strings.tr("Localizable", "meetings.scheduleMeeting.tipView.gotIt", fallback: "Got it")
        }
        public enum UpdateSuccessfull {
          /// Schedule meeting update: Success message shown when the schedule meeeting is updated successfully.
          public static let popupMessage = Strings.tr("Localizable", "meetings.scheduleMeeting.updateSuccessfull.popupMessage", fallback: "Meeting updated")
        }
        public enum WaitingRoom {
          /// Schedule meeting waiting room setting description
          public static let description = Strings.tr("Localizable", "meetings.scheduleMeeting.waitingRoom.description", fallback: "Only users admitted by the host can join the meeting.")
        }
        public enum WaitingRoomWarningBanner {
          /// Schedule meeting waiting room warning banner learn more
          public static let learnMore = Strings.tr("Localizable", "meetings.scheduleMeeting.waitingRoomWarningBanner.learnMore", fallback: "Learn more")
          /// Schedule meeting waiting room warning banner title
          public static let title = Strings.tr("Localizable", "meetings.scheduleMeeting.waitingRoomWarningBanner.title", fallback: "Participants added by non-hosts during calls won’t be sent to the waiting room.")
        }
      }
      public enum Scheduled {
        /// One off meeting date and time description, for a daily recurring meeting without ending date - Wed, 6 Jul 2022 from 09:00 to 10:00
        public static let oneOff = Strings.tr("Localizable", "meetings.scheduled.oneOff", fallback: "[B][WeekDay], [StartDate][/B] from [B][StartTime] to [EndTime][/B]")
        public enum ButtonOverlay {
          /// Button title to join an scheduled meeting
          public static let joinMeeting = Strings.tr("Localizable", "meetings.scheduled.buttonOverlay.joinMeeting", fallback: "Join meeting")
          /// Button title to start an scheduled meeting before the start date
          public static let startMeeting = Strings.tr("Localizable", "meetings.scheduled.buttonOverlay.startMeeting", fallback: "Start meeting")
        }
        public enum CancelAlert {
          /// Title for alert cancelling an scheduled meeting
          public static func title(_ p1: Any) -> String {
            return Strings.tr("Localizable", "meetings.scheduled.cancelAlert.title", String(describing: p1), fallback: "Cancel %@?")
          }
          public enum Description {
            /// Description for alert cancelling an scheduled meeting with messages in the chat room
            public static let withMessages = Strings.tr("Localizable", "meetings.scheduled.cancelAlert.description.withMessages", fallback: "This meeting will be placed under Past meetings and all participants will be notified.")
            /// Description for alert cancelling an scheduled meeting without messages in the chat room
            public static let withoutMessages = Strings.tr("Localizable", "meetings.scheduled.cancelAlert.description.withoutMessages", fallback: "This meeting will be archived and all participants will be notified.")
          }
          public enum Occurrence {
            /// Description for alert cancelling an occurrence
            public static let description = Strings.tr("Localizable", "meetings.scheduled.cancelAlert.occurrence.description", fallback: "Only this occurrence will be cancelled. All the other occurrences will go ahead as scheduled.")
            /// Success message when cancelling an occurrence
            public static func success(_ p1: Any) -> String {
              return Strings.tr("Localizable", "meetings.scheduled.cancelAlert.occurrence.success", String(describing: p1), fallback: "%@ occurrence cancelled")
            }
            /// Title for alert cancelling an occurrence
            public static func title(_ p1: Any) -> String {
              return Strings.tr("Localizable", "meetings.scheduled.cancelAlert.occurrence.title", String(describing: p1), fallback: "Cancel %@ occurrence?")
            }
            public enum Last {
              /// Title for alert cancelling last occurrence
              public static let title = Strings.tr("Localizable", "meetings.scheduled.cancelAlert.occurrence.last.title", fallback: "Cancel occurrence and meeting?")
              public enum WithMessages {
                /// Description for alert cancelling last occurrence with messages in chat room
                public static let description = Strings.tr("Localizable", "meetings.scheduled.cancelAlert.occurrence.last.withMessages.description", fallback: "This is the only occurrence of the recurring meeting. Cancelling this occurrence will cancel the meeting. If cancelled, the meeting will be placed under Past meetings and all participants will be notified.")
              }
              public enum WithoutMessages {
                /// Description for alert cancelling last occurrence without messages in chat room
                public static let description = Strings.tr("Localizable", "meetings.scheduled.cancelAlert.occurrence.last.withoutMessages.description", fallback: "This is the only occurrence of the recurring meeting. Cancelling this occurrence will cancel the meeting. If cancelled, the meeting will be archived and all participants will be notified.")
              }
            }
            public enum Option {
              /// Confirm cancel option for alert cancelling an occurrence
              public static let confirm = Strings.tr("Localizable", "meetings.scheduled.cancelAlert.occurrence.option.confirm", fallback: "Cancel occurrence")
            }
          }
          public enum Option {
            /// Don't cancel option for alert cancelling an scheduled meeting
            public static let dontCancel = Strings.tr("Localizable", "meetings.scheduled.cancelAlert.option.dontCancel", fallback: "Don’t cancel")
            public enum Confirm {
              /// Confirm cancel option for alert cancelling an scheduled meeting with messages in chat room
              public static let withMessages = Strings.tr("Localizable", "meetings.scheduled.cancelAlert.option.confirm.withMessages", fallback: "Cancel meeting")
              /// Confirm cancel option for alert cancelling an scheduled meeting without messages in chat room
              public static let withoutMessages = Strings.tr("Localizable", "meetings.scheduled.cancelAlert.option.confirm.withoutMessages", fallback: "Cancel and archive")
            }
          }
          public enum Success {
            /// Success message when cancelling an scheduled meeting with messages in chat room
            public static let withMessages = Strings.tr("Localizable", "meetings.scheduled.cancelAlert.success.withMessages", fallback: "Meeting cancelled")
            /// Success message when cancelling an scheduled meeting without messages in chat room
            public static let withoutMessages = Strings.tr("Localizable", "meetings.scheduled.cancelAlert.success.withoutMessages", fallback: "Meeting cancelled and archived")
          }
        }
        public enum ContextMenu {
          /// Button title to cancel an scheduled meeting from context menu
          public static let cancel = Strings.tr("Localizable", "meetings.scheduled.contextMenu.cancel", fallback: "Cancel")
          /// Button title to join an scheduled meeting from context menu
          public static let joinMeeting = Strings.tr("Localizable", "meetings.scheduled.contextMenu.joinMeeting", fallback: "Join")
          /// Button title to show list of occurrences of an scheduled meeting from context menu
          public static let occurrences = Strings.tr("Localizable", "meetings.scheduled.contextMenu.occurrences", fallback: "Occurrences")
          /// Button title to start an scheduled meeting before the start date from context menu
          public static let startMeeting = Strings.tr("Localizable", "meetings.scheduled.contextMenu.startMeeting", fallback: "Start")
        }
        public enum Create {
          public enum Daily {
            /// Plural format key: "%#@count@"
            public static func footerNote(_ p1: Int) -> String {
              return Strings.tr("Localizable", "meetings.scheduled.create.daily.footerNote", p1, fallback: "Plural format key: \"%#@count@\"")
            }
            /// Plural format key: "%#@day@"
            public static func interval(_ p1: Int) -> String {
              return Strings.tr("Localizable", "meetings.scheduled.create.daily.interval", p1, fallback: "Plural format key: \"%#@day@\"")
            }
          }
          public enum Monthly {
            /// Plural format key: "%#@month@"
            public static func interval(_ p1: Int) -> String {
              return Strings.tr("Localizable", "meetings.scheduled.create.monthly.interval", p1, fallback: "Plural format key: \"%#@month@\"")
            }
            public enum MultipleDays {
              /// Plural format key: "%#@count@"
              public static func footerNote(_ p1: Int) -> String {
                return Strings.tr("Localizable", "meetings.scheduled.create.monthly.multipleDays.footerNote", p1, fallback: "Plural format key: \"%#@count@\"")
              }
            }
            public enum MultipleDaysCardinal {
              /// Plural format key: "%#@count@"
              public static func footerNote(_ p1: Int) -> String {
                return Strings.tr("Localizable", "meetings.scheduled.create.monthly.multipleDaysCardinal.footerNote", p1, fallback: "Plural format key: \"%#@count@\"")
              }
            }
            public enum SingleDay {
              /// Plural format key: "%#@count@"
              public static func footerNote(_ p1: Int) -> String {
                return Strings.tr("Localizable", "meetings.scheduled.create.monthly.singleDay.footerNote", p1, fallback: "Plural format key: \"%#@count@\"")
              }
            }
            public enum SingleDayCardinal {
              /// Plural format key: "%#@count@"
              public static func footerNote(_ p1: Int) -> String {
                return Strings.tr("Localizable", "meetings.scheduled.create.monthly.singleDayCardinal.footerNote", p1, fallback: "Plural format key: \"%#@count@\"")
              }
            }
            public enum WeekDay {
              /// Plural format key: "%#@count@"
              public static func selectedFrequency(_ p1: Int) -> String {
                return Strings.tr("Localizable", "meetings.scheduled.create.monthly.weekDay.selectedFrequency", p1, fallback: "Plural format key: \"%#@count@\"")
              }
            }
            public enum WeekDayCardinal {
              /// Plural format key: "%#@count@"
              public static func selectedFrequency(_ p1: Int) -> String {
                return Strings.tr("Localizable", "meetings.scheduled.create.monthly.weekDayCardinal.selectedFrequency", p1, fallback: "Plural format key: \"%#@count@\"")
              }
            }
            public enum WeekNumberAndWeekDay {
              /// Plural format key: "%#@count@"
              public static func footerNote(_ p1: Int) -> String {
                return Strings.tr("Localizable", "meetings.scheduled.create.monthly.weekNumberAndWeekDay.footerNote", p1, fallback: "Plural format key: \"%#@count@\"")
              }
              /// Plural format key: "%#@count@"
              public static func selectedFrequency(_ p1: Int) -> String {
                return Strings.tr("Localizable", "meetings.scheduled.create.monthly.weekNumberAndWeekDay.selectedFrequency", p1, fallback: "Plural format key: \"%#@count@\"")
              }
            }
          }
          public enum Weekly {
            /// Plural format key: "%#@week@"
            public static func interval(_ p1: Int) -> String {
              return Strings.tr("Localizable", "meetings.scheduled.create.weekly.interval", p1, fallback: "Plural format key: \"%#@week@\"")
            }
            /// Plural format key: "%#@count@"
            public static func selectedFrequency(_ p1: Int) -> String {
              return Strings.tr("Localizable", "meetings.scheduled.create.weekly.selectedFrequency", p1, fallback: "Plural format key: \"%#@count@\"")
            }
            public enum EveryDay {
              /// Create Schedule Meeting: Schedule meeting repeats all days in a week. This text is shown in the custom option selection screen
              public static let footerNote = Strings.tr("Localizable", "meetings.scheduled.create.weekly.everyDay.footerNote", fallback: "Meeting will occur every day.")
            }
            public enum MultipleDays {
              /// Plural format key: "%#@count@"
              public static func footerNote(_ p1: Int) -> String {
                return Strings.tr("Localizable", "meetings.scheduled.create.weekly.multipleDays.footerNote", p1, fallback: "Plural format key: \"%#@count@\"")
              }
            }
            public enum SingleDay {
              /// Plural format key: "%#@count@"
              public static func footerNote(_ p1: Int) -> String {
                return Strings.tr("Localizable", "meetings.scheduled.create.weekly.singleDay.footerNote", p1, fallback: "Plural format key: \"%#@count@\"")
              }
            }
          }
        }
        public enum EditMeeting {
          /// Edit Schedule meeting navigaion title.
          public static let title = Strings.tr("Localizable", "meetings.scheduled.editMeeting.title", fallback: "Edit meeting")
        }
        public enum Listing {
          public enum InProgress {
            /// Description shown when a meeting is in progress. This text appears in the chat listing screeen.
            public static let description = Strings.tr("Localizable", "meetings.scheduled.listing.inProgress.description", fallback: "Meeting in progress")
            /// Description shown when a meeting is in progress. Description includes time. This text appears in the chat listing screeen.
            public static func descriptionWithDuration(_ p1: Any) -> String {
              return Strings.tr("Localizable", "meetings.scheduled.listing.inProgress.descriptionWithDuration", String(describing: p1), fallback: "Meeting in progress · %@")
            }
          }
        }
        public enum ManagementMessages {
          /// A log message in the chat conversation to tell the reader that a participant [A] cancelled the meeting. For example: Zadie Smith cancelled this meeting
          public static func cancelled(_ p1: Any) -> String {
            return Strings.tr("Localizable", "meetings.scheduled.managementMessages.cancelled", String(describing: p1), fallback: "%@ cancelled this meeting")
          }
          /// A log message in the chat conversation to tell the reader that a participant [A] created the meeting. For example: Zadie Smith created this meeting
          public static func created(_ p1: Any) -> String {
            return Strings.tr("Localizable", "meetings.scheduled.managementMessages.created", String(describing: p1), fallback: "%@ created this meeting")
          }
          /// Schedule meeting management message: Description in the chatroom whenever there is an update in the scheduled meeting.
          public static func updated(_ p1: Any) -> String {
            return Strings.tr("Localizable", "meetings.scheduled.managementMessages.updated", String(describing: p1), fallback: "%@ updated the meeting")
          }
          public enum Cancelled {
            /// A log message in the chat conversation to tell the reader that a participant [A] cancelled one ocurrence. For example: Zadie Smith cancelled the occurrence scheduled for Fri 22 April from 10:00 to 11:00
            public static func occurrence(_ p1: Any, _ p2: Any) -> String {
              return Strings.tr("Localizable", "meetings.scheduled.managementMessages.cancelled.occurrence", String(describing: p1), String(describing: p2), fallback: "%@ cancelled the occurrence scheduled for %@")
            }
            /// A log message in the chat conversation to tell the reader that a participant [A] cancelled a meeting. For example: Zadie Smith cancelled this meeting
            public static func oneOffMeeting(_ p1: Any) -> String {
              return Strings.tr("Localizable", "meetings.scheduled.managementMessages.cancelled.oneOffMeeting", String(describing: p1), fallback: "%@ cancelled this meeting")
            }
            /// A log message in the chat conversation to tell the reader that a participant [A] cancelled a meeting with recurrence. For example: Zadie Smith cancelled this meeting and all its occurrences
            public static func recurrenceMeeting(_ p1: Any) -> String {
              return Strings.tr("Localizable", "meetings.scheduled.managementMessages.cancelled.recurrenceMeeting", String(describing: p1), fallback: "%@ cancelled this meeting and all its occurrences")
            }
          }
        }
        public enum Recurring {
          /// Text description for a meeting showing that is a daily recurring meeting
          public static let daily = Strings.tr("Localizable", "meetings.scheduled.recurring.daily", fallback: "daily")
          /// Text description for a meeting showing that is a monthly recurring meeting
          public static let monthly = Strings.tr("Localizable", "meetings.scheduled.recurring.monthly", fallback: "monthly")
          /// Text description for a meeting showing that is a weekly recurring meeting
          public static let weekly = Strings.tr("Localizable", "meetings.scheduled.recurring.weekly", fallback: "weekly")
          public enum Daily {
            /// Plural format key: "%#@interval@"
            public static func forever(_ p1: Int) -> String {
              return Strings.tr("Localizable", "meetings.scheduled.recurring.daily.forever", p1, fallback: "Plural format key: \"%#@interval@\"")
            }
            /// Plural format key: "%#@interval@"
            public static func until(_ p1: Int) -> String {
              return Strings.tr("Localizable", "meetings.scheduled.recurring.daily.until", p1, fallback: "Plural format key: \"%#@interval@\"")
            }
          }
          public enum Frequency {
            /// Label to indicate the daily recurrence of an scheduled meeting
            public static let daily = Strings.tr("Localizable", "meetings.scheduled.recurring.frequency.daily", fallback: "Occurs daily")
            /// Label to indicate the monthly recurrence of an scheduled meeting
            public static let monthly = Strings.tr("Localizable", "meetings.scheduled.recurring.frequency.monthly", fallback: "Occurs monthly")
            /// Label to indicate the weekly recurrence of an scheduled meeting
            public static let weekly = Strings.tr("Localizable", "meetings.scheduled.recurring.frequency.weekly", fallback: "Occurs weekly")
          }
          public enum Monthly {
            public enum OrdinalDay {
              public enum Forever {
                public enum Friday {
                  /// Plural format key: "%#@interval@"
                  public static func fifth(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.friday.fifth", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func first(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.friday.first", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func fourth(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.friday.fourth", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func second(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.friday.second", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func third(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.friday.third", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                }
                public enum Monday {
                  /// Plural format key: "%#@interval@"
                  public static func fifth(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.monday.fifth", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func first(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.monday.first", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func fourth(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.monday.fourth", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func second(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.monday.second", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func third(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.monday.third", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                }
                public enum Saturday {
                  /// Plural format key: "%#@interval@"
                  public static func fifth(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.saturday.fifth", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func first(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.saturday.first", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func fourth(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.saturday.fourth", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func second(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.saturday.second", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func third(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.saturday.third", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                }
                public enum Sunday {
                  /// Plural format key: "%#@interval@"
                  public static func fifth(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.sunday.fifth", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func first(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.sunday.first", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func fourth(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.sunday.fourth", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func second(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.sunday.second", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func third(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.sunday.third", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                }
                public enum Thursday {
                  /// Plural format key: "%#@interval@"
                  public static func fifth(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.thursday.fifth", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func first(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.thursday.first", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func fourth(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.thursday.fourth", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func second(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.thursday.second", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func third(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.thursday.third", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                }
                public enum Tuesday {
                  /// Plural format key: "%#@interval@"
                  public static func fifth(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.fifth", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func first(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.first", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func fourth(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.fourth", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func second(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.second", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func third(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.third", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                }
                public enum Wednesday {
                  /// Plural format key: "%#@interval@"
                  public static func fifth(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.wednesday.fifth", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func first(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.wednesday.first", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func fourth(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.wednesday.fourth", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func second(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.wednesday.second", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func third(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.forever.wednesday.third", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                }
              }
              public enum Until {
                public enum Friday {
                  /// Plural format key: "%#@interval@"
                  public static func fifth(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.friday.fifth", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func first(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.friday.first", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func fourth(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.friday.fourth", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func second(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.friday.second", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func third(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.friday.third", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                }
                public enum Monday {
                  /// Plural format key: "%#@interval@"
                  public static func fifth(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.monday.fifth", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func first(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.monday.first", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func fourth(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.monday.fourth", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func second(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.monday.second", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func third(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.monday.third", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                }
                public enum Saturday {
                  /// Plural format key: "%#@interval@"
                  public static func fifth(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.saturday.fifth", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func first(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.saturday.first", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func fourth(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.saturday.fourth", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func second(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.saturday.second", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func third(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.saturday.third", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                }
                public enum Sunday {
                  /// Plural format key: "%#@interval@"
                  public static func fifth(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.sunday.fifth", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func first(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.sunday.first", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func fourth(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.sunday.fourth", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func second(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.sunday.second", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func third(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.sunday.third", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                }
                public enum Thursday {
                  /// Plural format key: "%#@interval@"
                  public static func fifth(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.thursday.fifth", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func first(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.thursday.first", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func fourth(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.thursday.fourth", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func second(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.thursday.second", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func third(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.thursday.third", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                }
                public enum Tuesday {
                  /// Plural format key: "%#@interval@"
                  public static func fifth(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.fifth", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func first(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.first", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func fourth(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.fourth", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func second(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.second", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func third(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.third", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                }
                public enum Wednesday {
                  /// Plural format key: "%#@interval@"
                  public static func fifth(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.wednesday.fifth", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func first(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.wednesday.first", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func fourth(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.wednesday.fourth", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func second(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.wednesday.second", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                  /// Plural format key: "%#@interval@"
                  public static func third(_ p1: Int) -> String {
                    return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.ordinalDay.until.wednesday.third", p1, fallback: "Plural format key: \"%#@interval@\"")
                  }
                }
              }
            }
            public enum SingleDay {
              /// Plural format key: "%#@interval@"
              public static func forever(_ p1: Int) -> String {
                return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.singleDay.forever", p1, fallback: "Plural format key: \"%#@interval@\"")
              }
              /// Plural format key: "%#@interval@"
              public static func until(_ p1: Int) -> String {
                return Strings.tr("Localizable", "meetings.scheduled.recurring.monthly.singleDay.until", p1, fallback: "Plural format key: \"%#@interval@\"")
              }
            }
          }
          public enum Occurrences {
            public enum List {
              /// Button label to indicate that more occurencies can be loaded in the list
              public static let seeMoreOccurrences = Strings.tr("Localizable", "meetings.scheduled.recurring.occurrences.list.seeMoreOccurrences", fallback: "See more")
            }
          }
          public enum Weekly {
            public enum OneDay {
              /// Plural format key: "%#@interval@"
              public static func forever(_ p1: Int) -> String {
                return Strings.tr("Localizable", "meetings.scheduled.recurring.weekly.oneDay.forever", p1, fallback: "Plural format key: \"%#@interval@\"")
              }
              /// Plural format key: "%#@interval@"
              public static func until(_ p1: Int) -> String {
                return Strings.tr("Localizable", "meetings.scheduled.recurring.weekly.oneDay.until", p1, fallback: "Plural format key: \"%#@interval@\"")
              }
            }
            public enum SeveralDays {
              /// Plural format key: "%#@interval@"
              public static func forever(_ p1: Int) -> String {
                return Strings.tr("Localizable", "meetings.scheduled.recurring.weekly.severalDays.forever", p1, fallback: "Plural format key: \"%#@interval@\"")
              }
              /// Plural format key: "%#@interval@"
              public static func until(_ p1: Int) -> String {
                return Strings.tr("Localizable", "meetings.scheduled.recurring.weekly.severalDays.until", p1, fallback: "Plural format key: \"%#@interval@\"")
              }
            }
          }
        }
      }
      public enum Sharelink {
        /// Message shown when the meeting link cannot be generated
        public static let error = Strings.tr("Localizable", "meetings.sharelink.Error", fallback: "Meeting link could not be generated. Please try again.")
      }
      public enum StartConversation {
        public enum ContextMenu {
          /// Meeting - start conversation context menu text for joining a meeting
          public static let joinMeeting = Strings.tr("Localizable", "meetings.startConversation.contextMenu.joinMeeting", fallback: "Join meeting")
          /// Start conversation: Schedule meeting context menu
          public static let scheduleMeeting = Strings.tr("Localizable", "meetings.startConversation.contextMenu.scheduleMeeting", fallback: "Schedule meeting")
          /// Meeting - start converstion context menu text for starting a meeting
          public static let startMeeting = Strings.tr("Localizable", "meetings.startConversation.contextMenu.startMeeting", fallback: "Start meeting now")
        }
      }
      public enum WaitingRoom {
        /// Meeting waiting room leave button
        public static let leave = Strings.tr("Localizable", "meetings.waitingRoom.leave", fallback: "Leave")
        public enum Alert {
          /// Meeting waiting room don't leave button
          public static let dontLeave = Strings.tr("Localizable", "meetings.waitingRoom.alert.dontLeave", fallback: "Don’t leave")
          /// Meeting waiting room alert title of Host didn’t let you in
          public static let hostDidNotLetYouIn = Strings.tr("Localizable", "meetings.waitingRoom.alert.hostDidNotLetYouIn", fallback: "Host didn’t let you in")
          /// Meeting waiting room leave alert message
          public static let leaveMeeting = Strings.tr("Localizable", "meetings.waitingRoom.alert.leaveMeeting", fallback: "Leave meeting?")
          /// Meeting waiting room alert action of ok got it
          public static let okGotIt = Strings.tr("Localizable", "meetings.waitingRoom.alert.okGotIt", fallback: "OK, got it")
          /// Meeting waiting room alert message of You'll be removed from the waiting room
          public static let youWillBeRemovedFromTheWaitingRoom = Strings.tr("Localizable", "meetings.waitingRoom.alert.youWillBeRemovedFromTheWaitingRoom", fallback: "You’ll be removed from the waiting room")
        }
        public enum Guest {
          /// Meeting waiting room guest join first name textfield
          public static let firstName = Strings.tr("Localizable", "meetings.waitingRoom.guest.firstName", fallback: "First name")
          /// Meeting waiting room guest join button
          public static let join = Strings.tr("Localizable", "meetings.waitingRoom.guest.join", fallback: "Join")
          /// Meeting waiting room guest join last name textfield
          public static let lastName = Strings.tr("Localizable", "meetings.waitingRoom.guest.lastName", fallback: "Last name")
        }
        public enum Message {
          /// Meeting waiting room message of wait for host to let you in
          public static let waitForHostToLetYouIn = Strings.tr("Localizable", "meetings.waitingRoom.message.waitForHostToLetYouIn", fallback: "Wait for host to let you in")
          /// Meeting waiting room message of wait for host to start the meeting
          public static let waitForHostToStartTheMeeting = Strings.tr("Localizable", "meetings.waitingRoom.message.waitForHostToStartTheMeeting", fallback: "Wait for host to start the meeting")
        }
      }
    }
    public enum Mybackups {
      public enum Share {
        public enum Folder {
          public enum Warning {
            /// Plural format key: "%#@share@"
            public static func message(_ p1: Int) -> String {
              return Strings.tr("Localizable", "mybackups.share.folder.warning.message", p1, fallback: "Plural format key: \"%#@share@\"")
            }
          }
        }
      }
    }
    public enum NameCollision {
      /// Plural format key: "%#@count@"
      public static func applyToAll(_ p1: Int) -> String {
        return Strings.tr("Localizable", "nameCollision.applyToAll", p1, fallback: "Plural format key: \"%#@count@\"")
      }
      public enum Files {
        /// Text to indicate the user that the file trying to upload/copy/move already exists in destination
        public static func alreadyExists(_ p1: Any) -> String {
          return Strings.tr("Localizable", "nameCollision.files.alreadyExists", String(describing: p1), fallback: "A file named %@ already exists at this destination.")
        }
        public enum Action {
          public enum Rename {
            /// Text description for the rename action when upload/copy/move and already exists in destination
            public static let description = Strings.tr("Localizable", "nameCollision.files.action.rename.description", fallback: "The file will be renamed as:")
            /// Text of the rename action when trying to upload/copy/move a file and already exists in destination
            public static let title = Strings.tr("Localizable", "nameCollision.files.action.rename.title", fallback: "Rename")
          }
          public enum Replace {
            /// Text description for the replace action when upload/copy/move and already exists in destination
            public static let description = Strings.tr("Localizable", "nameCollision.files.action.replace.description", fallback: "The file at this destination will be replaced with the new file.")
            /// Text of the replace action trying to upload/copy/move a file and already exists in destination
            public static let title = Strings.tr("Localizable", "nameCollision.files.action.replace.title", fallback: "Replace")
          }
          public enum Skip {
            /// Text of the skip action when trying to upload/copy/move a file and already exists in destination
            public static let title = Strings.tr("Localizable", "nameCollision.files.action.skip.title", fallback: "Skip this file")
          }
          public enum Update {
            /// Text description for the update action when upload and already exists in destination
            public static let description = Strings.tr("Localizable", "nameCollision.files.action.update.description", fallback: "The file will be updated with a new version.")
            /// Text of the update action when trying to upload a file and already exists in destination
            public static let title = Strings.tr("Localizable", "nameCollision.files.action.update.title", fallback: "Update")
          }
        }
      }
      public enum Folders {
        /// Text to indicate the user that the folder trying to upload/copy/move already exists in destination
        public static func alreadyExists(_ p1: Any) -> String {
          return Strings.tr("Localizable", "nameCollision.folders.alreadyExists", String(describing: p1), fallback: "A folder named %@ already exists at this destination.")
        }
        public enum Action {
          public enum Merge {
            /// Text description for the merge action when upload/copy/move and already exists in destination
            public static let description = Strings.tr("Localizable", "nameCollision.folders.action.merge.description", fallback: "The new folder will be merged with the folder at this destination.")
            /// Text of the merge action when trying to upload/copy/move a folder and already exists in destination
            public static let title = Strings.tr("Localizable", "nameCollision.folders.action.merge.title", fallback: "Merge")
          }
          public enum Skip {
            /// Text of the skip action when trying to upload/copy/move a folder and already exists in destination
            public static let title = Strings.tr("Localizable", "nameCollision.folders.action.skip.title", fallback: "Skip this folder")
          }
        }
      }
      public enum Title {
        /// Text to indicate the user that file already exists when uploading/copying/moving
        public static let file = Strings.tr("Localizable", "nameCollision.title.file", fallback: "File already exists")
        /// Text to indicate the user that folder already exists when uploading/copying/moving
        public static let folder = Strings.tr("Localizable", "nameCollision.title.folder", fallback: "Folder already exists")
      }
    }
    public enum Notifications {
      public enum Message {
        public enum TakenDownPubliclyShared {
          /// The text of a notification indicating that a file has been taken down due to infringement or other reason. The %@ will be replaced with the name of the file.
          public static func file(_ p1: Any) -> String {
            return Strings.tr("Localizable", "notifications.message.takenDownPubliclyShared.file", String(describing: p1), fallback: "Your publicly shared file “%@” has been taken down")
          }
          /// The text of a notification indicating that a folder has been taken down due to infringement or other reason. The %@ will be replaced with the name of the folder.
          public static func folder(_ p1: Any) -> String {
            return Strings.tr("Localizable", "notifications.message.takenDownPubliclyShared.folder", String(describing: p1), fallback: "Your publicly shared folder “%@” has been taken down")
          }
        }
        public enum TakenDownReinstated {
          /// The text of a notification indicating that a file that was taken down has now been restored due to a successful counter-notice.The %@ will be replaced with the name of the file.
          public static func file(_ p1: Any) -> String {
            return Strings.tr("Localizable", "notifications.message.takenDownReinstated.file", String(describing: p1), fallback: "Your taken-down file “%@” has been reinstated")
          }
          /// The text of a notification indicating that a folder that was taken down has now been restored due to a successful counter-notice.The %@ will be replaced with the name of the folder.
          public static func folder(_ p1: Any) -> String {
            return Strings.tr("Localizable", "notifications.message.takenDownReinstated.folder", String(describing: p1), fallback: "Your taken-down folder “%@” has been reinstated")
          }
        }
      }
    }
    public enum Offline {
      public enum LogOut {
        public enum Warning {
          /// Offline log out warning message
          public static let message = Strings.tr("Localizable", "offline.logOut.warning.message", fallback: "Logging out deletes your offline content.")
        }
      }
    }
    public enum Photo {
      public enum Empty {
        /// Photo view is empty
        public static let title = Strings.tr("Localizable", "photo.empty.title", fallback: "No photos found")
      }
      public enum Navigation {
        /// Navigation title for Photo Controller
        public static let title = Strings.tr("Localizable", "photo.navigation.title", fallback: "Photos")
      }
    }
    public enum Picker {
      public enum Disable {
        public enum Passcode {
          /// Description shown in Files app when users open MEGA and passcode is enabled. Files app can't be used with passcode enabled, it shows the users how to disable the passcode
          public static let description = Strings.tr("Localizable", "picker.disable.passcode.description", fallback: "To use MEGA in the Files app, disable your MEGA passcode. Go to Settings in the MEGA app, tap Security > Passcode.")
          /// Title shown in Files app when users open MEGA and passcode is enabled. Files app can't be used with passcode enabled
          public static let title = Strings.tr("Localizable", "picker.disable.passcode.title", fallback: "Disable MEGA passcode")
        }
      }
    }
    public enum Recents {
      public enum EmptyState {
        public enum ActivityHidden {
          /// Title of the button show in Recents on the empty state when the recent activity is hidden
          public static let button = Strings.tr("Localizable", "recents.emptyState.activityHidden.button", fallback: "Show activity")
          /// Title show in Recents on the empty state when the recent activity is hidden
          public static let title = Strings.tr("Localizable", "recents.emptyState.activityHidden.title", fallback: "Recent activity hidden")
        }
      }
      public enum Section {
        public enum MultipleFile {
          /// Plural format key: "%#@file@"
          public static func title(_ p1: Int) -> String {
            return Strings.tr("Localizable", "recents.section.multipleFile.title", p1, fallback: "Plural format key: \"%#@file@\"")
          }
        }
        public enum Thumbnail {
          public enum Count {
            /// Plural format key: "%#@image@"
            public static func image(_ p1: Int) -> String {
              return Strings.tr("Localizable", "recents.section.thumbnail.count.image", p1, fallback: "Plural format key: \"%#@image@\"")
            }
            /// Plural format key: "%#@video@"
            public static func video(_ p1: Int) -> String {
              return Strings.tr("Localizable", "recents.section.thumbnail.count.video", p1, fallback: "Plural format key: \"%#@video@\"")
            }
            public enum ImageAndVideo {
              /// Plural format key: "%#@image@"
              public static func image(_ p1: Int) -> String {
                return Strings.tr("Localizable", "recents.section.thumbnail.count.imageAndVideo.image", p1, fallback: "Plural format key: \"%#@image@\"")
              }
              /// Plural format key: "%#@video@"
              public static func video(_ p1: Int) -> String {
                return Strings.tr("Localizable", "recents.section.thumbnail.count.imageAndVideo.video", p1, fallback: "Plural format key: \"%#@video@\"")
              }
            }
          }
        }
        public enum Title {
          /// Plural format key: "%#@items@"
          public static func items(_ p1: Int) -> String {
            return Strings.tr("Localizable", "recents.section.title.items", p1, fallback: "Plural format key: \"%#@items@\"")
          }
        }
      }
    }
    public enum Rename {
      /// Rename file no extension warning text
      public static func fileWithoutExtension(_ p1: Any) -> String {
        return Strings.tr("Localizable", "rename.fileWithoutExtension", String(describing: p1), fallback: "File without extension .%@")
      }
      public enum ConfirmationAlert {
        /// Rename file confirmation alert description to ask if user is sure to change the file extension.
        public static let description = Strings.tr("Localizable", "rename.confirmationAlert.description", fallback: "You might not be able to open this file if you change its extension.")
        /// Rename file confirmation confirm button title
        public static let ok = Strings.tr("Localizable", "rename.confirmationAlert.ok", fallback: "Change anyway")
        /// Rename file confirmation alert title to ask if user is sure to change the file extension.
        public static let title = Strings.tr("Localizable", "rename.confirmationAlert.title", fallback: "File extension change")
      }
    }
    public enum Settings {
      public enum About {
        public enum Sfu {
          public enum ChangeAlert {
            /// Change SFU server alert cancel button.
            public static let cancelButton = Strings.tr("Localizable", "settings.about.sfu.changeAlert.cancelButton", fallback: "Cancel")
            /// Change SFU server alert change button.
            public static let changeButton = Strings.tr("Localizable", "settings.about.sfu.changeAlert.changeButton", fallback: "Change")
            /// Change SFU server alert message.
            public static let message = Strings.tr("Localizable", "settings.about.sfu.changeAlert.message", fallback: "Default is -1")
            /// Change SFU server alert test field placeholder.
            public static let placeholder = Strings.tr("Localizable", "settings.about.sfu.changeAlert.placeholder", fallback: "Enter SFU ID")
            /// Change SFU server alert title.
            public static let title = Strings.tr("Localizable", "settings.about.sfu.changeAlert.title", fallback: "Change SFU server")
          }
        }
      }
      public enum Accept {
        public enum Cookies {
          /// Cookie dialog footer description
          public static let footer = Strings.tr("Localizable", "settings.accept.cookies.footer", fallback: "Cookies aren’t used for ad tracking or sharing any personal information with third parties.")
        }
      }
      public enum Cookies {
        /// Cookie settings dialog text.
        public static let essential = Strings.tr("Localizable", "settings.cookies.essential", fallback: "Essential Cookies")
        /// Cookie settings dialog text.
        public static let performanceAndAnalytics = Strings.tr("Localizable", "settings.cookies.performanceAndAnalytics", fallback: "Performance and analytics Cookies")
        public enum Essential {
          /// Text shown next to Essential Cookies in Cookie Settings. This setting can not be disabled, that is why is 'Always on'
          public static let alwaysOn = Strings.tr("Localizable", "settings.cookies.essential.alwaysOn", fallback: "Always On")
          /// Cookie settings dialog text.
          public static let footer = Strings.tr("Localizable", "settings.cookies.essential.footer", fallback: "Essential for providing you important functionality and secure access to our services. For this reason, they do not require consent.")
        }
        public enum PerformanceAndAnalytics {
          /// Cookie settings dialog text.
          public static let footer = Strings.tr("Localizable", "settings.cookies.performanceAndAnalytics.footer", fallback: "Help us to understand how you use our services and provide us data that we can use to make improvements. Not accepting these Cookies will mean we will have less data available to us to help design improvements.")
        }
      }
      public enum FileManagement {
        public enum Alert {
          /// Question shown after you tap on 'Settings' - 'File Management' - 'Clear Offline files' to confirm the action
          public static let clearAllOfflineFiles = Strings.tr("Localizable", "settings.fileManagement.alert.clearAllOfflineFiles", fallback: "Clear all offline files?")
        }
        public enum RubbishBin {
          /// This text is displayed in Settings, File Management in Rubbish Bien view. Upgrade to Pro will be bold and green. And if you tap it, the Upgrade Account view will appear.
          public static let longerRetentionUpgrade = Strings.tr("Localizable", "settings.fileManagement.rubbishBin.longerRetentionUpgrade", fallback: "For a longer retention period [S]Upgrade to Pro[/S]")
          public enum CleanScheduler {
            public enum Placeholder {
              /// Textfield placeholder for rubbish bin Cleaning Scheduler in days alert
              public static let days = Strings.tr("Localizable", "settings.fileManagement.rubbishBin.cleanScheduler.placeholder.days", fallback: "days")
            }
          }
        }
        public enum UseMobileData {
          /// Footer explaning how Use Mobile Data setting to load preview of images in hight resolution works
          public static let footer = Strings.tr("Localizable", "settings.fileManagement.useMobileData.footer", fallback: "Use mobile data to load high resolution images when previewing. If disabled, the high resolution image will only be loaded when you zoom in.")
          /// Header of a Use Mobile Data setting to load preview of images in hight resolution
          public static let header = Strings.tr("Localizable", "settings.fileManagement.useMobileData.header", fallback: "Preview high resolution images")
        }
      }
      public enum Section {
        /// Title of the Settings section where you can configure security details of your MEGA account
        public static let security = Strings.tr("Localizable", "settings.section.security", fallback: "Security")
        /// Title of one of the Settings sections where you can see MEGA's 'Terms and Policies'
        public static let termsAndPolicies = Strings.tr("Localizable", "settings.section.termsAndPolicies", fallback: "Terms and Policies")
        /// Title of one of the Settings sections where you can customise the 'User Interface' of the app.
        public static let userInterface = Strings.tr("Localizable", "settings.section.userInterface", fallback: "User interface")
        public enum Calls {
          /// Title of the Settings section where you can configure calls options of your MEGA account
          public static let title = Strings.tr("Localizable", "settings.section.calls.title", fallback: "Calls")
          public enum SoundNotifications {
            /// Description of the sound notifications choice for calls when users join or left a call
            public static let description = Strings.tr("Localizable", "settings.section.calls.soundNotifications.description", fallback: "Hear a sound when someone joins or leaves a call.")
            /// Title of the sound notifications choice for calls when users join or left a call
            public static let title = Strings.tr("Localizable", "settings.section.calls.soundNotifications.title", fallback: "Sound notifications")
          }
        }
      }
      public enum UserInterface {
        /// In Settings - User Interface, there is an option that you can enable to hide the contents of the Recents section
        public static let hideRecentActivity = Strings.tr("Localizable", "settings.userInterface.hideRecentActivity", fallback: "Hide recent activity")
        public enum HideRecentActivity {
          /// In Settings - User Interface, there is an option that you can enable to hide the contents of the Recents section. This is the footer that appears under that option.
          public static let footer = Strings.tr("Localizable", "settings.userInterface.hideRecentActivity.footer", fallback: "Hide recent activity in Home section.")
        }
      }
    }
    public enum Share {
      public enum Message {
        /// Plural format key: "%#@count@"
        public static func uploadedToCloudDrive(_ p1: Int) -> String {
          return Strings.tr("Localizable", "share.message.uploadedToCloudDrive", p1, fallback: "Plural format key: \"%#@count@\"")
        }
        /// Plural format key: "%#@count@"
        public static func uploadedToDestinationFolder(_ p1: Int) -> String {
          return Strings.tr("Localizable", "share.message.uploadedToDestinationFolder", p1, fallback: "Plural format key: \"%#@count@\"")
        }
        public enum SendToChat {
          /// Plural format key: "%#@receiverCount@"
          public static func withMultipleFiles(_ p1: Int) -> String {
            return Strings.tr("Localizable", "share.message.sendToChat.withMultipleFiles", p1, fallback: "Plural format key: \"%#@receiverCount@\"")
          }
          /// Plural format key: "%#@receiverCount@"
          public static func withOneFile(_ p1: Int) -> String {
            return Strings.tr("Localizable", "share.message.sendToChat.withOneFile", p1, fallback: "Plural format key: \"%#@receiverCount@\"")
          }
        }
      }
    }
    public enum ShareFolder {
      /// Text displayed on banner we show when sharing folder with unverified contacts
      public static let contactsNotVerified = Strings.tr("Localizable", "shareFolder.contactsNotVerified", fallback: "Some of the contacts you’re sharing information with haven’t been approved by you. To ensure extra security, we recommend that you approve their credentials in Contacts by tapping on ⓘ next to the contact you want to approve.")
    }
    public enum SharedItems {
      public enum ContactVerification {
        /// On Cloud Drive screen for incoming shared folder, if the contact which shared the folder is not verified, this is the message that wwe display
        public static func contactNotVerifiedBannerMessage(_ p1: Any) -> String {
          return Strings.tr("Localizable", "sharedItems.contactVerification.contactNotVerifiedBannerMessage", String(describing: p1), fallback: "%@ is shared by a contact you haven’t approved. To ensure extra security, we recommend that you approve their credentials in Contacts by tapping on ⓘ next to the contact you want to approve.")
        }
        public enum Section {
          public enum MyCredentials {
            /// On fingerprint verification screen for Shared Items. Header message located at the top of "My credentials" section
            public static let message = Strings.tr("Localizable", "sharedItems.contactVerification.section.myCredentials.message", fallback: "To approve your contact, ensure the credentials you see above match their account credentials. You can ask them to share their credentials with you.")
          }
          public enum VerifyContact {
            /// On fingerprint verification screen for Incoming Shared Items. Yellow banner message that will be shown to the receiver if the owner of the folder haven't verified them yet.
            public static let bannerMessage = Strings.tr("Localizable", "sharedItems.contactVerification.section.verifyContact.bannerMessage", fallback: "To access the shared folder, the person who shared it with you should approve you, too.")
            public enum Owner {
              /// On fingerprint verification screen for Shared Items. Header message located at the top of contact's name and email address that needs to be verified
              public static let message = Strings.tr("Localizable", "sharedItems.contactVerification.section.verifyContact.owner.message", fallback: "We protect your data with zero-knowledge encryption. To ensure extra security, we ask you to approve the contacts you share information with before they can access the shared folders.")
            }
            public enum Receiver {
              /// On fingerprint verification screen for Shared Items. Header message located at the top of contact's name and email address if the owner of the received shared item is unverified
              public static let message = Strings.tr("Localizable", "sharedItems.contactVerification.section.verifyContact.receiver.message", fallback: "We protect your data with zero-knowledge encryption. To ensure extra security, we ask you to approve the contacts you receive information from before you can access the shared folders.")
            }
          }
        }
      }
      public enum GetLink {
        /// Plural format key: "%#@count@"
        public static func linkCopied(_ p1: Int) -> String {
          return Strings.tr("Localizable", "sharedItems.getLink.linkCopied", p1, fallback: "Plural format key: \"%#@count@\"")
        }
        /// Plural format key: "%#@count@"
        public static func linkCreatedAndCopied(_ p1: Int) -> String {
          return Strings.tr("Localizable", "sharedItems.getLink.linkCreatedAndCopied", p1, fallback: "Plural format key: \"%#@count@\"")
        }
      }
      public enum Link {
        /// Plural format key: "%#@count@"
        public static func accessInfo(_ p1: Int) -> String {
          return Strings.tr("Localizable", "sharedItems.link.accessInfo", p1, fallback: "Plural format key: \"%#@count@\"")
        }
        /// This is a description of a row on Get Link dialog which explains who will be able to access the link if the password is added to link
        public static let accessInfoPasswordProtected = Strings.tr("Localizable", "sharedItems.link.accessInfoPasswordProtected", fallback: "Only people with the password can open the link")
        /// This is a text of a banner which will be displayed user does an action which updates the shared link
        public static let linkUpdated = Strings.tr("Localizable", "sharedItems.link.linkUpdated", fallback: "Link updated. Copy again.")
      }
      public enum Menu {
        public enum Slideshow {
          /// Slideshow Menu Option
          public static let title = Strings.tr("Localizable", "sharedItems.menu.slideshow.title", fallback: "Slideshow")
        }
      }
      public enum Rubbish {
        public enum Confirmation {
          /// Plural format key: "%#@count@"
          public static func fileCount(_ p1: Int) -> String {
            return Strings.tr("Localizable", "sharedItems.rubbish.confirmation.fileCount", p1, fallback: "Plural format key: \"%#@count@\"")
          }
          /// Plural format key: "%#@count@"
          public static func folderCount(_ p1: Int) -> String {
            return Strings.tr("Localizable", "sharedItems.rubbish.confirmation.folderCount", p1, fallback: "Plural format key: \"%#@count@\"")
          }
          /// Success message shown when [A] = {1+} files and [B] = "{1+} file{s} {and} {1+} folder{s} have been removed from MEGA"
          public static func message(_ p1: Any) -> String {
            return Strings.tr("Localizable", "sharedItems.rubbish.confirmation.message", String(describing: p1), fallback: "%@ removed from MEGA")
          }
          /// Plural format key: "%#@count@"
          public static func removedItemCount(_ p1: Int) -> String {
            return Strings.tr("Localizable", "sharedItems.rubbish.confirmation.removedItemCount", p1, fallback: "Plural format key: \"%#@count@\"")
          }
        }
        public enum Warning {
          /// Plural format key: "%#@count@"
          public static func fileCount(_ p1: Int) -> String {
            return Strings.tr("Localizable", "sharedItems.rubbish.warning.fileCount", p1, fallback: "Plural format key: \"%#@count@\"")
          }
          /// Plural format key: "%#@count@"
          public static func folderCount(_ p1: Int) -> String {
            return Strings.tr("Localizable", "sharedItems.rubbish.warning.folderCount", p1, fallback: "Plural format key: \"%#@count@\"")
          }
          /// Alert message shown on the Rubbish Bin when you want to remove "{1+} file{s} {and} {1+} folder{s}"
          public static func message(_ p1: Any) -> String {
            return Strings.tr("Localizable", "sharedItems.rubbish.warning.message", String(describing: p1), fallback: "You are about to permanently remove %@. Would you like to proceed? (You cannot undo this action.)")
          }
        }
      }
      public enum Tab {
        public enum Incoming {
          /// On Incoming Shared Items Tab. Name of the folder if the the owner and the receiver has not yet verified each other.
          public static let undecryptedFolderName = Strings.tr("Localizable", "sharedItems.tab.incoming.undecryptedFolderName", fallback: "[Undecrypted folder]")
        }
        public enum Outgoing {
          /// On Outgoing Shared Items Tab. Text that shows the receiver's name of the shared folder. %@ will be replaced with the receiver's name.
          public static func sharedToContact(_ p1: Any) -> String {
            return Strings.tr("Localizable", "sharedItems.tab.outgoing.sharedToContact", String(describing: p1), fallback: "Shared with %@")
          }
          public enum Modal {
            public enum CannotVerifyContact {
              /// On Outgoing Shared Items Tab. Message of the modal shown when trying to verify pending outshare where receiver is not in contacts yet.
              public static func message(_ p1: Any) -> String {
                return Strings.tr("Localizable", "sharedItems.tab.outgoing.modal.cannotVerifyContact.message", String(describing: p1), fallback: "You can’t approve %@ as they’re not in your contact list. Wait for them to accept your invitation first.")
              }
              /// On Outgoing Shared Items Tab. Title of the modal shown when trying to verify pending outshare where receiver is not in contacts yet.
              public static let title = Strings.tr("Localizable", "sharedItems.tab.outgoing.modal.cannotVerifyContact.title", fallback: "Cannot approve contact")
            }
          }
        }
        public enum Recents {
          /// Plural format key: "%#@count@"
          public static func undecryptedFileName(_ p1: Int) -> String {
            return Strings.tr("Localizable", "sharedItems.tab.recents.undecryptedFileName", p1, fallback: "Plural format key: \"%#@count@\"")
          }
        }
      }
    }
    public enum Slideshow {
      public enum PreferenceSetting {
        /// Footer note for media in sub folders
        public static let mediaInSubFolders = Strings.tr("Localizable", "slideshow.preferenceSetting.mediaInSubFolders", fallback: "Include images from sub-folders in the slideshow")
        /// Option button Title shown on Slideshow Preference Setting
        public static let options = Strings.tr("Localizable", "slideshow.preferenceSetting.options", fallback: "Options")
        /// NavigationBar Title shown on Slideshow Order preference
        public static let order = Strings.tr("Localizable", "slideshow.preferenceSetting.order", fallback: "Slideshow order")
        /// NavigationBar Title shown on Slideshow Preference Setting
        public static let slideshowOptions = Strings.tr("Localizable", "slideshow.preferenceSetting.slideshowOptions", fallback: "Slideshow options")
        /// NavigationBar Title shown on Slideshow Speed preference
        public static let speed = Strings.tr("Localizable", "slideshow.preferenceSetting.speed", fallback: "Slideshow speed")
        public enum Order {
          /// Slideshow Speed Order shuffle
          public static let shuffle = Strings.tr("Localizable", "slideshow.preferenceSetting.order.shuffle", fallback: "Shuffle")
        }
        public enum SlideshowOptions {
          /// Slideshow Preference Setting repeat
          public static let `repeat` = Strings.tr("Localizable", "slideshow.preferenceSetting.slideshowOptions.repeat", fallback: "Repeat")
          /// Slideshow Preference Setting include subFolders
          public static let subFolders = Strings.tr("Localizable", "slideshow.preferenceSetting.slideshowOptions.subFolders", fallback: "Include sub-folders")
        }
        public enum Speed {
          /// Slideshow Speed preference fast
          public static let fast = Strings.tr("Localizable", "slideshow.preferenceSetting.speed.fast", fallback: "Fast (2s)")
          /// Slideshow Speed preference normal
          public static let normal = Strings.tr("Localizable", "slideshow.preferenceSetting.speed.normal", fallback: "Normal (4s)")
          /// Slideshow Speed preference slow
          public static let slow = Strings.tr("Localizable", "slideshow.preferenceSetting.speed.slow", fallback: "Slow (8s)")
        }
      }
    }
    public enum Transfer {
      public enum Cell {
        public enum ShareOwnerStorageQuota {
          /// A message shown when uploading to an incoming share and the owner’s account is over its storage quota.
          public static let infoLabel = Strings.tr("Localizable", "transfer.cell.shareOwnerStorageQuota.infoLabel", fallback: "Share owner is over storage quota.")
        }
      }
      public enum Error {
        /// Error shown when downloading a file that has violated Terms of Service.
        public static let termsOfServiceViolation = Strings.tr("Localizable", "transfer.error.termsOfServiceViolation", fallback: "Violated Terms of Service")
      }
      public enum Storage {
        /// Label indicating storage over quota
        public static let quotaExceeded = Strings.tr("Localizable", "transfer.storage.quotaExceeded", fallback: "Storage quota exceeded")
      }
    }
    public enum TransferQuotaError {
      public enum Button {
        /// Button title of the dialog for transfer quota error to buy new plan
        public static let buyNewPlan = Strings.tr("Localizable", "transferQuotaError.button.buyNewPlan", fallback: "Buy new plan")
        /// Button title of the dialog for transfer quota error that will direct to upgrade plan
        public static let upgrade = Strings.tr("Localizable", "transferQuotaError.button.upgrade", fallback: "Upgrade")
        /// Button title of the dialog for transfer quota error that will dismiss dialog
        public static let wait = Strings.tr("Localizable", "transferQuotaError.button.wait", fallback: "I will wait")
      }
      public enum DownloadExceededQuota {
        /// Title of the dialog for transfer quota error with exceeded quota
        public static let title = Strings.tr("Localizable", "transferQuotaError.downloadExceededQuota.title", fallback: "Transfer quota exceeded")
        public enum FreeAccount {
          /// Message text of the dialog for transfer quota error with exceeded download trasfer quota for free accounts
          public static func message(_ p1: Any) -> String {
            return Strings.tr("Localizable", "transferQuotaError.downloadExceededQuota.freeAccount.message", String(describing: p1), fallback: "You can’t continue downloading as you don’t have any transfer quota left for this IP address. To get more quota, upgrade to a Pro plan or wait for %@ until more free quota becomes available on your IP address. [A]Learn more[/A] about transfer quota.")
          }
        }
        public enum ProAccount {
          /// Message text of the dialog for transfer quota error with exceeded download trasfer quota for pro accounts
          public static let message = Strings.tr("Localizable", "transferQuotaError.downloadExceededQuota.proAccount.message", fallback: "You can’t continue downloading as you don’t have any transfer quota left on this account. To get more quota, purchase a new plan, or if you have a recurring subscription with MEGA, you can wait for your plan to renew.")
        }
      }
      public enum DownloadLimitedQuota {
        /// Title of the dialog for transfer quota error with limited available trasfer quota
        public static let title = Strings.tr("Localizable", "transferQuotaError.downloadLimitedQuota.title", fallback: "Limited available transfer quota")
        public enum FreeAccount {
          /// Message text of the dialog for transfer quota error with limited available trasfer quota for free accounts
          public static func message(_ p1: Any) -> String {
            return Strings.tr("Localizable", "transferQuotaError.downloadLimitedQuota.freeAccount.message", String(describing: p1), fallback: "Downloading may be interrupted as you’ve used most of your transfer quota for this IP address. To get more quota, upgrade to a Pro plan or wait for %@ until more free quota becomes available on your IP address. [A]Learn more[/A] about transfer quota.")
          }
        }
        public enum ProAccount {
          /// Message text of the dialog for transfer quota error with limited available trasfer quota for pro accounts
          public static let message = Strings.tr("Localizable", "transferQuotaError.downloadLimitedQuota.proAccount.message", fallback: "Downloading may be interrupted as you’ve used most of your transfer quota on this account. To get more quota, purchase a new plan, or if you have a recurring subscription with MEGA, you can wait for your plan to renew.")
        }
      }
      public enum FooterMessage {
        /// Footer message of the dialog for transfer quota error. [A] will be replaced by the usage quota percent. [B] will be replaced by the max transfer quota in TB. For example: 100% of 16 TB used
        public static let quotaUsage = Strings.tr("Localizable", "transferQuotaError.footerMessage.quotaUsage", fallback: "[A]%% of [B] TB used")
      }
      public enum StreamingExceededQuota {
        public enum FreeAccount {
          /// Message text of the dialog for transfer quota error with exceeded streaming trasfer quota for free accounts
          public static func message(_ p1: Any) -> String {
            return Strings.tr("Localizable", "transferQuotaError.streamingExceededQuota.freeAccount.message", String(describing: p1), fallback: "Your media stopped playing as you don’t have any transfer quota left for this IP address. To get more quota, upgrade to a Pro plan or wait for %@ until more free quota becomes available on your IP address. [A]Learn more[/A] about transfer quota.")
          }
        }
        public enum ProAccount {
          /// Message text of the dialog for transfer quota error with exceeded download trasfer quota for pro accounts
          public static let message = Strings.tr("Localizable", "transferQuotaError.streamingExceededQuota.proAccount.message", fallback: "Your media stopped playing as you don’t have any transfer quota left on this account. To get more quota, purchase a new plan, or if you have a recurring subscription with MEGA, you can wait for your plan to renew.")
        }
      }
    }
    public enum Transfers {
      public enum Cancellable {
        /// Message for action of cancelling a transfer
        public static let cancel = Strings.tr("Localizable", "transfers.cancellable.cancel", fallback: "Cancel transfer")
        /// Cancelling transfers step title message for cancellable transfer
        public static let cancellingTransfers = Strings.tr("Localizable", "transfers.cancellable.cancellingTransfers", fallback: "Cancelling transfers…")
        /// Message informing the user about transfers lost
        public static let confirmCancel = Strings.tr("Localizable", "transfers.cancellable.confirmCancel", fallback: "Interrupting the transfer process may render some of the items incomplete.")
        /// Second step title message for cancellable transfer
        public static let creatingFolders = Strings.tr("Localizable", "transfers.cancellable.creatingFolders", fallback: "Creating folders…")
        /// Dismiss action of cancelling a transfer
        public static let dismiss = Strings.tr("Localizable", "transfers.cancellable.dismiss", fallback: "No, continue")
        /// Message asking the user to not close the app during a process
        public static let donotclose = Strings.tr("Localizable", "transfers.cancellable.donotclose", fallback: "Don’t close the app. If you close, transfers not yet queued will be lost.")
        /// Confirm action of cancelling a transfer
        public static let proceed = Strings.tr("Localizable", "transfers.cancellable.proceed", fallback: "Yes, cancel")
        /// First step title message for cancellable transfer
        public static let scanning = Strings.tr("Localizable", "transfers.cancellable.scanning", fallback: "Scanning…")
        /// Title of the alert shown when you confirm to cancel pending transfers
        public static let title = Strings.tr("Localizable", "transfers.cancellable.title", fallback: "Cancel transfers?")
        /// Third step title message for cancellable transfer
        public static let transferring = Strings.tr("Localizable", "transfers.cancellable.transferring", fallback: "Transferring…")
        /// Message info for a cancelled transfer
        public static let trasnferCancelled = Strings.tr("Localizable", "transfers.cancellable.trasnferCancelled", fallback: "Transfer cancelled")
        public enum CreatingFolders {
          /// Count of folders created in the create folders stage
          public static func count(_ p1: Any, _ p2: Any) -> String {
            return Strings.tr("Localizable", "transfers.cancellable.creatingFolders.count", String(describing: p1), String(describing: p2), fallback: "%@/%@")
          }
        }
        public enum Scanning {
          /// Count of folders and files in the scanning stage
          public static func count(_ p1: Any, _ p2: Any) -> String {
            return Strings.tr("Localizable", "transfers.cancellable.scanning.count", String(describing: p1), String(describing: p2), fallback: "Found %@ and %@")
          }
        }
      }
    }
    public enum UpgradeAccountPlan {
      public enum Button {
        public enum BuyAccountPlan {
          /// On Upgrade Account Plan screen. Button title to buy account plan. %@ will be the name of the selected plan
          public static func title(_ p1: Any) -> String {
            return Strings.tr("Localizable", "upgradeAccountPlan.button.buyAccountPlan.title", String(describing: p1), fallback: "Buy %@")
          }
        }
        public enum Restore {
          /// On Upgrade Account Plan screen. Button title to restore purchases
          public static let title = Strings.tr("Localizable", "upgradeAccountPlan.button.restore.title", fallback: "Restore purchase")
        }
        public enum TermsAndPolicies {
          /// On Upgrade Account Plan screen. Button title to show terms and policies
          public static let title = Strings.tr("Localizable", "upgradeAccountPlan.button.termsAndPolicies.title", fallback: "Terms and policies")
        }
      }
      public enum Footer {
        public enum Message {
          /// On Upgrade Account Plan screen. Footer message with pricing page link.
          public static let pricingPage = Strings.tr("Localizable", "upgradeAccountPlan.footer.message.pricingPage", fallback: "You can upgrade your current subscription on our [A]pricing page[/A].")
        }
      }
      public enum Header {
        public enum PlanTermPicker {
          /// On Upgrade Account Plan screen. Account Plan picker option for monthly term.
          public static let monthly = Strings.tr("Localizable", "upgradeAccountPlan.header.planTermPicker.monthly", fallback: "Monthly")
          /// On Upgrade Account Plan screen. Account Plan picker option for yearly term.
          public static let yearly = Strings.tr("Localizable", "upgradeAccountPlan.header.planTermPicker.yearly", fallback: "Yearly")
        }
        public enum Title {
          /// On Upgrade Account Plan screen. Displayed header title text message
          public static let choosePlan = Strings.tr("Localizable", "upgradeAccountPlan.header.title.choosePlan", fallback: "Choose the right plan for you")
          /// On Upgrade Account Plan screen. Displayed header title text with current plan. %@ will be the name of the current plan
          public static func currentPlan(_ p1: Any) -> String {
            return Strings.tr("Localizable", "upgradeAccountPlan.header.title.currentPlan", String(describing: p1), fallback: "Current plan: %@")
          }
          /// On Upgrade Account Plan screen. Displayed header title text for pro plan features
          public static let featuresOfProPlan = Strings.tr("Localizable", "upgradeAccountPlan.header.title.featuresOfProPlan", fallback: "Features of Pro plans")
          /// On Upgrade Account Plan screen. Displayed header title text with percent of savings with yearly billing.
          public static let saveYearlyBilling = Strings.tr("Localizable", "upgradeAccountPlan.header.title.saveYearlyBilling", fallback: "Save up to 16%% with yearly billing")
          /// On Upgrade Account Plan screen. Displayed header title text for subscription details
          public static let subscriptionDetails = Strings.tr("Localizable", "upgradeAccountPlan.header.title.subscriptionDetails", fallback: "Subscription details")
        }
      }
      public enum Message {
        public enum Text {
          /// On Upgrade Account Plan screen. Displayed text body for pro plan features
          public static let featuresOfProPlan = Strings.tr("Localizable", "upgradeAccountPlan.message.text.featuresOfProPlan", fallback: "• Password-protected links\n\n• Links with expiry dates\n\n• Transfer quota sharing\n\n• Automatic backups\n\n• Rewind up to 90 days on Pro Lite and up to 365 days on Pro I, II, and III (coming soon)\n\n• Schedule rubbish bin clearing between 7 days and 10 years")
          /// On Upgrade Account Plan screen. Displayed text body for subscription details
          public static let subscriptionDetails = Strings.tr("Localizable", "upgradeAccountPlan.message.text.subscriptionDetails", fallback: "Subscriptions are renewed automatically for successive subscription periods of the same duration and at the same price as the initial period chosen.\nYou can switch off the automatic renewal of your MEGA Pro subscription no later than 24 hours before your next subscription payment is due via your iTunes account settings page.")
        }
      }
      public enum Plan {
        public enum Details {
          /// On Upgrade Account Plan screen. Displayed Storage detail on account plan options
          public static func storage(_ p1: Any) -> String {
            return Strings.tr("Localizable", "upgradeAccountPlan.plan.details.storage", String(describing: p1), fallback: "Storage: %@")
          }
          /// On Upgrade Account Plan screen. Displayed Transfer detail on account plan options
          public static func transfer(_ p1: Any) -> String {
            return Strings.tr("Localizable", "upgradeAccountPlan.plan.details.transfer", String(describing: p1), fallback: "Transfer: %@")
          }
          public enum Pricing {
            /// On Upgrade Account Plan screen. Displayed conversion for local currency per month on account plan options
            public static func localCurrencyPerMonth(_ p1: Any) -> String {
              return Strings.tr("Localizable", "upgradeAccountPlan.plan.details.pricing.localCurrencyPerMonth", String(describing: p1), fallback: "%@/month")
            }
            /// On Upgrade Account Plan screen. Displayed conversion for local currency per year on account plan options
            public static func localCurrencyPerYear(_ p1: Any) -> String {
              return Strings.tr("Localizable", "upgradeAccountPlan.plan.details.pricing.localCurrencyPerYear", String(describing: p1), fallback: "%@/year")
            }
          }
        }
        public enum Tag {
          /// On Upgrade Account Plan screen. Displayed tag text for current plan on account plan options
          public static let currentPlan = Strings.tr("Localizable", "upgradeAccountPlan.plan.tag.currentPlan", fallback: "Current plan")
          /// On Upgrade Account Plan screen. Displayed tag text for recommended plan on account plan options
          public static let recommended = Strings.tr("Localizable", "upgradeAccountPlan.plan.tag.recommended", fallback: "Recommended")
        }
      }
      public enum Selection {
        public enum Message {
          /// On Upgrade Account Plan screen. Snackbar message when selecting current recurring plan on account plan options
          public static let alreadyHaveRecurringSubscriptionOfPlan = Strings.tr("Localizable", "upgradeAccountPlan.selection.message.alreadyHaveRecurringSubscriptionOfPlan", fallback: "You already have a recurring subscription for this plan")
        }
      }
    }
    public enum VerifyCredentials {
      /// Title of the header label in contact verification screen.
      public static let headerMessage = Strings.tr("Localizable", "verifyCredentials.headerMessage", fallback: "We protect your data with zero-knowledge encryption so all the information you store, share, and receive on MEGA is secure. To ensure extra security, we ask you to approve the contacts you share information with or receive data from.")
      public enum YourCredentials {
        /// Title of the label in verification screen. It shows the credentials of the current user so it can be used to be verified by other contacts
        public static let title = Strings.tr("Localizable", "verifyCredentials.yourCredentials.title", fallback: "Your credentials")
      }
    }
    public enum Video {
      public enum Alert {
        public enum ResumeVideo {
          /// Alert message shown for video with options to resume playing the video or start from the beginning. %1$s will be replaced by name of the video. %2$s will be replaced by video timestamp
          public static func message(_ p1: UnsafePointer<CChar>, _ p2: UnsafePointer<CChar>) -> String {
            return Strings.tr("Localizable", "video.alert.resumeVideo.message", p1, p2, fallback: "%1$s will resume from %2$s")
          }
          /// Alert title shown for video with options to resume playing the video or start from the beginning
          public static let title = Strings.tr("Localizable", "video.alert.resumeVideo.title", fallback: "Resume video?")
          public enum Button {
            /// Alert button title that will start playing the video from the beginning
            public static let restart = Strings.tr("Localizable", "video.alert.resumeVideo.button.restart", fallback: "Restart")
            /// Alert button title that will resume playing the video
            public static let resume = Strings.tr("Localizable", "video.alert.resumeVideo.button.resume", fallback: "Resume")
          }
        }
      }
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension Strings {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
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
