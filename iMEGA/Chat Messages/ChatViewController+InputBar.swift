import Foundation
import MessageKit

extension ChatViewController {
    
    override var inputAccessoryView: UIView? {
        if chatInputBar == nil {
            chatInputBar = ChatInputBar()
            chatInputBar.delegate = self
        }
        
        return chatInputBar
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    private func displayAddToChatViewController() {
        // Using last window instead of keywindow. Using keywindow creates a glitch in the animation.
        // Athough using last prints "Keyboard cannot present view controllers" but does not have any side effects.
        // https://stackoverflow.com/questions/46996251/inputaccessoryview-animating-down-when-alertcontroller-actionsheet-presented
        guard let rootViewController = UIApplication.shared.windows.last?.rootViewController else {
            return
        }
        
        addToChatViewController = AddToChatViewController(nibName: nil, bundle: nil)
        addToChatViewController.transitioningDelegate = self
        rootViewController.present(addToChatViewController, animated: true, completion: nil)
    }
}

extension ChatViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard presented is AddToChatViewController else {
            return nil
        }
        
        return AddToChatViewAnimator(type: .present)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard dismissed is AddToChatViewController else {
            return nil
        }
        
        return AddToChatViewAnimator(type: .dismiss)
    }
}

extension ChatViewController: ChatMessageAndAudioInputBarDelegate {
    
    func tappedAddButton() {
        displayAddToChatViewController()
    }
    
    func tappedSendButton(withText text: String) {
        print("Send button tapped with text \(text)")
        MEGASdkManager.sharedMEGAChatSdk()?.sendMessage(toChat: chatRoom.chatId, message: text)
    }
    
    func tappedSendAudio(atPath path: String) {
        print("send audio at path \(path)")
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
