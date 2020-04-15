import Foundation
import MessageKit

extension ChatViewController {
    
    override var inputAccessoryView: UIView? {
        if chatMessageAndAudioInputBar == nil {
            chatMessageAndAudioInputBar = ChatMessageAndAudioInputBar()
            chatMessageAndAudioInputBar.delegate = self
        }
        
        return chatMessageAndAudioInputBar
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }

}

extension ChatViewController: ChatMessageAndAudioInputBarDelegate {
    
    func tappedAddButton() {
        print("Add button tapped")
    }
    
    func tappedSendButton(withText text: String) {
        print("Send button tapped with text \(text)")
    }
    
    func tappedVoiceButton() {
        let myViews = view.subviews.filter { $0 is TapAndHoldMessageView }
        guard myViews.count == 0  else {
            return
        }
        

        let tapAndHoldMessageView = TapAndHoldMessageView.instanceFromNib
        tapAndHoldMessageView.add(toView: view, bottom: inputAccessoryView!.frame.height)
    }
    
    func typing(withText text: String) {
        print("Started typing with text \(text)")
    }
}
