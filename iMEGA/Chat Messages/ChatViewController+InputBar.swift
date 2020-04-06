import Foundation
import MessageKit

extension ChatViewController {
    
    override var inputAccessoryView: UIView? {
        if inputBar == nil {
            inputBar = MessageInputBar.instanceFromNib
            inputBar.delegate = self
        }
        
        return inputBar
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }

}

extension ChatViewController: MessageInputBarDelegate {
    
    func tappedAddButton() {
        print("Add button tapped")
    }
    
    func tappedSendButton(withText text: String) {
        print("Send button tapped with text \(text)")
    }
    
    func tappedVoiceButton() {
        print("Voice button tapped")
    }
    
    func typing(withText text: String) {
        print("Started typing with text \(text)")
    }
}
