import Foundation
import MessageKit

extension ChatViewController {
    
    override var inputAccessoryView: UIView? {
        if inputBar == nil {
            inputBar = MessageInputBar.instanceFromNib
        }
        
        return inputBar
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }

}
