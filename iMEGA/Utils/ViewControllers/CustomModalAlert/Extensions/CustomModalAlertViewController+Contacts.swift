
import Foundation

extension CustomModalAlertViewController {
    
    func configureOutgoingContactRequest(_ email: String) {
        image = UIImage(named: "inviteSent")
        viewTitle = NSLocalizedString("inviteSent", comment: "Title shown when the user sends a contact invitation")
        var detailText = NSLocalizedString("theUserHasBeenInvited", comment: "Success message shown when a contact has been invited")
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
        
        var detailText = "Your contact %@ is not on MEGA. In order to call through MEGA's encrypted chat you need to invite your contact"
        detailText = detailText.replacingOccurrences(of: "%@", with: email)
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

