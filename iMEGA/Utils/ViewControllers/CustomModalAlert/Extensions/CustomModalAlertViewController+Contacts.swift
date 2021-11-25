
import Foundation

extension CustomModalAlertViewController {
    
    func configureOutgoingContactRequest(_ email: String) {
        image = UIImage(named: "inviteSent")
        viewTitle = NSLocalizedString("inviteSent", comment: "Title shown when the user sends a contact invitation")
        var detailText = NSLocalizedString("dialog.inviteContact.outgoingContactRequest", comment: "Detail message shown when a contact has been invited. The [X] placeholder will be replaced on runtime for the email of the invited user")
        detailText = detailText.replacingOccurrences(of: "[X]", with: email)
        detail = detailText
        
        boldInDetail = email
        
        firstButtonTitle = NSLocalizedString("close", comment: "")
        dismissButtonTitle = nil
        
        firstCompletion = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }
    
    func configureContactNotInMEGA(_ email: String) {
        image = UIImage(named: "groupChat")
        viewTitle = NSLocalizedString("inviteContact", comment: "Title shown when the user tries to make a call and the destination is not in the contact list")
        
        var detailText = NSLocalizedString("dialog.callAttempt.contactNotInMEGA", comment: "Detail message shown when you try to call someone that is not you contact in MEGA. The [X] placeholder will be replaced on runtime for the email of the user")
        detailText = detailText.replacingOccurrences(of: "[X]", with: email)
        detail = detailText
        
        boldInDetail = email
        
        firstButtonTitle = NSLocalizedString("invite", comment: "A button on a dialog which invites a contact to join MEGA")
        
        dismissButtonTitle = NSLocalizedString("later", comment: "Button title to allow the user postpone an action")
        
        firstCompletion = { [weak self] in
            let inviteContactRequestDelegate = MEGAInviteContactRequestDelegate(numberOfRequests: 1)
            MEGASdkManager.sharedMEGASdk().inviteContact(withEmail: email, message: "", action: .add, delegate: inviteContactRequestDelegate)
            
            self?.dismiss(animated: true, completion: nil)
        }
    }
}

