import Foundation
import MessageKit

extension ChatViewController {
    
    // MARK: - Overriden properties
    
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
    
    // MARK: - Interface methods.
    
     func present(viewController: UIViewController) {
        if let rc = UIApplication.shared.keyWindow?.rootViewController {
            if let tabBarController = rc as? UITabBarController {
                tabBarController.tabBar.isHidden = true
            }
            
            rc.present(viewController, animated: true) {
                if let tabBarController = rc as? UITabBarController {
                    tabBarController.tabBar.isHidden = false
                }
            }
        }
     }
    
    // MARK: - Private methods.
    
    private func displayAddToChatViewController(_ button: UIButton) {
        let addToChatViewController = AddToChatViewController(nibName: nil, bundle: nil)
        addToChatViewController.addToChatDelegate = self
        
        chatInputBar.dismissKeyboard()

        if UIDevice.current.iPadDevice {
            let navController = MEGANavigationController(rootViewController: addToChatViewController)
            navController.addLeftDismissButton(withText: AMLocalizedString("cancel"))
            navController.modalPresentationStyle = .popover;
            navController.preferredContentSize = CGSize(width: 440, height: 360)

            if let popover = navController.popoverPresentationController {
                popover.delegate = self

                popover.sourceView = button
                popover.sourceRect = button.bounds

                present(navController, animated: true, completion: nil)
            }
        } else {
            
            addToChatViewController.transitioningDelegate = self
            present(viewController: addToChatViewController)
        }
    }
        
    private func presentShareLocation() {
        let storyboard = UIStoryboard(name: "Chat", bundle: nil)
        guard let shareLocationViewController = storyboard.instantiateViewController(withIdentifier: "ShareLocationViewControllerID") as? ShareLocationViewController else {
            fatalError("ChatViewController: could not create an instance of ShareLocationViewController")
        }
        
        shareLocationViewController.chatRoom = chatRoom
            
        let navController = MEGANavigationController(rootViewController: shareLocationViewController)
        navController.addLeftDismissButton(withText: AMLocalizedString("cancel"))
        present(viewController: navController)
    }
    
    private func createGroupChat(selectedObjects: [Any]?,
                                 groupName: String?,
                                 keyRotationEnabled: Bool,
                                 getChatLink:Bool) {
        guard let selectedUsers = selectedObjects as? [MEGAUser],
            let groupName = groupName else {
            return
        }
        
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show()

        let peerlist = MEGAChatPeerList()
        selectedUsers.forEach { peerlist.addPeer(withHandle: $0.handle, privilege: 2)}
        
        if keyRotationEnabled {
            let createChatGroupRequestDelegate = MEGAChatCreateChatGroupRequestDelegate { newChatRoom in
                self.open(chatRoom: newChatRoom)
            }
            
            MEGASdkManager.sharedMEGAChatSdk()?.createChatGroup(true,
                                                                peers: peerlist,
                                                                title: groupName,
                                                                delegate: createChatGroupRequestDelegate)

            
        } else {
            let createChatGroupRequestDelegate = MEGAChatCreateChatGroupRequestDelegate { newChatRoom in
                if getChatLink {
                    let genericRequestDelegate = MEGAChatGenericRequestDelegate { (request, error) in
                        if error.type == .MEGAChatErrorTypeOk {
                            let chatViewController = ChatViewController()
                            chatViewController.publicChatWithLinkCreated = true
                            chatViewController.chatRoom = newChatRoom
                            chatViewController.publicChatLink = URL(string: request.text)
                            self.replaceCurrentViewController(withViewController: chatViewController)
                        }
                    }
                    
                    guard let chatId = newChatRoom?.chatId else {
                        fatalError("could not create chatlink The chat id is nil")
                    }

                    
                    MEGASdkManager.sharedMEGAChatSdk()?.createChatLink(chatId, delegate: genericRequestDelegate)
                } else {
                    self.open(chatRoom: newChatRoom)
                }
            }
            MEGASdkManager.sharedMEGAChatSdk()?.createPublicChat(withPeers: peerlist,
                                                                 title: groupName,
                                                                 delegate: createChatGroupRequestDelegate)
        }
    }
    
    private func createContactsViewController() -> (UINavigationController, ContactsViewController)? {
        let storyboard = UIStoryboard(name: "Contacts", bundle: nil)
        let contactsNavigationController = storyboard.instantiateViewController(withIdentifier: "ContactsNavigationControllerID")
        
        guard let navController = contactsNavigationController as? UINavigationController,
            let contactsViewController = navController.viewControllers.first as? ContactsViewController else {
                return nil
        }
        
        return (navController, contactsViewController)
    }
    
    private func open(chatRoom: MEGAChatRoom?) {
        let chatViewController = ChatViewController()
        chatViewController.chatRoom = chatRoom
        replaceCurrentViewController(withViewController: chatViewController)
    }
    
    private func replaceCurrentViewController(withViewController viewController: UIViewController,
                                              dismissProgress: Bool = true) {
        guard let navController = navigationController else {
            fatalError("No navigation controller in the stack to push")
        }

        let currentIndex = navController.viewControllers.count - 1
        navController.pushViewController(viewController, animated: false)
        navController.viewControllers.remove(at: currentIndex)
        
        if dismissProgress {
            SVProgressHUD.setDefaultMaskType(.none)
            SVProgressHUD.dismiss()
        }
    }
}

extension ChatViewController: ChatMessageAndAudioInputBarDelegate {
    
    func tappedAddButton(_ button: UIButton) {
        displayAddToChatViewController(button)
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
                let transferUploadDelegate: MEGAStartUploadTransferDelegate = MEGAStartUploadTransferDelegate(toUploadToChatWithTotalBytes: { (transfer) in
                    let totalBytes = transfer!.totalBytes.doubleValue
                    self.totalBytesToUpload += totalBytes
                    self.remainingBytesToUpload += totalBytes
                }, progress: { (transfer) in
                    self.navigationBarProgressView.isHidden = false
                    let transferredBytes = transfer!.transferredBytes.doubleValue
                    let totalBytes = transfer!.totalBytes.doubleValue
                    let asignableProgresRegardWithTotal = totalBytes / self.totalBytesToUpload
                    let transferProgress = transferredBytes / totalBytes
                    var currentAsignableProgressForThisTransfer = transferProgress * asignableProgresRegardWithTotal
                    if (currentAsignableProgressForThisTransfer < asignableProgresRegardWithTotal) {
                        if (self.totalProgressOfTransfersCompleted != 0) {
                            currentAsignableProgressForThisTransfer += self.totalProgressOfTransfersCompleted
                        }
                        
                        if (currentAsignableProgressForThisTransfer > Double(self.navigationBarProgressView.progress)) {
                            self.navigationBarProgressView.setProgress(Float(currentAsignableProgressForThisTransfer), animated: true)
                        }
                    }
                }, completion: { (transfer) in
                    let totalBytes = transfer!.totalBytes.doubleValue
                    let progressCompletedRegardWithTotal = totalBytes / self.totalBytesToUpload
                    self.totalProgressOfTransfersCompleted += progressCompletedRegardWithTotal
                    self.remainingBytesToUpload -= totalBytes
                    
                    if self.remainingBytesToUpload == 0 {
                        self.navigationBarProgressView.progress = 0
                        self.navigationBarProgressView.isHidden = true
                    }
                    
                })
                
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
        chatInputBar.recordingViewEnabled = true
    }
    
    func showContacts() {
        guard let (contactsNavigationController, contactsViewController) = createContactsViewController() else {
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
        guard let (contactsNavigationController, contactsViewController) = createContactsViewController() else {
            return
        }

        contactsViewController.contactsMode = .chatCreateGroup
        contactsViewController.createGroupChat = createGroupChat
        present(viewController: contactsNavigationController)
    }
    
    func showLocation() {
        let genericRequestDelegate = MEGAGenericRequestDelegate { (request, error) in
            if error.type != .apiOk {
                let title = AMLocalizedString("Send Location", "Alert title shown when the user opens a shared Geolocation for the first time from any client, we will show a confirmation dialog warning the user that he is now leaving the E2EE paradigm")
                
                let message = AMLocalizedString("This location will be opened using a third party maps provider outside the end-to-end encrypted MEGA platform.", "Message shown when the user opens a shared Geolocation for the first time from any client, we will show a confirmation dialog warning the user that he is now leaving the E2EE paradigm")
                
                let cancelAction = UIAlertAction(title: AMLocalizedString("cancel"), style: .cancel) { _ in
                    //TODO: Logic if check if the input bar hidden or not.
                }
                
                let continueAction = UIAlertAction(title: AMLocalizedString("continue"), style: .default) { _ in
                    let enableGeolocationDelegate = MEGAGenericRequestDelegate { (request, error) in
                        if error.type != .apiOk {
                            let alertTitle = AMLocalizedString("error")
                            let alertMessage = String(format: "Enable geolocation failed. Error: %@", error.name)
                            
                            let enableGeolocationAlertAction = UIAlertAction(title: AMLocalizedString("ok"),
                                                                             style: .default) { _ in
                                                                                //TODO: Logic if check if the input bar hidden or not.
                                                                                
                            }
                            
                            let enableGeolocationAlertController = UIAlertController(title: alertTitle,
                                                                                     message: alertMessage,
                                                                                     preferredStyle: .alert)
                            enableGeolocationAlertController.addAction(enableGeolocationAlertAction)
                            self.present(viewController: enableGeolocationAlertController)
                        } else {
                            self.presentShareLocation()
                        }
                    }
                    MEGASdkManager.sharedMEGASdk()?.enableGeolocation(with: enableGeolocationDelegate)
                }
                
                let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alertController.addAction(cancelAction)
                alertController.addAction(continueAction)
                self.present(viewController: alertController)
            } else {
                self.presentShareLocation()
            }
        }
        MEGASdkManager.sharedMEGASdk()?.isGeolocationEnabled(with: genericRequestDelegate)
    }
    
    func recordingViewShown(withAdditionalHeight height: CGFloat) {
        // Messagekit calculates the inset intially, keyboard shown or hidden, textview text changed. In other cases we need to add the height manually.
        additionalBottomInset = height
    }
    
    func recordingViewHidden() {
        // Need to reset the additional bottom inset set during `recordingViewShown` method.
        additionalBottomInset = 0
    }
}

extension ChatViewController: UIPopoverPresentationControllerDelegate {
//    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
//        <#code#>
//    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController,
                                   traitCollection: UITraitCollection) -> UIModalPresentationStyle{
        return .none
    }
}
