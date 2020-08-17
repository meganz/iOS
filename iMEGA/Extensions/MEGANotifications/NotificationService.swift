import UserNotifications

class NotificationService: UNNotificationServiceExtension, MEGAChatNotificationDelegate, MEGAChatDelegate {
    private static var session: String?
    private static var setLogToConsole = false
    private static let genericBody = NSLocalizedString("You may have new messages", comment: "Content of the notification when there is unknown activity on the Chat")

    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?
    
    private var chatId: UInt64?
    private var msgId: UInt64?
    
    private var waitingForThumbnail = false
    private var waitingForUserAttributes = false

    // MARK: - UNNotificationServiceExtension

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        NotificationService.setupLogging()
        MEGALogInfo("Push received: request identifier: \(request.identifier)\n user info: \(request.content.userInfo)")
        removePreviousGenericNotifications()
        
        guard let session = SAMKeychain.password(forService: "MEGA", account: "sessionV3") else {
            postNotification(withError: "No session in the Keychain")
            return
        }
        
        if NotificationService.session == nil {
            guard NotificationService.initExtensionProcess(with: session) else {
                return
            }
            NotificationService.session = session
        } else {
            if NotificationService.session != session {
                MEGALogDebug("Restart extension process: NSE session != Keychain session")
                restartExtensionProcess(with: session)
                return
            }
            if let sharedUserDefaults = UserDefaults.init(suiteName: MEGAGroupIdentifier) {
                if sharedUserDefaults.bool(forKey: MEGAInvalidateNSECache) {
                    MEGALogDebug("Restart extension process: app invalidates the NSE cache")
                    restartExtensionProcess(with: session)
                    return
                }
            }
        }
        
        processNotification()
    }

    override func serviceExtensionTimeWillExpire() {
        MEGALogDebug("Service extension time will expire")
        if let chatId = chatId, let msgId = msgId, let message = MEGASdkManager.sharedMEGAChatSdk()?.message(forChat: chatId, messageId: msgId) {
            if message.type == .unknown {
                postNotification(withError: "Unknown message")
            } else {
                let error = !generateNotification(with: message, immediately: true)
                postNotification(withError: error ? "No chat room for message" : nil)
            }
        } else {
            postNotification(withError: "Service Extension time will expire and message not found")
        }
    }

    // MARK: - Private
    
    private func generateNotification(with message: MEGAChatMessage, immediately: Bool) -> Bool {
        guard let chatId = chatId, let chatRoom = MEGASdkManager.sharedMEGAChatSdk()?.chatRoom(forChatId: chatId) else {
            return false
        }
        let notificationManager = MEGALocalNotificationManager(chatRoom: chatRoom, message: message, silent: false)
        bestAttemptContent?.userInfo = ["chatId": chatId, "msgId": message.messageId]
        bestAttemptContent?.body = notificationManager.bodyString()
        bestAttemptContent?.sound = UNNotificationSound.default
        let displayName = chatRoom.userDisplayName(forUserHandle: message.userHandle)
        if chatRoom.isGroup {
            bestAttemptContent?.title = chatRoom.title ?? ""
            if #available(iOS 12.0, *) {
                bestAttemptContent?.summaryArgument = chatRoom.title ?? ""
            }
        }
        setupDisplayName(displayName: displayName, for: chatRoom)
        
        let chatIdBase64 = MEGASdk.base64Handle(forUserHandle: chatId) ?? ""
        bestAttemptContent?.threadIdentifier = chatIdBase64
        
        if immediately {
            return true
        }
        
        var readyToPost = true
        if displayName == nil {
            MEGASdkManager.sharedMEGAChatSdk()?.loadUserAttributes(forChatId: chatId, usersHandles: [message.userHandle] as [NSNumber], delegate: MEGAChatGenericRequestDelegate { [weak self] request, error in
                if error.type != .MEGAChatErrorTypeOk {
                    return
                }
                guard let chatRoom = MEGASdkManager.sharedMEGAChatSdk()?.chatRoom(forChatId: chatId) else {
                    return
                }
                let displayName = chatRoom.userDisplayName(forUserHandle: message.userHandle)
                self?.setupDisplayName(displayName: displayName, for: chatRoom)
                self?.waitingForUserAttributes = false
                if !(self?.waitingForThumbnail ?? true) {
                    self?.postNotification(withError: nil)
                }
            })
            readyToPost = false
            waitingForUserAttributes = true
        }
        
        if message.type == .attachment {
            guard let nodeList = message.nodeList else {
                return readyToPost
            }
            if nodeList.size?.intValue != 1 {
                return readyToPost
            }
            guard let node = nodeList.node(at: 0) else {
                return readyToPost
            }
            if !node.hasThumbnail() {
                return readyToPost
            }
            guard let destinationFilePath = path(for: node, in: "thumbnailsV3") else {
                return readyToPost
            }

            MEGASdkManager.sharedMEGASdk()?.getThumbnailNode(node, destinationFilePath: destinationFilePath, delegate: MEGAGenericRequestDelegate { [weak self] request, _ in
                if let notificationAttachment = notificationManager.notificationAttachment(for: request.file, withIdentifier: node.base64Handle) {
                    self?.bestAttemptContent?.attachments = [notificationAttachment]
                    self?.waitingForThumbnail = false
                    if !(self?.waitingForUserAttributes ?? true) {
                        self?.postNotification(withError: nil)
                    }
                }
            })
            readyToPost = false
            waitingForThumbnail = true
        }
        
        return readyToPost
    }
    
    private func postNotification(withError error: String?) {
        MEGASdkManager.sharedMEGAChatSdk()?.remove(self as MEGAChatNotificationDelegate)
        MEGASdkManager.sharedMEGAChatSdk()?.remove(self as MEGAChatDelegate)

        guard let contentHandler = contentHandler else {
            return
        }
        guard let bestAttemptContent = bestAttemptContent else {
            return
        }

        if let errorString = error {
            MEGALogError(errorString)
            bestAttemptContent.body = NotificationService.genericBody
            bestAttemptContent.sound = nil
        } else {
            MEGALogDebug("Post notification: message found")
            if let msgId = msgId, let chatId = chatId {
                MEGAStore.shareInstance()?.insertMessage(msgId, chatId: chatId)
            }
        }
        
        MEGASdkManager.sharedMEGAChatSdk()?.saveCurrentState()
        
        // Note: As soon as we call the contentHandler, no content can be retrieved from notification center.
        bestAttemptContent.badge = MEGASdkManager.sharedMEGAChatSdk()?.unreadChats as NSNumber?
        contentHandler(bestAttemptContent)
    }
    
    private func removePreviousGenericNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
            var identifiers = [String]()
            for request in requests {
                if request.content.body == NotificationService.genericBody {
                    identifiers.append(request.identifier)
                }
            }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        }
        UNUserNotificationCenter.current().getDeliveredNotifications { (notifications) in
            var identifiers = [String]()
            for notification in notifications {
                if notification.request.content.body == NotificationService.genericBody {
                    identifiers.append(notification.request.identifier)
                }
            }
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
        }
    }
    
    private func processNotification() {
        MEGALogDebug("Process notification")
        guard let megadataDictionary = bestAttemptContent?.userInfo["megadata"] as? [String : String],
            let chatIdBase64 = megadataDictionary["chatid"],
            let msgIdBase64 = megadataDictionary["msgid"]
            else {
                postNotification(withError: "No chatId/msgId in the notification")
                return
        }
        let chatId = MEGASdk.handle(forBase64UserHandle: chatIdBase64)
        let msgId = MEGASdk.handle(forBase64UserHandle: msgIdBase64)
        
        self.chatId = chatId
        self.msgId = msgId
        
        bestAttemptContent?.categoryIdentifier = "nz.mega.chat.message"
        
        if let moMessage = MEGAStore.shareInstance()?.fetchMessage(withChatId: chatId, messageId: msgId) {
            MEGAStore.shareInstance()?.delete(moMessage)
            postNotification(withError: "Already notified")
        }
        
        MEGASdkManager.sharedMEGAChatSdk()?.add(self as MEGAChatNotificationDelegate)
        MEGASdkManager.sharedMEGAChatSdk()?.add(self as MEGAChatDelegate)
        MEGASdkManager.sharedMEGAChatSdk()?.pushReceived(withBeep: true, chatId: MEGAInvalidHandle)
        
        if MEGASdkManager.sharedMEGAChatSdk()?.areAllChatsLoggedIn ?? false,
            let message = MEGASdkManager.sharedMEGAChatSdk()?.message(forChat: chatId, messageId: msgId),
            message.type != .unknown,
            generateNotification(with: message, immediately: false) {
                MEGALogDebug("Message exists in karere cache")
                postNotification(withError: nil)
                return
        }
    }
    
    private func restartExtensionProcess(with session: String) {
        NotificationService.session = nil
        MEGASdkManager.sharedMEGASdk()?.localLogout(with: MEGAGenericRequestDelegate {
            request, error in
            if error.type != .apiOk {
                self.postNotification(withError: "SDK error in localLogout \(error)")
                return
            }
            MEGASdkManager.sharedMEGAChatSdk()?.localLogout(with: MEGAChatGenericRequestDelegate {
                request, error in
                if error.type != .MEGAChatErrorTypeOk {
                    self.postNotification(withError: "MEGAChat error in localLogout \(error)")
                    return
                }
                if NotificationService.initExtensionProcess(with: session) {
                    NotificationService.session = session
                    self.processNotification()
                }
            })
        })
    }
    
    private func path(for node: MEGANode, in sharedSandboxCacheDirectory: String) -> String? {
        let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: MEGAGroupIdentifier)
        guard let destinationURL = containerURL?.appendingPathComponent(MEGAExtensionCacheFolder, isDirectory: true).appendingPathComponent(sharedSandboxCacheDirectory, isDirectory: true) else {
            return nil
        }
        do {
            try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
            return destinationURL.appendingPathComponent(node.base64Handle).path
        } catch {
            return nil
        }
    }
    
    private func setupDisplayName(displayName: String?, for chatRoom: MEGAChatRoom) {
        guard let displayName = displayName else {
            MEGALogWarning("[Chat Links Scalability] Display name not ready")
            return
        }
        
        if chatRoom.isGroup {
            bestAttemptContent?.subtitle = displayName
        } else {
            bestAttemptContent?.title = displayName
            if #available(iOS 12.0, *) {
                bestAttemptContent?.summaryArgument = displayName
            }
        }
    }

    // MARK: - Lean init, login and connect
    
    private static func initExtensionProcess(with session: String) -> Bool {
        MEGALogDebug("Init extension process")
        NSSetUncaughtExceptionHandler { (exception) in
            MEGALogError("Exception name: \(exception.name)\nreason: \(String(describing: exception.reason))\nuser info: \(String(describing: exception.userInfo))\n")
            MEGALogError("Stack trace: \(exception.callStackSymbols)")
        }
        
        copyDatabasesFromMainApp(with: session)

        let success = initChat(with: session)
        if success {
            MEGALogDebug("Init chat success")
            loginToMEGA(with: session)
            if let sharedUserDefaults = UserDefaults.init(suiteName: MEGAGroupIdentifier) {
                sharedUserDefaults.set(false, forKey: MEGAInvalidateNSECache)
            }
        }
        
        return success
    }
    
    private static func setupLogging() {
        if !setLogToConsole {
            setLogToConsole = true
#if DEBUG
            MEGASdk.setLogLevel(.max)
            MEGAChatSdk.setCatchException(false)
#else
            MEGASdk.setLogLevel(.fatal)
#endif
            MEGASdk.setLogToConsole(true)
        }
        
        guard let sharedUserDefaults = UserDefaults.init(suiteName: MEGAGroupIdentifier) else {
            return
        }
        
        if sharedUserDefaults.bool(forKey: "logging") {
            guard let logsFolderURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: MEGAGroupIdentifier)?.appendingPathComponent(MEGAExtensionLogsFolder) else {
                return
            }
            if !FileManager.default.fileExists(atPath: logsFolderURL.path) {
                do {
                    try FileManager.default.createDirectory(atPath: logsFolderURL.path, withIntermediateDirectories: false, attributes: nil)
                } catch {
                    MEGALogError("Error creating logs directory: \(logsFolderURL.path)")
                    return
                }
            }
            let logsPath = logsFolderURL.appendingPathComponent("MEGAiOS.NSE.log").path
            MEGALogger.shared()?.startLogging(toFile: logsPath)
        }
    }

    // As part of the lean init, a cache is required. It will not be generated from scratch.
    private static func copyDatabasesFromMainApp(with session: String) {
        MEGALogDebug("Copy databases from main app")
        let fileManager = FileManager.default
        
        guard let groupContainerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: MEGAGroupIdentifier) else {
            MEGALogError("No groupContainerURL")
            return
        }

        let groupSupportURL = groupContainerURL.appendingPathComponent(MEGAExtensionGroupSupportFolder)
        if !fileManager.fileExists(atPath: groupSupportURL.path) {
            MEGALogError("No groupSupportURL")
            return
        }
        
        let nseCacheURL = groupContainerURL.appendingPathComponent(MEGANotificationServiceExtensionCacheFolder)
                
        do {
            try fileManager.createDirectory(at: nseCacheURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            MEGALogError("Failed to locate/create \(nseCacheURL.path) directory");
        }
        
        guard let nseCacheContent = try? fileManager.contentsOfDirectory(atPath: nseCacheURL.path),
            let groupSupportPathContent = try? fileManager.contentsOfDirectory(atPath: groupSupportURL.path)
            else {
                MEGALogError("Error enumerating groupSupportPathContent")
                return
        }
        
        let cacheSessionName = session.dropFirst(Int(MEGADropFirstCharactersFromSession))
        for filename in nseCacheContent {
            if filename.contains(cacheSessionName) {
                let pathToRemove = nseCacheURL.appendingPathComponent(filename).path
                fileManager.mnz_removeItem(atPath: pathToRemove)
            }
        }

        for filename in groupSupportPathContent {
            if filename.contains(cacheSessionName) {
                let sourceURL = groupSupportURL.appendingPathComponent(filename)
                let destinationURL = nseCacheURL.appendingPathComponent(filename)
                do {
                    MEGALogDebug("Copy item: \(sourceURL.absoluteString)")
                    try fileManager.copyItem(at: sourceURL, to: destinationURL)
                } catch {
                    MEGALogError("Copy item at path failed with error: \(error)")
                }
            }
        }
    }
    
    private static func initChat(with session: String) -> Bool {
        MEGALogDebug("Init chat")
        if MEGASdkManager.sharedMEGAChatSdk() == nil {
            MEGASdkManager.createSharedMEGAChatSdk()
        }

        var chatInit = MEGASdkManager.sharedMEGAChatSdk()?.initState()
        if chatInit == .notDone {
            MEGALogDebug("Init state == notDone -> Init Karere Lean Mode")
            chatInit = MEGASdkManager.sharedMEGAChatSdk()?.initKarereLeanMode(withSid: session)
            if chatInit == .error {
                MEGALogError("Init Karere Lean Mode fails -> logout")
                MEGASdkManager.sharedMEGAChatSdk()?.logout()
                return false
            }
            MEGALogDebug("Reset client Id")
            MEGASdkManager.sharedMEGAChatSdk()?.resetClientId()
        } else {
            MEGALogDebug("Init state != notDone -> Reconnect")
            MEGAReachabilityManager.shared()?.reconnect()
        }
        
        return true
    }
    
    private static func loginToMEGA(with session: String) {
        MEGALogDebug("Login to MEGA")
        MEGASdkManager.sharedMEGASdk()?.fastLogin(withSession: session, delegate: MEGAGenericRequestDelegate { request, error in
            if error.type != .apiOk {
                MEGALogError("Login error \(error)")
                return
            }

            MEGALogDebug("Connect in background")
            MEGASdkManager.sharedMEGAChatSdk()?.connectInBackground()
        })
    }

    // MARK: - MEGAChatNotificationDelegate

    func onChatNotification(_ api: MEGAChatSdk, chatId: UInt64, message: MEGAChatMessage) {
        if chatId != self.chatId || message.messageId != self.msgId {
            MEGALogWarning("onChatNotification for a different message")
            return
        }

        if generateNotification(with: message, immediately: false) {
            MEGALogDebug("On Chat notification for message \(message)")
            if api.areAllChatsLoggedIn {
                postNotification(withError: nil)
            } else {
                MEGALogWarning("But not logged in all chats")
            }
        }
    }

    // MARK: - MEGAChatDelegate

    func onChatConnectionStateUpdate(_ api: MEGAChatSdk!, chatId: UInt64, newState: Int32) {
        if chatId == MEGAInvalidHandle && newState == 3 {
            MEGALogDebug("Logged in all chats")
            if let message = MEGASdkManager.sharedMEGAChatSdk()?.message(forChat: self.chatId ?? MEGAInvalidHandle, messageId: self.msgId ?? MEGAInvalidHandle) {
                if message.type != .unknown && generateNotification(with: message, immediately: false) {
                    postNotification(withError: nil)
                } else {
                    MEGALogWarning("Message unknown or generate notification return false")
                }
            } else {
                MEGALogWarning("Message not found in karere cache")
            }
        }
    }
}
