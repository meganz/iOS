import MEGADomain
import MEGAPresentation

@objc final class ContactsViewModel: NSObject {
    private let sdk: MEGASdk
    var bannerConfig: BannerView.Config?
    var bannerDecider: (Int) -> Bool = { _ in false }
    var dismissedBannerWarning = false
    var shouldShowBannerWarning: Bool {
        bannerConfig != nil && !dismissedBannerWarning
    }
    
    init(
        sdk: MEGASdk
    ) {
        self.sdk = sdk
    }
    
    func shouldShowBannerWarning(
        selectedUsersCount: Int
    ) -> Bool {
        reachedLimitOfCallParticipants(selectedUsersCount: selectedUsersCount)
        && !dismissedBannerWarning
    }
    
    private func reachedLimitOfCallParticipants(
        selectedUsersCount: Int
    ) -> Bool {
        bannerDecider(selectedUsersCount)
    }
   
    @objc
    func shouldShowUnverifiedContactsBanner(
        contactsMode: ContactsMode,
        selectedUsersArray: NSMutableArray?,
        visibleUsersArray: NSMutableArray?
    ) -> Bool {
        
        guard sdk.isContactVerificationWarningEnabled,
              [ContactsMode.shareFoldersWith, ContactsMode.folderSharedWith].contains(contactsMode) else {
            return false
        }

        var users: [MEGAUser]?

        // We are displaying the warning banner in this screen when it is started for two contact modes:
        // 1. ContactsMode == .shareFoldersWith (when we are starting "Share Folder" flow)
        // 2. ContactsMode == .folderShared with (when the folder is already shared and we tapped on "Manage Share")
        if contactsMode == .shareFoldersWith {
            // In the first point of entry, users which we want to share folder with are stored in selectedUsersArray.
            // We have couple of options to add user to share a folder with:
            // 1. Select them from the list of our MEGA contacts
            // 2. Add external users via contacts, email, or QR code
            // Because of that, our selectedUsersArray can be consisted of both MEGAUser and String objects which represent emails and all three options
            // and look something like this ["mega@test.com", MEGAUser, "mega@test2.com"]
            users = selectedUsersArray?.filter { $0 is MEGAUser } as? [MEGAUser]
        } else {
            // In the second point, users with which the folder is already shared are stored in stored in visibleUsersArray.
            users = visibleUsersArray as? [MEGAUser]
        }

        // We check if in the existing MEGA users we have some which are unverified
        let hasExistingUnverifiedContacts = users?.contains(where: { !sdk.areCredentialsVerified(of: $0) }) == true

        // We check if we have invited non existing MEGA users by contacts, email, or QR
        // In that situation, we consider these users as unverified also, and we should display the banner
        let selectedUsersCount = selectedUsersArray?.count ?? 0
        let hasInvitedNonExistingUsers = selectedUsersArray != nil && selectedUsersCount > 0 &&
        (users?.count ?? 0) < selectedUsersCount

        return hasExistingUnverifiedContacts || hasInvitedNonExistingUsers
    }
}
