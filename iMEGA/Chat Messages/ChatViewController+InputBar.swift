import Foundation
import MessageKit

extension ChatViewController {
    
    // MARK: - Overriden properties
    
    override var inputAccessoryView: UIView? {
        guard !isEditing else {
            return nil
        }
        
        if let chatRoom = chatRoom,
            chatRoom.isPublicChat,
            chatRoom.isPreview,
            !chatRoomDelegate.hasChatRoomClosed {
            return joinInputBar
        } else if chatRoom.ownPrivilege.rawValue <= MEGAChatRoomPrivilege.ro.rawValue {
            return nil
        } else if chatInputBar == nil {
            chatInputBar = ChatInputBar()
            chatInputBar?.delegate = self
        }
        
        return chatInputBar
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    // MARK: - Private properties

    private var joinInputBar: JoinInputBar {
        let joinInputBar = JoinInputBar.instanceFromNib
        joinInputBar.buttonTappedHandler = { [weak self] button in
            self?.join(button: button)
        }
        return joinInputBar
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
    
    func replaceCurrentViewController(withViewController viewController: UIViewController,
                                      animated: Bool = true) {
        guard let navController = navigationController else {
            fatalError("No navigation controller in the stack to push")
        }
        
        navController.pushViewController(viewController, animated: animated)
        var viewControllers = navController.viewControllers
        viewControllers.remove(at: viewControllers.count - 2)
        navController.viewControllers = viewControllers
    }
    
    // MARK: - Private methods.
    
    private func join(button: UIButton) {
        if MEGASdkManager.sharedMEGAChatSdk()!.initState() == .anonymous {
            MEGALinkManager.secondaryLinkURL = publicChatLink
            MEGALinkManager.selectedOption = .joinChatLink
            dismissChatRoom()
        } else {
            let delegate = MEGAChatGenericRequestDelegate { (request, error) in
                let chatViewController = ChatViewController()
                chatViewController.chatRoom = MEGASdkManager.sharedMEGAChatSdk()!.chatRoom(forChatId: request.chatHandle)
                self.closeChatRoom()
                self.replaceCurrentViewController(withViewController: chatViewController, animated: false)
                button.isEnabled = true
            }
            MEGASdkManager.sharedMEGAChatSdk()?.autojoinPublicChat(chatRoom.chatId,
                                                                   delegate: delegate)
            button.isEnabled = false
        }
    }
    
    private func displayAddToChatViewController(_ button: UIButton) {
        addToChatViewController = AddToChatViewController(nibName: nil, bundle: nil)
        
        guard let addToChatViewController = addToChatViewController else {
            fatalError("Could not create an instance of AddToChatViewController class")
        }
        
        addToChatViewController.addToChatDelegate = self
        
        chatInputBar?.dismissKeyboard()

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
                            SVProgressHUD.setDefaultMaskType(.none)
                            SVProgressHUD.dismiss()
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
        SVProgressHUD.setDefaultMaskType(.none)
        SVProgressHUD.dismiss()
    }
    
    private func createUploadTransferDelegate() -> MEGAStartUploadTransferDelegate {
        return MEGAStartUploadTransferDelegate(toUploadToChatWithTotalBytes: { [weak self] (transfer) in
            guard let `self` = self,
                let transfer = transfer else {
                return
            }
            
            let totalBytes = transfer.totalBytes.doubleValue
            self.totalBytesToUpload += totalBytes
            self.remainingBytesToUpload += totalBytes
        }, progress: {  [weak self] (transfer) in
            guard let `self` = self,
                let transfer = transfer  else {
                    return
            }
            
            let transferredBytes = transfer.transferredBytes.doubleValue
            let totalBytes = transfer.totalBytes.doubleValue
            let asignableProgresRegardWithTotal = totalBytes / self.totalBytesToUpload
            let transferProgress = transferredBytes / totalBytes
            var currentAsignableProgressForThisTransfer = transferProgress * asignableProgresRegardWithTotal
            if (currentAsignableProgressForThisTransfer < asignableProgresRegardWithTotal) {
                if (self.totalProgressOfTransfersCompleted != 0) {
                    currentAsignableProgressForThisTransfer += self.totalProgressOfTransfersCompleted
                }
                
//                if (currentAsignableProgressForThisTransfer > Double(self.navigationBarProgressView.progress)) {
////                    self.navigationBarProgressView.setProgress(Float(currentAsignableProgressForThisTransfer), animated: true)
//                }
            }
        }, completion: { [weak self] (transfer) in
            guard let `self` = self else {
                return
            }
            
            let totalBytes = transfer!.totalBytes.doubleValue
            let progressCompletedRegardWithTotal = totalBytes / self.totalBytesToUpload
            self.totalProgressOfTransfersCompleted += progressCompletedRegardWithTotal
            self.remainingBytesToUpload -= totalBytes
            
            if self.remainingBytesToUpload == 0 {
//                self.navigationBarProgressView.progress = 0
//                self.navigationBarProgressView.isHidden = true
                self.totalBytesToUpload = 0.0
                self.totalProgressOfTransfersCompleted = 0.0;
            }
        })
    }
    
    private func uploadAsset(withFilePath filePath: String, parentNode: MEGANode, localIdentifier: String) {
        var appData: String? = nil
        
        if let cordinates = (filePath as NSString).mnz_coordinatesOfPhotoOrVideo() {
            appData = NSString().mnz_appData(toSaveCoordinates: cordinates)
        }
                                            
        appData = ((appData ?? "") as NSString).mnz_appDataToAttach(toChatID: self.chatRoom.chatId, asVoiceClip: false)
        appData = ((appData ?? "") as NSString).mnz_appData(toLocalIdentifier: localIdentifier)

        MEGASdkManager.sharedMEGASdk()!.startUpload(withLocalPath: filePath,
                                                    parent: parentNode,
                                                    appData: appData,
                                                    isSourceTemporary: true,
                                                    delegate: self.createUploadTransferDelegate())
    }
    
    private func uploadVideo(withFilePath path: String, parentNode: MEGANode) {
        let videoURL = URL(fileURLWithPath: NSHomeDirectory().append(pathComponent: path))
        
        let processAsset = MEGAProcessAsset(toShareThroughChatWithVideoURL: videoURL,
                                            parentNode: parentNode,
                                            filePath: { [weak self] path in
            guard let filePath = path,
                let `self` = self else {
                MEGALogDebug("Video processing `MEGAProcessAsset` issue with file path as nil")
                return
            }
            
            self.uploadAsset(withFilePath: filePath, parentNode: parentNode, localIdentifier: "")
        }, node: nil) { [weak self] error in
            guard let `self` = self else {
                return
            }
            
            let title = AMLocalizedString("error");
            let message = error?.localizedDescription
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: AMLocalizedString("ok"), style: .cancel, handler: nil))
            
            DispatchQueue.main.async {
                self.present(alertController, animated: true, completion: nil)
            }
        }
        
        processAsset?.prepare()
    }
}

extension ChatViewController: ChatInputBarDelegate {
    
    func tappedAddButton(_ button: UIButton) {
        displayAddToChatViewController(button)
    }
    
    func tappedSendButton(withText text: String) {
        MEGASdkManager.sharedMEGAChatSdk()?.sendStopTypingNotification(forChat: chatRoom.chatId)
        
        if let editMessage = editMessage {
            let messageId = (editMessage.message.status == .sending) ? editMessage.message.temporalId : editMessage.message.messageId
            
            if editMessage.message.content != text,
                let message = MEGASdkManager.sharedMEGAChatSdk()?.editMessage(forChat: chatRoom.chatId, messageId: messageId, message: text) {
                message.chatId = chatRoom.chatId
                
                if let index = messages.firstIndex(of: editMessage),
                    index != NSNotFound {
                    chatRoomDelegate.chatMessage[index] = ChatMessage(message: message, chatRoom: chatRoom)
                    messagesCollectionView.reloadDataAndKeepOffset()
                }
            }
            
            self.editMessage = nil
        } else if let message = MEGASdkManager.sharedMEGAChatSdk()?.sendMessage(toChat: chatRoom.chatId, message: text) {
            chatRoomDelegate.insertMessage(message)
        }
    }
    
    func tappedSendAudio(atPath path: String) {
        MEGASdkManager.sharedMEGASdk()!.getMyChatFilesFolder {[weak self] result in
            guard let `self` = self else {
                return
            }
                        
            let appData = ("" as NSString).mnz_appDataToAttach(toChatID: self.chatRoom.chatId, asVoiceClip: true)
            
            if let voiceMessagesNode = MEGASdkManager.sharedMEGASdk()!.node(forPath: MEGAVoiceMessagesFolderName, node: result) {
                MEGASdkManager.sharedMEGASdk()!.startUpload(withLocalPath: path,
                                                            parent: voiceMessagesNode,
                                                            appData: appData,
                                                            isSourceTemporary: true,
                                                            delegate: self.createUploadTransferDelegate())
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
                                                                    delegate: self.createUploadTransferDelegate())
                        
                    } else {
                        MEGALogDebug("Voice folder not created")
                    }
                }
                
                MEGASdkManager.sharedMEGASdk()!.createFolder(withName: MEGAVoiceMessagesFolderName,
                                                             parent: result,
                                                             delegate: requestDelegate)
            }
        }
    }
    
    func tappedVoiceButton() {
        showTapAndHoldMessage()
    }
    
    func typing(withText text: String) {
        if text.isEmpty {
            MEGASdkManager.sharedMEGAChatSdk()?.sendStopTypingNotification(forChat: chatRoom.chatId)
            if sendTypingTimer != nil {
                self.sendTypingTimer?.invalidate()
                self.sendTypingTimer = nil
            }
        } else if !text.isEmpty && sendTypingTimer == nil {
            sendTypingTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { [weak self] _ in
                guard let `self` = self,
                    let timer = self.sendTypingTimer else {
                    return
                }
                
                timer.invalidate()
                self.sendTypingTimer = nil
            }
            MEGASdkManager.sharedMEGAChatSdk()?.sendTypingNotification(forChat: chatRoom.chatId)
        }
    }
    
    func showTapAndHoldMessage() {
        let myViews = view.subviews.filter { $0 is TapAndHoldMessageView }
        guard let inputAccessoryView = inputAccessoryView,
            myViews.count == 0  else {
            return
        }
        
        let tapAndHoldMessageView = TapAndHoldMessageView.instanceFromNib
        tapAndHoldMessageView.add(toView: view, bottom: inputAccessoryView.frame.height)
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
        MEGASdkManager.sharedMEGASdk()!.getMyChatFilesFolder {[weak self] resultNode in
            guard let `self` = self else {
                return
            }
            
            let processAsset = MEGAProcessAsset(toShareThroughChatWith: [asset],
                                                parentNode: resultNode,
                                                filePaths: { [weak self] filePaths in
                
                guard let filePath = filePaths?.first,
                    let `self` = self else {
                    return
                }
                self.uploadAsset(withFilePath: filePath, parentNode: resultNode, localIdentifier: asset.localIdentifier)
            }, nodes:nil) { errors in
                guard let errors = errors else {
                    return
                }
                
                var message: String?
                
                if let error = errors.first,
                    errors.count == 1 {
                    message = error.localizedDescription
                } else {
                    message = AMLocalizedString("shareExtensionUnsupportedAssets")
                }
                
                let alertController = UIAlertController(title: AMLocalizedString("error"),
                                                        message: message,
                                                        preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: AMLocalizedString("ok"),
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
        let pickerController = MEGAImagePickerController(toShareThroughChatWith: .camera) { [weak self] (filePath, sourceType, node) in
            guard let path = filePath,
                let parentNode = node,
                let `self` = self else {
                    return
            }
            
            if (path as NSString).mnz_isImagePathExtension  {
                self.uploadAsset(withFilePath: path, parentNode: parentNode, localIdentifier: "")
            } else if (path as NSString).mnz_isVideoPathExtension {
                self.uploadVideo(withFilePath: path, parentNode: parentNode)
            } else {
                MEGALogDebug("showCamera: Unknown media type found and cannot be uploaded.")
            }
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
        chatInputBar?.voiceRecordingViewEnabled = true
    }
    
    func showContacts() {
        guard let (contactsNavigationController, contactsViewController) = createContactsViewController() else {
            return
        }
            
        contactsViewController.contactsMode = .chatAttachParticipant

        contactsViewController.userSelected = { [weak self] users in
            guard let `self` = self else {
                return
            }
            
            if let message = MEGASdkManager.sharedMEGAChatSdk()?.attachContacts(toChat: self.chatRoom.chatId,
                                                                                contacts: users) {
                self.chatRoomDelegate.insertMessage(message)
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
                
                let cancelAction = UIAlertAction(title: AMLocalizedString("cancel"), style: .cancel, handler: nil)
                
                let continueAction = UIAlertAction(title: AMLocalizedString("continue"), style: .default) { _ in
                    let enableGeolocationDelegate = MEGAGenericRequestDelegate { (request, error) in
                        if error.type != .apiOk {
                            let alertTitle = AMLocalizedString("error")
                            let alertMessage = String(format: "Enable geolocation failed. Error: %@", error.name)
                            
                            let enableGeolocationAlertAction = UIAlertAction(title: AMLocalizedString("ok"),
                                                                             style: .default,
                                                                             handler: nil)
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
    
    func shouldDisableAudioMenu() -> Bool {
        return shouldDisableAudioVideoCall
    }
    
    func shouldDisableVideoMenu() -> Bool {
        guard !chatRoom.isGroup else {
            return true
        }
        
        return shouldDisableAudioVideoCall
    }
    
    func canRecordAudio() -> Bool {
        guard let chatSDK = MEGASdkManager.sharedMEGAChatSdk() else {
            return false
        }
        
        if chatSDK.mnz_existsActiveCall {
            let message = AMLocalizedString("It is not possible to record voice messages while there is a call in progress", "Message shown when there is an ongoing call and the user tries to record a voice message")
            SVProgressHUD.setDefaultMaskType(.clear)
            SVProgressHUD.showError(withStatus: message)
            return false
        }
        
        return true
    }
    
    func didDisplayVoiceRecordingView() {
        messagesCollectionView.isScrollEnabled = false
    }
    
    func didHideVoiceRecordingView() {
        messagesCollectionView.isScrollEnabled = true
    }
}

extension ChatViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController,
                                   traitCollection: UITraitCollection) -> UIModalPresentationStyle{
        return .none
    }
}
