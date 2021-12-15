
import Foundation

extension CustomModalAlertViewController {
    
    func configureOutgoingContactRequest(_ email: String) {
        image = Asset.Images.Contacts.inviteSent.image
        viewTitle = Strings.Localizable.inviteSent
        var detailText = Strings.Localizable.Dialog.InviteContact.outgoingContactRequest
        detailText = detailText.replacingOccurrences(of: "[X]", with: email)
        detail = detailText
        
        boldInDetail = email
        
        firstButtonTitle = Strings.Localizable.close
        dismissButtonTitle = nil
        
        firstCompletion = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }
    
    func configureContactNotInMEGA(_ email: String) {
        image = Asset.Images.Chat.groupChat.image
        viewTitle = Strings.Localizable.inviteContact
        
        var detailText = Strings.Localizable.Dialog.CallAttempt.contactNotInMEGA
        detailText = detailText.replacingOccurrences(of: "[X]", with: email)
        detail = detailText
        
        boldInDetail = email
        
        firstButtonTitle = Strings.Localizable.invite
        
        dismissButtonTitle = Strings.Localizable.later
        
        firstCompletion = { [weak self] in
            let inviteContactRequestDelegate = MEGAInviteContactRequestDelegate(numberOfRequests: 1)
            MEGASdkManager.sharedMEGASdk().inviteContact(withEmail: email, message: "", action: .add, delegate: inviteContactRequestDelegate)
            
            self?.dismiss(animated: true, completion: nil)
        }
    }
}

