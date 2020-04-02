import Foundation
import MessageKit
import InputBarAccessoryView

extension ChatViewController: InputBarAccessoryViewDelegate {
    func configureInputBar() {
        messageInputBar.delegate = self
        
        messageInputBar.inputTextView.backgroundColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1)
        messageInputBar.inputTextView.placeholderTextColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 12, left: 38, bottom: 12, right: 16)
        messageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 12, left: 40, bottom: 12, right: 20)
        messageInputBar.inputTextView.layer.cornerRadius = 25
        messageInputBar.inputTextView.layer.masksToBounds = true
        messageInputBar.inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        messageInputBar.middleContentViewPadding.left = -38
        messageInputBar.separatorLine.backgroundColor = .clear
        messageInputBar.inputTextView.placeholder = "Message..."
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setRightStackViewWidthConstant(to: 36, animated: false)

        let button = InputBarButtonItem()
        button.onKeyboardSwipeGesture { item, gesture in
            if gesture.direction == .left {
                item.inputBarAccessoryView?.setLeftStackViewWidthConstant(to: 0, animated: true)
            } else if gesture.direction == .right {
                item.inputBarAccessoryView?.setLeftStackViewWidthConstant(to: 36, animated: true)
            }
        }
        .onKeyboardEditingBegins { (item) in
            item.inputBarAccessoryView?.setRightStackViewWidthConstant(to: 0, animated: true)

        }.onKeyboardEditingEnds { (item) in
            item.inputBarAccessoryView?.setRightStackViewWidthConstant(to: 36, animated: true)

        }
        
        button.setSize(CGSize(width: 60, height: 60), animated: false)
        button.setImage(UIImage(named: "addAttachment"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = UIColor(red: 0, green: 122/255, blue: 1, alpha: 1)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
        messageInputBar.sendButton.image = UIImage(named: "sendVoiceClipDefault")
        messageInputBar.sendButton.title = nil
        messageInputBar.sendButton.setSize(CGSize(width: 60, height: 60), animated: false)
        messageInputBar.sendButton.imageView?.backgroundColor = UIColor(white: 0.85, alpha: 1)
        messageInputBar.sendButton.imageView?.layer.cornerRadius = 16

        
    }
}
