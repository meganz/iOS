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
        if let rc = UIApplication.shared.keyWindow?.rootViewController {
            if let tabBarController = rc as? UITabBarController {
                tabBarController.tabBar.isHidden = true
            }
            
            chatInputBar.dismissKeyboard()

            let addToChatViewController = AddToChatViewController(nibName: nil, bundle: nil)
            addToChatViewController.delegate = self
            addToChatViewController.transitioningDelegate = self
            rc.present(addToChatViewController, animated: true) {
                if let tabBarController = rc as? UITabBarController {
                    tabBarController.tabBar.isHidden = false
                }
            }
        }
    }
}

extension ChatViewController: ChatMessageAndAudioInputBarDelegate {
    
    func tappedAddButton() {
        displayAddToChatViewController()
    }
    
    func tappedSendButton(withText text: String) {
        print("Send button tapped with text \(text)")
        var message : MEGAChatMessage?
        if editMessage != nil {
            if editMessage?.message.content != text {
                let messageId = editMessage?.message.status == .sending ? editMessage?.message.temporalId : editMessage?.message.messageId
                message = MEGASdkManager.sharedMEGAChatSdk()?.editMessage(forChat: chatRoom.chatId, messageId: messageId!, message: text)!
                message?.chatId = chatRoom.chatId
                let index = messages.firstIndex(of: editMessage!)
                if index != NSNotFound {
                    chatRoomDelegate.messages[index!] = ChatMessage(message: message!, chatRoom: chatRoom)
                    messagesCollectionView.reloadDataAndKeepOffset()
                }
            }
            
            editMessage = nil
        } else {
            message = MEGASdkManager.sharedMEGAChatSdk()?.sendMessage(toChat: chatRoom.chatId, message: text)
            print(message!.status)
            
            chatRoomDelegate.insertMessage(message!)
            
        }
        MEGASdkManager.sharedMEGAChatSdk()?.sendStopTypingNotification(forChat: chatRoom.chatId)
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
    
    func present(viewController: UIViewController) {
        if let rc = UIApplication.shared.keyWindow?.rootViewController {
            if let tabBarController = rc as? UITabBarController {
                tabBarController.tabBar.isHidden = true
            }
            
            present(viewController, animated: true) {
                if let tabBarController = rc as? UITabBarController {
                    tabBarController.tabBar.isHidden = false
                }
            }
        }

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


extension ChatViewController: AddToChatViewControllerDelegate {
    func send(asset: PHAsset) {
        print("send the asset")
        
        //TODO: Refactor this function.
        MEGASdkManager.sharedMEGASdk()!.getMyChatFilesFolder {[weak self] resultNode in
            guard let `self` = self else {
                return
            }
            
            let processAsset = MEGAProcessAsset(toShareThroughChatWith: [asset], parentNode: resultNode, filePaths: { filePaths in
                
                guard let filePath = filePaths?.first else {
                    return
                }
                
                let transferUploadDelegate: MEGAStartUploadTransferDelegate  = MEGAStartUploadTransferDelegate { _ in
                    // Should show the progress to the user.
                }
                
                var appData: String? = nil
                
                if let cordinates = (filePath as NSString).mnz_coordinatesOfPhotoOrVideo() {
                    appData = NSString().mnz_appData(toSaveCoordinates: cordinates)
                }
                
                if appData == nil {
                    appData = ("" as NSString).mnz_appDataToAttach(toChatID: self.chatRoom.chatId,
                                                                   asVoiceClip: false)
                } else {
                    appData = appData!.mnz_appDataToAttach(toChatID: self.chatRoom.chatId,
                                                           asVoiceClip: false)
                }
                
                MEGASdkManager.sharedMEGASdk()!.startUpload(withLocalPath: filePath,
                                                            parent: resultNode,
                                                            appData: appData,
                                                            isSourceTemporary: true,
                                                            delegate: transferUploadDelegate)
                
            }, nodes:nil) { errors in
                guard let error = errors?.first else {
                    return
                }
                
                let alertController = UIAlertController(title: AMLocalizedString("error", nil),
                                                        message: error.localizedDescription,
                                                        preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: AMLocalizedString("ok", nil),
                                                        style: .cancel,
                                                        handler: nil))
                
                DispatchQueue.main.async {
                    self.present(alertController, animated: true)
                }
            }
            
            DispatchQueue.global(qos: .background).async {
                processAsset?.isOriginalName = true
                processAsset?.prepare()
            }
        }
    }
    
    func loadPhotosView() {
        let imagePickerController = MEGAAssetsPickerController { assets in
            guard let assets = assets else {
                return
            }
            
            assets.forEach { self.send(asset: $0)}
        }
        
        present(viewController: imagePickerController!)
    }
    
    func showCamera() {
        let pickerController = MEGAImagePickerController(toShareThroughChatWith: .camera) { (filePath, sourceType, node) in
            guard let path = filePath,
                let parentNode = node,
                (path as NSString).mnz_isImagePathExtension else {
                    return
            }
            
            let transferUploadDelegate: MEGAStartUploadTransferDelegate  = MEGAStartUploadTransferDelegate { _ in
                // Should show the progress to the user.
            }
            
            let appData = ("" as NSString).mnz_appDataToAttach(toChatID: self.chatRoom.chatId,
                                                               asVoiceClip: false)
            
            MEGASdkManager.sharedMEGASdk()!.startUpload(withLocalPath: path,
                                                        parent: parentNode,
                                                        appData: appData,
                                                        isSourceTemporary: true,
                                                        delegate: transferUploadDelegate)
        }
        
        present(viewController: pickerController!)
    }
    
    func showCloudDrive() {
        let storyboard = UIStoryboard(name: "Cloud", bundle: nil)
        let cloudDriveNavController = storyboard.instantiateViewController(withIdentifier: "BrowserNavigationControllerID")
        
        if let navController = cloudDriveNavController as? UINavigationController,
            let browserViewController = navController.viewControllers.first as? BrowserViewController {
            browserViewController.browserAction = .sendFromCloudDrive
            browserViewController.selectedNodes = { selectedObjects in
                guard let selectedNodes = selectedObjects as? [MEGANode] else {
                    return
                }
                
                // TODO: Handle the error
                selectedNodes.forEach { node in
                    Helper.import(node) { newNode in
                        MEGASdkManager.sharedMEGAChatSdk()?.attachNode(toChat: self.chatRoom.chatId, node: newNode.handle)
                    }
                }
                
            }
        }
        
        present(viewController: cloudDriveNavController)
    }
    
    func showVoiceClip() {
        
    }
    
    func showContacts() {
        let storyboard = UIStoryboard(name: "Contacts", bundle: nil)
        let contactsNavigationController = storyboard.instantiateViewController(withIdentifier: "ContactsNavigationControllerID")
        
        guard let navController = contactsNavigationController as? UINavigationController,
            let contactsViewController = navController.viewControllers.first as? ContactsViewController else {
                return
        }
            
        contactsViewController.contactsMode = .chatAttachParticipant

        contactsViewController.userSelected = { users in
            if let message = MEGASdkManager.sharedMEGAChatSdk()?.attachContacts(toChat: self.chatRoom.chatId,
                                                                                contacts: users) {
                //TODO: Add the message to model and reload the cell.
                print(message)
                
            }
        }
        
        present(viewController: contactsNavigationController)
    }
    
    func startGroupChat() {
        
    }
    
    func showLocation() {
        
    }
}
