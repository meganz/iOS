import Foundation
import MessageKit
import InputBarAccessoryView

extension ChatViewController: InputBarAccessoryViewDelegate {
    func configureInputBar() {
        messageInputBar.delegate = self
        
        messageInputBar.inputTextView.backgroundColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1)
        messageInputBar.inputTextView.placeholderTextColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        messageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20)
        messageInputBar.inputTextView.layer.borderColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1).cgColor
        messageInputBar.inputTextView.layer.borderWidth = 1.0
        messageInputBar.inputTextView.layer.cornerRadius = 16.0
        messageInputBar.inputTextView.layer.masksToBounds = true
        messageInputBar.inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        messageInputBar.middleContentViewPadding.left = -38
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 36, bottom: 8, right: 8)
        messageInputBar.inputTextView.placeholder = "12"
        messageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 44, bottom: 8, right: 8)
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        
        let button = InputBarButtonItem()
        button.onKeyboardSwipeGesture { item, gesture in
            if gesture.direction == .left {
                item.inputBarAccessoryView?.setLeftStackViewWidthConstant(to: 0, animated: true)
            } else if gesture.direction == .right {
                item.inputBarAccessoryView?.setLeftStackViewWidthConstant(to: 36, animated: true)
            }
        }
        button.setSize(CGSize(width: 36, height: 36), animated: false)
        button.setImage(#imageLiteral(resourceName: "add").withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = UIColor(red: 0, green: 122/255, blue: 1, alpha: 1)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
        
    }
}
