import UserNotifications

class NotificationService: UNNotificationServiceExtension, MEGAChatNotificationDelegate {
    static var session: String?

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    var chatId: UInt64?
    var msgId: UInt64?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        if NotificationService.session == nil {
            NotificationService.initExtensionProcess()
            if NotificationService.session == nil {
                postNotification(withError: "No session in the Keychain")
                return
            }
        }

        MEGALogInfo("Push received: request identifier: \(request.identifier)\n user info: \(request.content.userInfo)")

        guard let megadataDictionary = bestAttemptContent?.userInfo["megadata"] as? [String: String],
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

        if let message = MEGASdkManager.sharedMEGAChatSdk()?.message(forChat: chatId, messageId: msgId) {
            if generateNotification(with: message, immediately: false) {
                postNotification(withError: nil)
            }
            return
        } else {
            MEGASdkManager.sharedMEGAChatSdk()?.add(self as MEGAChatNotificationDelegate)
            MEGASdkManager.sharedMEGAChatSdk()?.pushReceived(withBeep: true, chatId: chatId, delegate: MEGAChatGenericRequestDelegate { [weak self] _, error in
                if error.type != .MEGAChatErrorTypeOk {
                    self?.postNotification(withError: "Error in pushReceived \(error)")
                    return
                }
            })
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let chatId = chatId, let msgId = msgId, let message = MEGASdkManager.sharedMEGAChatSdk()?.message(forChat: chatId, messageId: msgId) {
            let error = !generateNotification(with: message, immediately: true)
            postNotification(withError: error ? "No chat room for message" : nil)
        } else {
            postNotification(withError: "Service Extension time will expire")
        }
    }

    // MARK: - Private

    func generateNotification(with message: MEGAChatMessage, immediately: Bool) -> Bool {
        guard let chatId = chatId, let chatRoom = MEGASdkManager.sharedMEGAChatSdk()?.chatRoom(forChatId: chatId) else {
            return false
        }
        let notificationManager = MEGALocalNotificationManager(chatRoom: chatRoom, message: message, silent: false)
        bestAttemptContent?.userInfo = ["chatId": chatId, "msgId": message.messageId]
        bestAttemptContent?.body = notificationManager.bodyString()
        bestAttemptContent?.sound = UNNotificationSound.default
        if chatRoom.isGroup {
            bestAttemptContent?.title = chatRoom.title
            bestAttemptContent?.subtitle = notificationManager.displayName()
        } else {
            bestAttemptContent?.title = notificationManager.displayName()
        }

        let chatIdBase64 = MEGASdk.base64Handle(forUserHandle: chatId) ?? ""
        bestAttemptContent?.threadIdentifier = chatIdBase64
        if #available(iOS 12.0, *) {
            if chatRoom.isGroup {
                bestAttemptContent?.summaryArgument = chatRoom.title
            } else {
                bestAttemptContent?.summaryArgument = notificationManager.displayName()
            }
        }

        if immediately {
            return true
        }

        if message.type == .attachment {
            guard let nodeList = message.nodeList else {
                return true
            }
            if nodeList.size?.intValue != 1 {
                return true
            }
            guard let node = nodeList.node(at: 0) else {
                return true
            }
            if !node.hasThumbnail() {
                return true
            }
            guard let destinationFilePath = path(for: node, in: "thumbnailsV3") else {
                return true
            }

            MEGASdkManager.sharedMEGASdk()?.getThumbnailNode(node, destinationFilePath: destinationFilePath, delegate: MEGAGenericRequestDelegate { [weak self] request, _ in
                if let notificationAttachment = notificationManager.notificationAttachment(for: request.file, withIdentifier: node.base64Handle) {
                    self?.bestAttemptContent?.attachments = [notificationAttachment]
                    self?.postNotification(withError: nil)
                }
            })
            return false
        }

        return true
    }

    func postNotification(withError error: String?) {
        MEGASdkManager.sharedMEGAChatSdk()?.remove(self as MEGAChatNotificationDelegate)

        guard let contentHandler = contentHandler else {
            return
        }
        guard let bestAttemptContent = bestAttemptContent else {
            return
        }

        if let errorString = error {
            MEGALogError(errorString)
            bestAttemptContent.body = AMLocalizedString("You may have new messages", "Content of the notification when there is unknown activity on the Chat")
            bestAttemptContent.sound = nil
        } else {
            if let msgId = msgId, let chatId = chatId {
                MEGAStore.shareInstance()?.insertMessage(msgId, chatId: chatId)
            }
        }

        // Note: As soon as we call the contentHandler, no content can be retrieved from notification center.
        bestAttemptContent.badge = MEGASdkManager.sharedMEGAChatSdk()?.unreadChats as NSNumber?
        contentHandler(bestAttemptContent)
    }

    func path(for node: MEGANode, in sharedSandboxCacheDirectory: String) -> String? {
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

    // MARK: - Lean init, login and connect

    static func initExtensionProcess() {
        setupLogging()

        guard let session = SAMKeychain.password(forService: "MEGA", account: "sessionV3") else {
            return
        }

        NotificationService.session = session
        copyDatabasesFromMainApp()
        initChat()
        loginToMEGA(with: session)
    }

    static func setupLogging() {
        NSSetUncaughtExceptionHandler { (exception) in
            MEGALogError("Exception name: \(exception.name)\nreason: \(String(describing: exception.reason))\nuser info: \(String(describing: exception.userInfo))\n")
            MEGALogError("Stack trace: \(exception.callStackSymbols)")
        }

        if let sharedUserDefaults = UserDefaults.init(suiteName: MEGAGroupIdentifier) {
            if sharedUserDefaults.bool(forKey: "logging") {
                guard let logsFolderURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: MEGAGroupIdentifier)?.appendingPathComponent(MEGAExtensionLogsFolder) else {
                    return
                }
                if !FileManager.default.fileExists(atPath: logsFolderURL.path) {
                    do {
                        try FileManager.default.createDirectory(atPath: logsFolderURL.path, withIntermediateDirectories: false, attributes: nil)
                    } catch {
                        MEGALogError("Error creating logs directory: \(error)")
                        return
                    }
                }
                let logsPath = logsFolderURL.appendingPathComponent("MEGAiOS.NSE.log").path
                MEGALogger.shared()?.startLogging(toFile: logsPath)
#if DEBUG
                MEGASdk.setLogLevel(.max)
                MEGAChatSdk.setCatchException(false)
#else
                MEGASdk.setLogLevel(.fatal)
#endif
                MEGASdk.setLogToConsole(true)
            }
        }
    }

    // As part of the lean init, a cache is required. It will not be generated from scratch.
    static func copyDatabasesFromMainApp() {
        let fileManager = FileManager.default

        guard let applicationSupportDirectoryURL = try? fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
            MEGALogError("Failed to locate/create .applicationSupportDirectory.")
            return
        }

        guard let groupContainerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: MEGAGroupIdentifier) else {
            MEGALogError("No groupContainerURL")
            return
        }

        let groupSupportURL = groupContainerURL.appendingPathComponent(MEGAExtensionGroupSupportFolder)
        if !fileManager.fileExists(atPath: groupSupportURL.path) {
            MEGALogError("No groupSupportURL")
            return
        }

        guard let incomingDate = try? newestMegaclientModificationDateForDirectory(at: groupSupportURL),
            let extensionDate = try? newestMegaclientModificationDateForDirectory(at: applicationSupportDirectoryURL)
            else {
                MEGALogError("Exception in newestMegaclientModificationDateForDirectory")
                return
        }

        if incomingDate <= extensionDate {
            return
        }

        guard let applicationSupportContent = try? fileManager.contentsOfDirectory(atPath: applicationSupportDirectoryURL.path),
            let groupSupportPathContent = try? fileManager.contentsOfDirectory(atPath: groupSupportURL.path)
            else {
                MEGALogError("Error enumerating groupSupportPathContent")
                return
        }

        for filename in applicationSupportContent {
            if filename.contains("megaclient") || filename.contains("karere") {
                let pathToRemove = applicationSupportDirectoryURL.appendingPathComponent(filename).path
                fileManager.mnz_removeItem(atPath: pathToRemove)
            }
        }

        for filename in groupSupportPathContent {
            if filename.contains("megaclient") || filename.contains("karere") {
                let sourceURL = groupSupportURL.appendingPathComponent(filename)
                let destinationURL = applicationSupportDirectoryURL.appendingPathComponent(filename)
                do {
                    try fileManager.copyItem(at: sourceURL, to: destinationURL)
                } catch {
                    MEGALogError("Copy item at path failed with error: \(error)")
                }
            }
        }
    }

    static func newestMegaclientModificationDateForDirectory(at url: URL) throws -> Date {
        let fileManager = FileManager.default
        var newestDate = Date(timeIntervalSince1970: 0)
        var pathContent: [String]
        do {
            pathContent = try fileManager.contentsOfDirectory(atPath: url.path)
        } catch {
            throw error
        }
        for filename in pathContent {
            if filename.contains("megaclient") || filename.contains("karere") {
                do {
                    let attributes = try fileManager.attributesOfItem(atPath: url.appendingPathComponent(filename).path)
                    guard let date = attributes[.modificationDate] as? Date else {
                        continue
                    }
                    if date > newestDate {
                        newestDate = date
                    }
                } catch {
                    throw error
                }
            }
        }
        return newestDate
    }

    static func initChat() {
        if MEGASdkManager.sharedMEGAChatSdk() == nil {
            MEGASdkManager.createSharedMEGAChatSdk()
        }

        var chatInit = MEGASdkManager.sharedMEGAChatSdk()?.initState()
        if chatInit == .notDone {
            chatInit = MEGASdkManager.sharedMEGAChatSdk()?.initKarereLeanMode(withSid: session)
            MEGASdkManager.sharedMEGAChatSdk()?.resetClientId()
            if chatInit == .error {
                MEGASdkManager.sharedMEGAChatSdk()?.logout()
            }
        } else {
            MEGAReachabilityManager.shared()?.reconnect()
        }
    }

    static func loginToMEGA(with session: String) {
        MEGASdkManager.sharedMEGASdk()?.fastLogin(withSession: session, delegate: MEGAGenericRequestDelegate { _, error in
            if error.type != .apiOk {
                MEGALogError("Login error \(error)")
                return
            }

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
            postNotification(withError: nil)
        }
    }

}
