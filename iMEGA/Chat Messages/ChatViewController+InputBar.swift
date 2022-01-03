import Foundation
import MessageKit
import ISEmojiView
import VisionKit

extension ChatViewController {
    
    // MARK: - Overriden properties
    
    override var inputAccessoryView: UIView? {
        guard !isEditing else {
            return nil
        }
           
        if chatRoom.isPublicChat,
            chatRoom.isPreview,
            !chatRoomDelegate.hasChatRoomClosed || MEGALinkManager.joiningOrLeavingChatBase64Handles.contains(MEGASdk.base64Handle(forUserHandle: chatRoom.chatId) ?? "") {
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
        if MEGALinkManager.joiningOrLeavingChatBase64Handles.contains(MEGASdk.base64Handle(forUserHandle: chatRoom.chatId) ?? "") {
            newState = chatRoom.ownPrivilege.rawValue <= MEGAChatRoomPrivilege.ro.rawValue ? .joining : .leaving
        } else {
            newState = .default
        }
        
        joinInputBar.setJoinViewState(newState: newState)
        
    }

    // MARK: - Interface methods.
    
    func dismissKeyboardIfRequired() {
        if let input = inputAccessoryView as? ChatInputBar,
           input.isTextViewTheFirstResponder() {
            input.dismissKeyboard()
        }
    }
    
    func present(viewController: UIViewController, animated: Bool = true, dismissKeyboard: Bool = true) {
        if dismissKeyboard {
            dismissKeyboardIfRequired()
        }
        
        if let tabBarController = UIApplication.shared.keyWindow?.rootViewController as? UITabBarController,
           !tabBarController.tabBar.isHidden {
            tabBarController.tabBar.isHidden = true
            
            tabBarController.present(viewController, animated: animated) {
                tabBarController.tabBar.isHidden = false
            }
        } else {
            present(viewController, animated: animated)
        }
    }
    
    func replaceCurrentViewController(withViewController viewController: UIViewController,
                                      animated: Bool = true) {
        guard let navController = navigationController else {
            MEGALogDebug("Chat: No navigation controller in the stack to push")
            return
        }
        
        navController.pushViewController(viewController, animated: animated)
        var viewControllers = navController.viewControllers
        viewControllers.remove(at: viewControllers.count - 2)
        navController.viewControllers = viewControllers
    }

    func loadDraft() {
        if let chatInputBar = inputAccessoryView as? ChatInputBar,
            let text = MEGAStore.shareInstance().fetchChatDraft(withChatId: chatRoom.chatId)?.text,
            !text.isEmpty {
            chatInputBar.set(text: text, showKeyboard: false)
        }
    }
    
    func saveDraft() {
        guard let chatInputBar = inputAccessoryView as? ChatInputBar else {
            return
        }
        
        MEGAStore.shareInstance().insertOrUpdateChatDraft(withChatId: chatRoom.chatId, text: (editMessage != nil) ? "" : (chatInputBar.text ?? ""))
    }
    
    func presentShareLocation(editing:Bool = false) {
        let storyboard = UIStoryboard(name: "Chat", bundle: nil)
        guard let shareLocationViewController = storyboard.instantiateViewController(withIdentifier: "ShareLocationViewControllerID") as? ShareLocationViewController else {
            fatalError("ChatViewController: could not create an instance of ShareLocationViewController")
        }
        
        shareLocationViewController.chatRoom = chatRoom
        
        if editing, let editMessage = self.editMessage {
            shareLocationViewController.editMessage = editMessage.message
            self.editMessage = nil
        }
            
        let navController = MEGANavigationController(rootViewController: shareLocationViewController)
        navController.addLeftDismissButton(withText: Strings.Localizable.cancel)
        present(viewController: navController)
    }
    
    // MARK: - Private methods.
    private func join(button: UIButton) {
        if MEGASdkManager.sharedMEGAChatSdk().initState() == .anonymous {
            MEGALinkManager.secondaryLinkURL = publicChatLink
            MEGALinkManager.selectedOption = .joinChatLink
            dismissChatRoom()
        } else {
            let delegate = MEGAChatGenericRequestDelegate { (request, error) in
                guard let chatRoom = MEGASdkManager.sharedMEGAChatSdk().chatRoom(forChatId: request.chatHandle) else {
                    MEGALogDebug("ChatRoom not found with chat handle \(request.chatHandle)")
                    return
                }
                let chatViewController = ChatViewController(chatRoom: chatRoom)
                self.closeChatRoom()
                self.replaceCurrentViewController(withViewController: chatViewController, animated: false)
                button.isEnabled = true
                MEGALinkManager.joiningOrLeavingChatBase64Handles.remove(MEGASdk.base64Handle(forUserHandle: self.chatRoom.chatId) ?? "")
                self.updateJoinView()

            }
            MEGASdkManager.sharedMEGAChatSdk().autojoinPublicChat(chatRoom.chatId, delegate: delegate)
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
            
            self.addToChatViewController = nil
        }
        
        chatInputBar?.dismissKeyboard()

        if UIDevice.current.iPadDevice {
            let navController = MEGANavigationController(rootViewController: addToChatViewController)
            navController.navigationBar.isTranslucent = false
            navController.addLeftDismissButton(withText: Strings.Localizable.cancel)
            navController.modalPresentationStyle = .popover

            if let popover = navController.popoverPresentationController {
                popover.delegate = self

                popover.sourceView = button
                popover.sourceRect = button.bounds

                present(navController, animated: true, completion: nil)
            }
        } else {
            addToChatViewController.transitioningDelegate = self
            if UIDevice.current.deviceName() == "iPhone SE 1st" , #available(iOS 14.0, *) {
                // to fix https://testrail.systems.mega.nz/index.php?/tests/view/1052975
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.present(viewController: addToChatViewController)
                }
            } else {
                present(viewController: addToChatViewController)
            }
            
        }
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
            MEGASdkManager.sharedMEGAChatSdk().mnz_createChatRoom(usersArray: selectedUsers,
                                                                   title: groupName) {
                                                                    newChatRoom in
                                                                    self.open(chatRoom: newChatRoom)
            }
        } else {
            let createChatGroupRequestDelegate = MEGAChatGenericRequestDelegate { request, error in
                guard let newChatRoom = MEGASdkManager.sharedMEGAChatSdk().chatRoom(forChatId: request.chatHandle) else {
                    MEGALogDebug("Cannot find chatRoom chat id \(request.chatHandle)")
                    return
                }
                if getChatLink {
                    let genericRequestDelegate = MEGAChatGenericRequestDelegate { (request, error) in
                        if error.type == .MEGAChatErrorTypeOk {
                            let chatViewController = ChatViewController(chatRoom: newChatRoom)
                            chatViewController.publicChatWithLinkCreated = true
                            chatViewController.publicChatLink = URL(string: request.text)
                            self.replaceCurrentViewController(withViewController: chatViewController)
                            SVProgressHUD.setDefaultMaskType(.none)
                            SVProgressHUD.dismiss()
                        }
                    }
                    
                    MEGASdkManager.sharedMEGAChatSdk().createChatLink(newChatRoom.chatId, delegate: genericRequestDelegate)
                } else {
                    self.open(chatRoom: newChatRoom)
                }
            }
            MEGASdkManager.sharedMEGAChatSdk().createPublicChat(withPeers: peerlist,
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
    
    private func open(chatRoom: MEGAChatRoom) {
        let chatViewController = ChatViewController(chatRoom: chatRoom)
        replaceCurrentViewController(withViewController: chatViewController)
        SVProgressHUD.setDefaultMaskType(.none)
        SVProgressHUD.dismiss()
    }
    
    private func postMessageSentAccessibilityNotification() {
        postAccessibilityNotification(message: Strings.Localizable.messageSent)
    }
    
    private func postAccessibilityNotification(message: String) {
        guard UIAccessibility.isVoiceOverRunning else { return }
        UIAccessibility.post(notification: .announcement, argument: message)
    }
    
    private func createUploadTransferDelegate() -> MEGAStartUploadTransferDelegate {
        return MEGAStartUploadTransferDelegate(toUploadToChatWithTotalBytes: nil, progress: nil) { [weak self] transfer in
            guard let self = self, let state = transfer?.state else { return }
            
            switch state {
            case .complete:
                self.postMessageSentAccessibilityNotification()
            case .failed:
                self.postAccessibilityNotification(message: Strings.Localizable.failedToSendTheMessage)
            case .cancelled:
                self.postAccessibilityNotification(message: Strings.Localizable.messageSendingCancelled)
            default:
                break
            }
        }
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
        }) { [weak self] error in
            guard let `self` = self else {
                return
            }
            
            let title = Strings.Localizable.error
            let message = error?.localizedDescription
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: Strings.Localizable.ok, style: .cancel, handler: nil))
            
            DispatchQueue.main.async {
                self.present(viewController: alertController)
            }
        }
        
        processAsset?.prepare()
    }
    
    private func startUpload(assets: [PHAsset]) {
        MyChatFilesFolderNodeAccess.shared.loadNode { [weak self] myChatFilesFolderNode, error in
            guard let myChatFilesFolderNode = myChatFilesFolderNode, let `self` = self else {
                if let error = error {
                    MEGALogWarning("Could not load MyChatFiles target folder due to error \(error.localizedDescription)")
                }
                return
            }
            
            let processAsset = MEGAProcessAsset(toShareThroughChatWith: assets,
                                                parentNode: myChatFilesFolderNode,
                                                filePaths: { [weak self] filePaths in
                
                guard let `self` = self,
                    let filePaths = filePaths else {
                    return
                }
                                                    
                filePaths.enumerated().forEach { (index, filePath) in
                    self.uploadAsset(withFilePath: filePath, parentNode: myChatFilesFolderNode, localIdentifier: assets[index].localIdentifier)
                }
                
            }) { errors in
                guard let errors = errors else {
                    return
                }
                
                var message: String?
                
                if let error = errors.first,
                    errors.count == 1 {
                    message = error.localizedDescription
                } else {
                    message = Strings.Localizable.shareExtensionUnsupportedAssets
                }
                
                let alertController = UIAlertController(title: Strings.Localizable.error,
                                                        message: message,
                                                        preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: Strings.Localizable.ok,
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
    func didPasteImage(_ image: UIImage) {
        let router = PasteImagePreviewRouter(viewControllerToPresent: self, chatRoom: chatRoom)
        router.start()
    }
    
    func tappedAddButton(_ button: UIButton) {
        displayAddToChatViewController(button)
        audioController.stopAnyOngoingPlaying()
    }
    
    func clearEditMessage() {
        editMessage = nil
    }
    
    func tappedSendButton(withText text: String) {
        MEGASdkManager.sharedMEGAChatSdk().sendStopTypingNotification(forChat: chatRoom.chatId)
        
        if let editMessage = editMessage {
            let messageId = (editMessage.message.status == .sending) ? editMessage.message.temporalId : editMessage.message.messageId
            
            if editMessage.message.content != text,
                let message = MEGASdkManager.sharedMEGAChatSdk().editMessage(forChat: chatRoom.chatId, messageId: messageId, message: text) {
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
                    postMessageSentAccessibilityNotification()
                }
                checkDialogs(message)
            }
            
            self.editMessage = nil
        } else if let message = MEGASdkManager.sharedMEGAChatSdk().sendMessage(toChat: chatRoom.chatId, message: text) {
            chatRoomDelegate.updateUnreadMessagesLabel(unreads: 0)
            chatRoomDelegate.insertMessage(message, scrollToBottom: true)
            checkDialogs(message)
            // Message sent voice over message overlaps with the send button dimmed and stops announcing. So delaying the message sent message.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.postMessageSentAccessibilityNotification()
            }
        }
    }
    
    func checkDialogs(_ message: MEGAChatMessage) {
        if MEGAChatSdk.hasUrl(message.content) {
            MEGASdkManager.sharedMEGASdk().shouldShowRichLinkWarning(with: MEGAGetAttrUserRequestDelegate(completion: { (request) in
                if let request = request, request.flag {
                    message.warningDialog = (request.number.intValue >= 3 ? MEGAChatMessageWarningDialog.standard : MEGAChatMessageWarningDialog.initial)
                    self.richLinkWarningCounterValue = request.number.uintValue
                    self.chatRoomDelegate.updateMessage(message)
                }
            }, error: { (request, error) in
                if let request = request, request.flag {
                    message.warningDialog = (request.number.intValue >= 3 ? MEGAChatMessageWarningDialog.standard : MEGAChatMessageWarningDialog.initial)
                    self.richLinkWarningCounterValue = request.number.uintValue
                    self.chatRoomDelegate.updateMessage(message)

                }
            }))
        }
    }
    
    func tappedSendAudio(atPath path: String) {
        MyChatFilesFolderNodeAccess.shared.loadNode { [weak self] myChatFilesFolderNode, error in
            guard let myChatFilesFolderNode = myChatFilesFolderNode, let `self` = self else {
                if let error = error {
                    MEGALogWarning("Could not load MyChatFiles target folder due to error \(error.localizedDescription)")
                }
                return
            }
                        
            let appData = ("" as NSString).mnz_appDataToAttach(toChatID: self.chatRoom.chatId, asVoiceClip: true)
            
            if let voiceMessagesNode = MEGASdkManager.sharedMEGASdk().node(forPath: MEGAVoiceMessagesFolderName, node: myChatFilesFolderNode) {
                ChatUploader.sharedInstance.upload(filepath: path,
                                                   appData: appData,
                                                   chatRoomId: self.chatRoom.chatId,
                                                   parentNode: voiceMessagesNode,
                                                   isSourceTemporary: false,
                                                   delegate: self.createUploadTransferDelegate())
            } else {
                let requestDelegate: MEGARequestDelegate = MEGACreateFolderRequestDelegate { request in
                    guard let request = request else {
                        fatalError("request object should not be nil")
                    }
                    
                    if let voiceMessagesNode = MEGASdkManager.sharedMEGASdk().node(forHandle: request.nodeHandle) {
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
                
                MEGASdkManager.sharedMEGASdk().createFolder(withName: MEGAVoiceMessagesFolderName,
                                                             parent: myChatFilesFolderNode,
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
            MEGASdkManager.sharedMEGAChatSdk().sendStopTypingNotification(forChat: chatRoom.chatId)
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
            MEGASdkManager.sharedMEGAChatSdk().sendTypingNotification(forChat: chatRoom.chatId)
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
    
    func voiceRecordingStarted() {
        audioController.stopAnyOngoingPlaying()
        isVoiceRecordingInProgress = true
        updateRightBarButtons()
    }
    
    func voiceRecordingEnded() {
        isVoiceRecordingInProgress = false
        updateRightBarButtons()
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
    func showScanDoc() {
        let vc = VNDocumentCameraViewController()
        vc.delegate = self
        present(viewController: vc)
    }
    
    func send(asset: PHAsset) {
        startUpload(assets: [asset])
    }
    
    func loadPhotosView() {
        let selectionActionDisabledText = Strings.Localizable.send
        let albumTableViewController = AlbumsTableViewController(selectionActionType: AlbumsSelectionActionType.send,
                                                                 selectionActionDisabledText: selectionActionDisabledText) { [weak self] assets in
                                                                    guard let `self` = self else {
                                                                        return
                                                                    }
                                                                    
                                                                    self.startUpload(assets: assets)
        }
        albumTableViewController.source = .chat
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
    
    func showGiphy() {
        let vc = GiphySelectionViewController(chatRoom: chatRoom)
        let nav = MEGANavigationController(rootViewController: vc)
        nav.addRightCancelButton()
        present(nav, animated: true, completion: nil)
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
                        MEGASdkManager.sharedMEGAChatSdk().attachNode(toChat: self.chatRoom.chatId, node: newNode.handle)
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
            guard let self = self, let users = users else {
                return
            }
            
            if let message = MEGASdkManager.sharedMEGAChatSdk().attachContacts(toChat: self.chatRoom.chatId,
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
                let title = Strings.Localizable.sendLocation
                
                let message = Strings.Localizable.thisLocationWillBeOpenedUsingAThirdPartyMapsProviderOutsideTheEndToEndEncryptedMEGAPlatform
                
                let cancelAction = UIAlertAction(title: Strings.Localizable.cancel, style: .cancel, handler: nil)
                
                let continueAction = UIAlertAction(title: Strings.Localizable.continue, style: .default) { _ in
                    let enableGeolocationDelegate = MEGAGenericRequestDelegate { (request, error) in
                        if error.type != .apiOk {
                            let alertTitle = Strings.Localizable.error
                            let alertMessage = Strings.Localizable.Chat.Map.Location.enableGeolocationFailedError(error.name)
                            
                            let enableGeolocationAlertAction = UIAlertAction(title: Strings.Localizable.ok,
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
                    MEGASdkManager.sharedMEGASdk().enableGeolocation(with: enableGeolocationDelegate)
                }
                
                let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alertController.addAction(cancelAction)
                alertController.addAction(continueAction)
                self.present(viewController: alertController)
            } else {
                self.presentShareLocation()
            }
        }
        MEGASdkManager.sharedMEGASdk().isGeolocationEnabled(with: genericRequestDelegate)
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
        if !isAudioPermissionAuthorized() {
            return false
        }
        
        if MEGASdkManager.sharedMEGAChatSdk().mnz_existsActiveCall {
            let message = Strings.Localizable.itIsNotPossibleToRecordVoiceMessagesWhileThereIsACallInProgress
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
