import Foundation
import MessageKit

extension ChatViewController {
    
    override var inputAccessoryView: UIView? {
        if displayedAddToChatViewController {
            return nil
        }
        
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
        addToChatViewController = AddToChatViewController(nibName: nil, bundle: nil)
        
        addToChatViewController.tapHandler = {
            self.displayedAddToChatViewController = false
            self.reloadInputViews()
        }
        
        addToChatViewController.dismissHandler = {[weak self] viewController in
            // remove the content
            viewController.willMove(toParent: nil)
            viewController.view.removeFromSuperview()
            viewController.removeFromParent()
            
            guard let `self` = self else {
                return
            }
            
            self.addToChatViewController = nil
        }
        
        if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
            // add content view
            rootViewController.addChild(addToChatViewController)
            rootViewController.view.addSubview(addToChatViewController.view)
            addToChatViewController.view.autoPinEdgesToSuperviewEdges()
            addToChatViewController.didMove(toParent: rootViewController)
            
            self.displayedAddToChatViewController = true

            // remove the accessory view and presenting animation
            chatInputBar.dismissKeyboard()
            reloadInputViews()
            addToChatViewController.presentAnimation()
        }
        
    }
}

extension ChatViewController: ChatMessageAndAudioInputBarDelegate {
    
    func tappedAddButton() {
        displayAddToChatViewController()
    }
    
    func tappedSendButton(withText text: String) {
        print("Send button tapped with text \(text)")
        
        let message = MEGASdkManager.sharedMEGAChatSdk()?.sendMessage(toChat: chatRoom.chatId, message: text)
        print(message!.status)

        chatRoomDelegate.insertMessage(message!)
    }
    
    func tappedSendAudio(atPath path: String) {
        print("send audio at path \(path)")
        
        // TODO: Refactor the below code.
        // Handle errors and show the progress as well
        MEGASdkManager.sharedMEGASdk()!.getMyChatFilesFolder {[weak self] result in
            guard let `self` = self else {
                return
            }
            
            let voiceFolderName = "My voice messages"
            
            let transferUploadDelegate: MEGAStartUploadTransferDelegate  = MEGAStartUploadTransferDelegate { _ in
                // SHould show the progress to the user.
            }
            
            let appData = ("" as NSString).mnz_appDataToAttach(toChatID: self.chatRoom.chatId, asVoiceClip: true)

            if let voiceMessagesNode = MEGASdkManager.sharedMEGASdk()!.node(forPath: voiceFolderName, node: result) {
                MEGASdkManager.sharedMEGASdk()!.startUpload(withLocalPath: path,
                                                            parent: voiceMessagesNode,
                                                            appData: appData,
                                                            isSourceTemporary: true,
                                                            delegate: transferUploadDelegate)
            } else {
                let requestDelegate: MEGARequestDelegate = MEGACreateFolderRequestDelegate { request in
                    guard let request = request else {
                        fatalError("request object should not be nil")
                    }
                    
                    if let voiceMessagesNode = MEGASdkManager.sharedMEGASdk()!.node(forHandle: request.nodeHandle) {

                        MEGASdkManager.sharedMEGASdk()!.startUpload(withLocalPath: path,
                                                                    parent: voiceMessagesNode,
                                                                    appData: appData,
                                                                    isSourceTemporary: true,
                                                                    delegate: transferUploadDelegate)

                    }
                }
                
                MEGASdkManager.sharedMEGASdk()!.createFolder(withName: voiceFolderName,
                                                             parent: result,
                                                             delegate: requestDelegate)
            }
        }
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
