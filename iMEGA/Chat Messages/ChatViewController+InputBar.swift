import Chat
import ChatRepo
import CoreServices
import Foundation
import ISEmojiView
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAUI
import MessageKit
import VisionKit

extension ChatViewController {
    
    // MARK: - Overriden properties
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    // MARK: - Private properties

    private var joinInputBar: JoinInputBar {
        let joinInputBar = JoinInputBar.instanceFromNib
        joinInputBar.joinButton.backgroundColor = TokenColors.Button.primary
        joinInputBar.joinButton.setTitleColor(TokenColors.Text.inverseAccent, for: .normal)
        joinInputBar.buttonTappedHandler = { [weak self] button in
            self?.join(button: button)
        }
        joinInputBar.backgroundColor = TokenColors.Background.page
        view.addSubview(joinInputBar)
        joinInputBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            joinInputBar.heightAnchor.constraint(equalToConstant: 126),
            joinInputBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            joinInputBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            joinInputBar.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        return joinInputBar
    }
    
    func updateJoinView() {
        var newState: JoinViewState
        if MEGALinkManager.joiningOrLeavingChatBase64Handles.contains(MEGASdk.base64Handle(forUserHandle: chatRoom.chatId) ?? "") {
            newState = chatRoom.ownPrivilegeIsReadOnlyOrLower ? .joining : .leaving
        } else {
            newState = .default
        }
        
        joinInputBar.setJoinViewState(newState: newState)
    }

    // MARK: - Interface methods.
    
    func dismissKeyboardIfRequired() {
        if inputBarType == .custom(chatInputBar),
           chatInputBar.isTextViewTheFirstResponder() {
            chatInputBar.dismissKeyboard()
        }
    }
    
    func present(viewController: UIViewController, animated: Bool = true, dismissKeyboard: Bool = true) {
        if dismissKeyboard {
            dismissKeyboardIfRequired()
        }
        
        if let mainTabBarController = UIApplication.mainTabBarRootViewController() {
            if !mainTabBarController.tabBar.isHidden {
                mainTabBarController.tabBar.isHidden = true
                
                mainTabBarController.present(viewController, animated: animated) {
                    mainTabBarController.tabBar.isHidden = false
                }
                
                return
            }
        }
        present(viewController, animated: animated)
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
        if inputBarType == .custom(chatInputBar),
            let text = MEGAStore.shareInstance().fetchChatDraft(withChatId: chatRoom.chatId)?.text,
            !text.isEmpty {
            chatInputBar.set(text: text, showKeyboard: false)
        }
    }
    
    func saveDraft() {
        if inputBarType == .custom(chatInputBar) {
            MEGAStore.shareInstance().insertOrUpdateChatDraft(withChatId: chatRoom.chatId, text: (editMessage != nil) ? "" : (chatInputBar.text ?? ""))
        }
    }
    
    func presentShareLocation(editing: Bool = false) {
        let storyboard = UIStoryboard(name: "Chat", bundle: nil)
        guard let shareLocationViewController = storyboard.instantiateViewController(withIdentifier: "ShareLocationViewControllerID") as? ShareLocationViewController else {
            fatalError("ChatViewController: could not create an instance of ShareLocationViewController")
        }
        
        guard let megaChatRoom = chatRoom.toMEGAChatRoom() else {
            return
        }
        shareLocationViewController.chatRoom = megaChatRoom
        
        if editing, let editMessage = self.editMessage {
            shareLocationViewController.editMessage = editMessage.message
            self.editMessage = nil
        }
            
        let navController = MEGANavigationController(rootViewController: shareLocationViewController)
        navController.addLeftDismissButton(withText: Strings.Localizable.cancel)
        present(viewController: navController)
    }
    
    // MARK: - Private methods.
    internal func configureInputBarType() {
        if isEditing {
            inputBarType = .custom(UIView(frame: .zero))
        } else if chatRoom.isPublicChat,
                  chatRoom.isPreview,
                  !chatRoomDelegate.hasChatRoomClosed || MEGALinkManager.joiningOrLeavingChatBase64Handles.contains(MEGASdk.base64Handle(forUserHandle: chatRoom.chatId) ?? "") {
            inputBarType = .custom(joinInputBar)
        } else if chatRoom.ownPrivilegeIsReadOnlyOrLower || previewMode {
            inputBarType = .custom(UIView(frame: .zero))
        } else {
            inputBarType = .custom(chatInputBar)
        }
    }
    
    private func join(button: UIButton) {
        if MEGAChatSdk.shared.initState() == .anonymous {
            MEGALinkManager.secondaryLinkURL = publicChatLink
            MEGALinkManager.selectedOption = .joinChatLink
            dismissChatRoom()
        } else {
            let delegate = ChatRequestDelegate { result in
                guard case let .success(request) = result,
                      let chatRoom = MEGAChatSdk.shared.chatRoom(forChatId: request.chatHandle) else {
                    MEGALogDebug("ChatRoom not found with chat handle")
                    return
                }
                MEGALinkManager.joiningOrLeavingChatBase64Handles.remove(MEGASdk.base64Handle(forUserHandle: self.chatRoom.chatId) ?? "")
                self.closeChatRoom()
                self.update(chatRoom: chatRoom.toChatRoomEntity())
                self.messagesCollectionView.reloadData()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.scrollToBottom()
                    self.reloadInputViews()
                    self.configureInputBarType()
                }
            }
            if let handle = MEGASdk.base64Handle(forUserHandle: chatRoom.chatId) {
                MEGALinkManager.joiningOrLeavingChatBase64Handles.add(handle)
            }
            MEGAChatSdk.shared.autojoinPublicChat(chatRoom.chatId, delegate: delegate)
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
        
        chatInputBar.dismissKeyboard()

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
            if UIDevice.current.deviceName() == "iPhone SE 1st" {
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
                                 allowNonHostToAddParticipants: Bool,
                                 getChatLink: Bool) {
        guard let selectedUsers = selectedObjects as? [MEGAUser] else {
            return
        }
        
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show()

        let peerlist = MEGAChatPeerList()
        selectedUsers.forEach { peerlist.addPeer(withHandle: $0.handle, privilege: 2)}
        
        if keyRotationEnabled {
            MEGAChatSdk.shared.mnz_createChatRoom(
                usersArray: selectedUsers,
                title: groupName,
                allowNonHostToAddParticipants: allowNonHostToAddParticipants
            ) { newChatRoom in
                DispatchQueue.main.async {
                    self.open(chatRoom: newChatRoom)
                }
            }
        } else {
            let createChatGroupRequestDelegate = ChatRequestDelegate { result in
                guard case let .success(request) = result,
                        let newChatRoom = MEGAChatSdk.shared.chatRoom(forChatId: request.chatHandle) else {
                    MEGALogDebug("Cannot find chatRoom")
                    return
                }
                if getChatLink {
                    let genericRequestDelegate = ChatRequestDelegate { result in
                        if case let .success(request) = result, let text = request.text {
                            self.open(chatRoom: newChatRoom, publicLink: text)
                        }
                    }
                    
                    MEGAChatSdk.shared.createChatLink(newChatRoom.chatId, delegate: genericRequestDelegate)
                } else {
                    DispatchQueue.main.async {
                        self.open(chatRoom: newChatRoom)
                    }
                }
            }
            MEGAChatSdk.shared.createPublicChat(withPeers: peerlist,
                                                                title: groupName,
                                                                speakRequest: false,
                                                                waitingRoom: false,
                                                                openInvite: allowNonHostToAddParticipants,
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
    
    private func open(chatRoom: MEGAChatRoom, publicLink: String? = nil) {
        ChatContentRouter(chatRoom: chatRoom.toChatRoomEntity(), presenter: self.navigationController, publicLink: publicLink, showShareLinkViewAfterOpenChat: publicLink != nil ? true : false).start()
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
            guard let self else { return }
            
            switch transfer.state {
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
    
    private nonisolated func uploadAsset(withFilePath filePath: String, parentNode: MEGANode, localIdentifier: String, chatRoomId: HandleEntity, delegate: MEGAStartUploadTransferDelegate) {
        var appData: String?
        
        if let cordinates = (filePath as NSString).mnz_coordinatesOfPhotoOrVideo() {
            appData = NSString().mnz_appData(toSaveCoordinates: cordinates)
        }
                                            
        appData = ((appData ?? "") as NSString).mnz_appDataToAttach(toChatID: chatRoomId, asVoiceClip: false)
        appData = ((appData ?? "") as NSString).mnz_appData(toLocalIdentifier: localIdentifier)
        
        ChatUploader.sharedInstance.upload(filepath: filePath,
                                           appData: appData ?? "",
                                           chatRoomId: chatRoomId,
                                           parentNode: parentNode,
                                           isSourceTemporary: false,
                                           delegate: delegate)
    }
    
    private func uploadVideo(withFilePath path: String, parentNode: MEGANode) {
        let videoURL = URL(fileURLWithPath: NSHomeDirectory().append(pathComponent: path))
        
        let processAsset = MEGAProcessAsset(toShareThroughChatWithVideoURL: videoURL,
                                            presenter: self,
                                            filePath: { [weak self] path in
            guard let filePath = path,
                let `self` = self else {
                MEGALogDebug("Video processing `MEGAProcessAsset` issue with file path as nil")
                return
            }
            
            self.uploadAsset(withFilePath: filePath, parentNode: parentNode, localIdentifier: "", chatRoomId: chatRoom.chatId, delegate: createUploadTransferDelegate())
        }, error: { [weak self] error in
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
        })
        
        processAsset.prepare()
    }
    
    private nonisolated func uploadingAssets(assets: [PHAsset], parentNode: MEGANode, chatRoomId: HandleEntity, delegate: MEGAStartUploadTransferDelegate) {
        let processAsset = MEGAProcessAsset(toShareThroughChatWith: assets,
                                            presenter: self,
                                            filePaths: { [weak self] filePaths in
            
            guard let self, let filePaths else { return }
                                                
            filePaths.enumerated().forEach { (index, filePath) in
                self.uploadAsset(withFilePath: filePath, parentNode: parentNode, localIdentifier: assets[index].localIdentifier, chatRoomId: chatRoomId, delegate: delegate)
            }
            
        }, errors: { errors in
            guard let errors = errors else {
                return
            }
            
            let message = if let error = errors.first, errors.count == 1 {
                error.localizedDescription
            } else {
                Strings.Localizable.shareExtensionUnsupportedAssets
            }
            
            Task { @MainActor in
                let alertController = UIAlertController(title: Strings.Localizable.error,
                                                        message: message,
                                                        preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: Strings.Localizable.ok,
                                                        style: .cancel,
                                                        handler: nil))
                self.present(alertController, animated: true)
            }
        })
        
        DispatchQueue.global(qos: .background).async {
            processAsset.isOriginalName = true
            processAsset.prepare()
        }
    }
    
    private func startUpload(assets: [PHAsset]) async {
        do {
            MyChatFilesFolderNodeAccess.shared.updateAutoCreate(status: true)
            guard let myChatFilesFolderNode = try await MyChatFilesFolderNodeAccess.shared.loadNode() else { return }
            uploadingAssets(assets: assets, parentNode: myChatFilesFolderNode, chatRoomId: chatRoom.chatId, delegate: createUploadTransferDelegate())
        } catch {
            MEGALogWarning("Could not load MyChatFiles target folder due to error \(error.localizedDescription)")
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
        MEGAChatSdk.shared.sendStopTypingNotification(forChat: chatRoom.chatId)
        
        if let editMessage = editMessage {
            let messageId = (editMessage.message.status == .sending) ? editMessage.message.temporalId : editMessage.message.messageId
            
            if editMessage.message.content != text,
                let message = MEGAChatSdk.shared.editMessage(forChat: chatRoom.chatId, messageId: messageId, message: text) {
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
        } else if let message = MEGAChatSdk.shared.sendMessage(toChat: chatRoom.chatId, message: text) {
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
        if let content = message.content, MEGAChatSdk.hasUrl(content) {
            MEGASdk.shared.shouldShowRichLinkWarning(with: MEGAGetAttrUserRequestDelegate(completion: { (request) in
                if let request = request, request.flag {
                    message.warningDialog = (request.number >= 3 ? MEGAChatMessageWarningDialog.standard : MEGAChatMessageWarningDialog.initial)
                    self.richLinkWarningCounterValue = Int(request.number)
                    self.chatRoomDelegate.updateMessage(message)
                }
            }, error: { (request, _) in
                if let request = request, request.flag {
                    message.warningDialog = (request.number >= 3 ? MEGAChatMessageWarningDialog.standard : MEGAChatMessageWarningDialog.initial)
                    self.richLinkWarningCounterValue = Int(request.number)
                    self.chatRoomDelegate.updateMessage(message)

                }
            }))
        }
    }
    
    private nonisolated func uploadAudio(path: String, parentNode: MEGANode, chatRoomId: HandleEntity, delegate: MEGAStartUploadTransferDelegate) {
        let appData = ("" as NSString).mnz_appDataToAttach(toChatID: chatRoomId, asVoiceClip: true)
        
        if let voiceMessagesNode = MEGASdk.shared.node(forPath: MEGAVoiceMessagesFolderName, node: parentNode) {
            ChatUploader.sharedInstance.upload(filepath: path,
                                               appData: appData,
                                               chatRoomId: chatRoomId,
                                               parentNode: voiceMessagesNode,
                                               isSourceTemporary: false,
                                               delegate: delegate)
        } else {
            let requestDelegate: some MEGARequestDelegate = MEGACreateFolderRequestDelegate { request in
                guard let request = request else {
                    fatalError("request object should not be nil")
                }
                
                if let voiceMessagesNode = MEGASdk.shared.node(forHandle: request.nodeHandle) {
                    ChatUploader.sharedInstance.upload(filepath: path,
                                                       appData: appData,
                                                       chatRoomId: chatRoomId,
                                                       parentNode: voiceMessagesNode,
                                                       isSourceTemporary: false,
                                                       delegate: delegate)
                } else {
                    MEGALogDebug("Voice folder not created")
                }
            }
            
            MEGASdk.shared.createFolder(withName: MEGAVoiceMessagesFolderName,
                                                         parent: parentNode,
                                                         delegate: requestDelegate)
        }
    }
    
    func tappedSendAudio(atPath path: String) {
        Task {
            do {
                MyChatFilesFolderNodeAccess.shared.updateAutoCreate(status: true)
                guard let myChatFilesFolderNode = try await MyChatFilesFolderNodeAccess.shared.loadNode() else { return }
                uploadAudio(path: path, parentNode: myChatFilesFolderNode, chatRoomId: chatRoom.chatId, delegate: createUploadTransferDelegate())
                TonePlayer().playSystemSound(.audioClipSent)
            } catch {
                MEGALogWarning("Could not load MyChatFiles target folder due to error \(error.localizedDescription)")
            }
        }
    }
    
    func tappedVoiceButton() {
        if !permissionHandler.isAudioPermissionAuthorized {
            return
        }
        
        showTapAndHoldMessage()
    }
    
    func updateTypingIndicatorView(withAttributedString attributedString: NSAttributedString?) {
        if inputBarType == .custom(chatInputBar) {
            chatInputBar.setTypingIndicator(text: attributedString)
        }
    }
    
    func typing(withText text: String) {
        if text.isEmpty {
            MEGAChatSdk.shared.sendStopTypingNotification(forChat: chatRoom.chatId)
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
            MEGAChatSdk.shared.sendTypingNotification(forChat: chatRoom.chatId)
        }
    }
    
    func textDidEndEditing() {
        saveDraft()
    }
    
    func showTapAndHoldMessage() {
        let myViews = view.subviews.filter { $0 is TapAndHoldMessageView }
        guard let inputAccessoryView = inputAccessoryView,
            myViews.isEmpty  else {
            return
        }
        
        let tapAndHoldMessageView = TapAndHoldMessageView.instanceFromNib
        tapAndHoldMessageView.add(toView: view, bottom: inputAccessoryView.frame.height)
    }
    
    func voiceRecordingStarted() {
        audioController.stopAnyOngoingPlaying()
        chatContentViewModel.dispatch(.startRecordVoiceClip)
    }
    
    func voiceRecordingEnded() {
        chatContentViewModel.dispatch(.stopRecordVoiceClip)
    }
}

extension ChatViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        guard presented is AddToChatViewController else {
            return nil
        }
        
        return AddToChatViewAnimator(type: .present)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
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
        Task {
            await startUpload(assets: [asset])
        }
    }
    
    func loadPhotosView() {
        let photoPicker = MEGAPhotoPicker(presenter: self)
        Task { @MainActor in
            let assets = await photoPicker.pickAssets()
            await startUpload(assets: assets)
        }
    }
    
    func showCamera() {
        guard let pickerController = MEGAImagePickerController(toShareThroughChatWith: .camera,
                                                               filePathCompletion: { [weak self] (filePath, _, node) in
            guard let path = filePath,
                let parentNode = node,
                let `self` = self else {
                    return
            }
            let pathGroup = path.fileExtensionGroup
            if pathGroup.isImage {
                self.uploadAsset(withFilePath: path, parentNode: parentNode, localIdentifier: "", chatRoomId: chatRoom.chatId, delegate: createUploadTransferDelegate())
            } else if pathGroup.isVideo {
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
    
    func showFilesApp() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.data, UTType.package], asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = true
        present(documentPicker, animated: true)
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
                        MEGAChatSdk.shared.attachNode(toChat: self.chatRoom.chatId, node: newNode.handle)
                    }
                }
            }
        }
        
        present(viewController: cloudDriveNavController)
    }
    
    func showVoiceClip() {
        chatInputBar.voiceRecordingViewEnabled = true
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
            
            if let message = MEGAChatSdk.shared.attachContacts(toChat: self.chatRoom.chatId,
                                                                                contacts: users) {
                self.chatRoomDelegate.insertMessage(message)
            }
        }
        
        present(viewController: contactsNavigationController)
    }
    
    func showLocation() {
        let genericRequestDelegate = RequestDelegate { result in
            if case .success = result {
                let title = Strings.Localizable.sendLocation
                
                let message = Strings.Localizable.thisLocationWillBeOpenedUsingAThirdPartyMapsProviderOutsideTheEndToEndEncryptedMEGAPlatform
                
                let cancelAction = UIAlertAction(title: Strings.Localizable.cancel, style: .cancel, handler: nil)
                
                let continueAction = UIAlertAction(title: Strings.Localizable.continue, style: .default) { _ in
                    let enableGeolocationDelegate = RequestDelegate { result in
                        if case let .failure(error) = result {
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
                    MEGASdk.shared.enableGeolocation(with: enableGeolocationDelegate)
                }
                
                let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alertController.addAction(cancelAction)
                alertController.addAction(continueAction)
                self.present(viewController: alertController)
            } else {
                self.presentShareLocation()
            }
        }
        MEGASdk.shared.isGeolocationEnabled(with: genericRequestDelegate)
    }
    
    var canRecordAudio: Bool {
        permissionHandler.isAudioPermissionAuthorized
    }
    
    var existsActiveCall: Bool {
        MEGAChatSdk.shared.mnz_existsActiveCall
    }
    
    func requestOrInformAudioPermissions() {
        if permissionHandler.shouldAskForAudioPermissions {
            permissionHandler.requestAudioPermission()
            return
        }
        
        if permissionHandler.audioPermissionAuthorizationStatus == .denied {
            informPermissionsDenied()
        }
    }
    
    func presentActiveCall() {
        let message = Strings.Localizable.itIsNotPossibleToRecordVoiceMessagesWhileThereIsACallInProgress
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.showError(withStatus: message)
    }
    
    private func informPermissionsDenied() {
        permissionRouter.alertAudioPermission(incomingCall: false)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

extension ChatViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController,
                                   traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}

extension ChatViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        Task { @MainActor in
            do {
                guard let myChatFilesFolderNode = try await MyChatFilesFolderNodeAccess.shared.loadNode() else { return }
                urls.forEach { url in
                    uploadAsset(withFilePath: url.path, parentNode: myChatFilesFolderNode, localIdentifier: "", chatRoomId: chatRoom.chatId, delegate: createUploadTransferDelegate())
                }
            } catch {
                MEGALogWarning("Could not load MyChatFiles target folder due to error \(error.localizedDescription)")
            }
        }
    }
}
