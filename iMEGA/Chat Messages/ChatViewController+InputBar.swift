import Foundation
import MessageKit
import ISEmojiView

extension ChatViewController {
    
    // MARK: - Overriden properties
    
    override var inputAccessoryView: UIView? {
        guard !isEditing else {
            return nil
        }
           
        if let chatRoom = chatRoom,
            chatRoom.isPublicChat,
            chatRoom.isPreview,
        !chatRoomDelegate.hasChatRoomClosed || MEGALinkManager.joiningOrLeavingChatBase64Handles.contains(MEGASdk.base64Handle(forUserHandle: chatRoom.chatId)) {
            return joinInputBar
        } else if chatRoom.ownPrivilege.rawValue <= MEGAChatRoomPrivilege.ro.rawValue || previewMode {
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
    
    func updateJoinView() {
        var newState: JoinViewState
        if MEGALinkManager.joiningOrLeavingChatBase64Handles.contains(MEGASdk.base64Handle(forUserHandle: chatRoom.chatId)) {
            newState = chatRoom.ownPrivilege.rawValue <= MEGAChatRoomPrivilege.ro.rawValue ? .joining : .leaving
        } else {
            newState = .default
        }
        
        joinInputBar.setJoinViewState(newState: newState)
        
    }

    // MARK: - Interface methods.
    
     func present(viewController: UIViewController) {
        if let rc = UIApplication.shared.keyWindow?.rootViewController {
            if let tabBarController = rc as? UITabBarController,
                !tabBarController.tabBar.isHidden {
                tabBarController.tabBar.isHidden = true
                
                rc.present(viewController, animated: true) {
                    if let tabBarController = rc as? UITabBarController {
                        tabBarController.tabBar.isHidden = false
                    }
                }
            } else {
                rc.present(viewController, animated: true)
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

    func loadDraft() {
        if let chatInputBar = inputAccessoryView as? ChatInputBar,
            let text = MEGAStore.shareInstance()?.fetchChatDraft(withChatId: chatRoom.chatId)?.text,
            !text.isEmpty {
            chatInputBar.set(text: text, showKeyboard: false)
        }
    }
    
    func saveDraft() {
        guard let chatInputBar = inputAccessoryView as? ChatInputBar else {
            return
        }
        
        MEGAStore.shareInstance()?.insertOrUpdateChatDraft(withChatId: chatRoom.chatId, text: (editMessage != nil) ? "" : chatInputBar.text)
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
                MEGALinkManager.joiningOrLeavingChatBase64Handles.remove(MEGASdk.base64Handle(forUserHandle: self.chatRoom.chatId))
                self.updateJoinView()

            }
            MEGASdkManager.sharedMEGAChatSdk()?.autojoinPublicChat(chatRoom.chatId,
                                                                   delegate: delegate)
            if let handle = MEGASdk.base64Handle(forUserHandle: chatRoom.chatId) {
                MEGALinkManager.joiningOrLeavingChatBase64Handles.add(handle)
            }
            updateJoinView()
            button.isEnabled = false
        }
    }
    
    private func displayAddToChatViewController(_ button: UIButton) {
        addToChatViewController = AddToChatViewController(nibName: nil, bundle: nil)
        
        guard let addToChatViewController = addToChatViewController else {
            fatalError("Could not create an instance of AddToChatViewController class")
        }
        
        addToChatViewController.addToChatDelegate = self
        addToChatViewController.dismissHandler = { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.adjustMessageCollectionBottomInset()
        }
        
        chatInputBar?.dismissKeyboard()

        if UIDevice.current.iPadDevice {
            let navController = MEGANavigationController(rootViewController: addToChatViewController)
            navController.navigationBar.isTranslucent = false
            navController.addLeftDismissButton(withText: AMLocalizedString("cancel"))
            navController.modalPresentationStyle = .popover

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
    
    // This method has be added to overcome this issue. https://github.com/MessageKit/MessageKit/issues/993
    // The fix is suppose to be added in the milestone https://github.com/MessageKit/MessageKit/milestone/22
    // Once Messagekit 4.0 is released try removing this method.
    private func adjustMessageCollectionBottomInset() {
        guard let accessoryView = inputAccessoryView,
            let window = view.window else {
                return
        }
        
        var collectionViewInset = accessoryView.frame.height
        if #available(iOS 11.0, *) {
            collectionViewInset -= window.safeAreaInsets.bottom
        }
        
        if messagesCollectionView.contentInset.bottom != collectionViewInset {
            var oldInset = messagesCollectionView.contentInset.bottom
            if #available(iOS 11.0, *) {
                oldInset = messagesCollectionView.adjustedContentInset.bottom
            }
            
            messagesCollectionView.contentInset.bottom = collectionViewInset
            messagesCollectionView.scrollIndicatorInsets.bottom = collectionViewInset
            
            var contentOffset = messagesCollectionView.contentOffset
            contentOffset.y += (messagesCollectionView.contentInset.bottom + oldInset)
            messagesCollectionView.contentOffset = contentOffset
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
        guard let selectedUsers = selectedObjects as? [MEGAUser] else {
            return
        }
        
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show()

        let peerlist = MEGAChatPeerList()
        selectedUsers.forEach { peerlist.addPeer(withHandle: $0.handle, privilege: 2)}
        
        if keyRotationEnabled {
            MEGASdkManager.sharedMEGAChatSdk()?.mnz_createChatRoom(usersArray: selectedUsers,
                                                                   title: groupName) {
                                                                    newChatRoom in
                                                                    self.open(chatRoom: newChatRoom)
            }
        } else {
            let createChatGroupRequestDelegate = MEGAChatGenericRequestDelegate { request, error in
                let newChatRoom = MEGASdkManager.sharedMEGAChatSdk()?.chatRoom(forChatId: request.chatHandle)
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
        return MEGAStartUploadTransferDelegate(toUploadToChatWithTotalBytes: nil, progress: nil, completion: nil)
    }
    
    private func uploadAsset(withFilePath filePath: String, parentNode: MEGANode, localIdentifier: String) {
        var appData: String? = nil
        
        if let cordinates = (filePath as NSString).mnz_coordinatesOfPhotoOrVideo() {
            appData = NSString().mnz_appData(toSaveCoordinates: cordinates)
        }
                                            
        appData = ((appData ?? "") as NSString).mnz_appDataToAttach(toChatID: self.chatRoom.chatId, asVoiceClip: false)
        appData = ((appData ?? "") as NSString).mnz_appData(toLocalIdentifier: localIdentifier)
        
        ChatUploader.sharedInstance.upload(filepath: filePath,
                                           appData: appData ?? "",
                                           chatRoomId: chatRoom.chatId,
                                           parentNode: parentNode,
                                           isSourceTemporary: false,
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
            
            let title = AMLocalizedString("error")
            let message = error?.localizedDescription
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: AMLocalizedString("ok"), style: .cancel, handler: nil))
            
            DispatchQueue.main.async {
                self.present(alertController, animated: true, completion: nil)
            }
        }
        
        processAsset?.prepare()
    }
    
    private func startUpload(assets: [PHAsset]) {
        MEGASdkManager.sharedMEGASdk()!.getMyChatFilesFolder {[weak self] resultNode in
            guard let `self` = self else {
                return
            }
            
            let processAsset = MEGAProcessAsset(toShareThroughChatWith: assets,
                                                parentNode: resultNode,
                                                filePaths: { [weak self] filePaths in
                
                guard let `self` = self,
                    let filePaths = filePaths else {
                    return
                }
                                                    
                filePaths.enumerated().forEach { (index, filePath) in
                    self.uploadAsset(withFilePath: filePath, parentNode: resultNode, localIdentifier: assets[index].localIdentifier)
                }
                
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
                                
                let firstIndex = messages.firstIndex { message -> Bool in
                    guard let chatMessage = message as? ChatMessage else {
                        return false
                    }
                    
                    return chatMessage == editMessage
                }
                
                if let index = firstIndex,
                    index != NSNotFound {
                    chatRoomDelegate.chatMessages[index] = ChatMessage(message: message, chatRoom: chatRoom)
                    messagesCollectionView.reloadDataAndKeepOffset()
                }
            }
            
            self.editMessage = nil
        } else if let message = MEGASdkManager.sharedMEGAChatSdk()?.sendMessage(toChat: chatRoom.chatId, message: text) {
            chatRoomDelegate.insertMessage(message, scrollToBottom: true)
            chatRoomDelegate.updateUnreadMessagesLabel(unreads: 0)
        }
    }
    
    func tappedSendAudio(atPath path: String) {
        MEGASdkManager.sharedMEGASdk()!.getMyChatFilesFolder {[weak self] result in
            guard let `self` = self else {
                return
            }
                        
            let appData = ("" as NSString).mnz_appDataToAttach(toChatID: self.chatRoom.chatId, asVoiceClip: true)
            
            if let voiceMessagesNode = MEGASdkManager.sharedMEGASdk()!.node(forPath: MEGAVoiceMessagesFolderName, node: result) {
                ChatUploader.sharedInstance.upload(filepath: path,
                                                   appData: appData,
                                                   chatRoomId: self.chatRoom.chatId,
                                                   parentNode: voiceMessagesNode,
                                                   isSourceTemporary: true,
                                                   delegate: self.createUploadTransferDelegate())
            } else {
                let requestDelegate: MEGARequestDelegate = MEGACreateFolderRequestDelegate { request in
                    guard let request = request else {
                        fatalError("request object should not be nil")
                    }
                    
                    if let voiceMessagesNode = MEGASdkManager.sharedMEGASdk()!.node(forHandle: request.nodeHandle) {
                        ChatUploader.sharedInstance.upload(filepath: path,
                                                           appData: appData,
                                                           chatRoomId: self.chatRoom.chatId,
                                                           parentNode: voiceMessagesNode,
                                                           isSourceTemporary: false,
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
        if !isAudioPermissionAuthorized() {
            return
        }
        
        showTapAndHoldMessage()
    }
    
    func updateTypingIndicatorView(withAttributedString attributedString: NSAttributedString?) {
        guard let chatInputBar = inputAccessoryView as? ChatInputBar else {
            return
        }
        
        chatInputBar.setTypingIndicator(text: attributedString)
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
    
    func textDidEndEditing() {
        saveDraft()
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
        startUpload(assets: [asset])
    }
    
    func loadPhotosView() {
        let selectionActionText = AMLocalizedString("Send (%d)", "Used in Photos app browser view to send the photos from the view to the chat.")
        let selectionActionDisabledText = AMLocalizedString("send", "Used in Photos app browser view as a disabled action when there is no assets selected")
        let albumTableViewController = AlbumsTableViewController(selectionActionText: selectionActionText,
                                                                 selectionActionDisabledText: selectionActionDisabledText) { [weak self] assets in
                                                                    guard let `self` = self else {
                                                                        return
                                                                    }
                                                                    
                                                                    self.startUpload(assets: assets)
        }
        
        let navigationController = MEGANavigationController(rootViewController: albumTableViewController)
        present(viewController: navigationController)
    }
    
    func showCamera() {
        guard let pickerController = MEGAImagePickerController(toShareThroughChatWith: .camera,
                                                               filePathCompletion: { [weak self] (filePath, sourceType, node) in
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
        }) else {
            MEGALogDebug("Could not load Image Picker view")
            return
        }
        
        present(viewController: pickerController)
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
        contactsViewController.createGroupChat = { [weak self] in
            self?.createGroupChat(selectedObjects: $0, groupName: $1, keyRotationEnabled: $2, getChatLink: $3)
        }
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
        
        if !isAudioPermissionAuthorized() {
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
    
    private func isAudioPermissionAuthorized() -> Bool {
        switch DevicePermissionsHelper.audioPermissionAuthorizationStatus() {
        case .notDetermined:
            DevicePermissionsHelper.audioPermissionModal(false, forIncomingCall: false, withCompletionHandler: nil)
            return false
        case .restricted, .denied:
            DevicePermissionsHelper.alertAudioPermission(forIncomingCall: false)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return false
        default:
            return true
        }
    }
}

extension ChatViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController,
                                   traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
