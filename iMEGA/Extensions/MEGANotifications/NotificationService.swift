import ChatRepo
import Firebase
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n
import MEGASwift
import SAMKeychain
import UserNotifications

class NotificationService: UNNotificationServiceExtension, MEGAChatNotificationDelegate {
    private static let session = Atomic<String?>(wrappedValue: nil)
    private static let setLogToConsole = Atomic<Bool>(wrappedValue: false)
    
    private static let genericBody = Strings.Localizable.youMayHaveNewMessages
    private let memoryPressureSource = DispatchSource.makeMemoryPressureSource(
        eventMask: .all,
        queue: nil
    )
    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?
    
    private var chatId: UInt64?
    private var msgId: UInt64?
    private var megatime: TimeInterval? // set by the api
    private var megatime2: TimeInterval? // set by the pushserver
    private var pushReceivedTi = Date().timeIntervalSince1970
    
    private var waitingForThumbnail = false
    private var waitingForUserAttributes = false
    
    private lazy var analyticsEventUseCase: AnalyticsEventUseCase = {
        AnalyticsEventUseCase(repository: AnalyticsRepository(sdk: MEGASdk.sharedNSESdk))
    }()
    
    override init() {
        super.init()
        AppEnvironmentConfigurator.configAppEnvironment()
        FirebaseApp.configure()
        UncaughtExceptionHandler.registerHandler()
        NotificationService.setupLogging()
        MEGALogDebug("NSE Init, pid: \(ProcessInfo.processInfo.processIdentifier)")
        observeAndLogMemoryPressure()
    }

    // MARK: - UNNotificationServiceExtension

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        MEGALogInfo("Push received: request identifier: \(request.identifier)\n user info: \(request.content.userInfo)")

        if request.content.isStartScheduledMeetingNotification == true {
            processStartScheduledMeetingNotification(withContentHandler: contentHandler, request: request)
            return
        }
        
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        removePreviousGenericNotifications()
        
        megatime = request.content.userInfo["megatime"] as? TimeInterval
        megatime2 = request.content.userInfo["megatime2"] as? TimeInterval
        
        guard let session = SAMKeychain.password(forService: "MEGA", account: "sessionV3") else {
            postNotification(withError: "No session in the Keychain")
            return
        }
        
        if let currentSession = NotificationService.session.wrappedValue {
            guard currentSession == session else {
                MEGALogDebug("Restart extension process: NSE session != Keychain session")
                restartExtensionProcess(with: session)
                return
            }
            
            if let sharedUserDefaults = UserDefaults.init(suiteName: MEGAGroupIdentifier),
               sharedUserDefaults.bool(forKey: MEGAInvalidateNSECache) {
                MEGALogDebug("Restart extension process: app invalidates the NSE cache")
                restartExtensionProcess(with: session)
                return
            }
        } else {
            guard NotificationService.initExtensionProcess(with: session) else {
                return
            }
            NotificationService.session.mutate { $0 = session }
        }
        
        processNotification()
    }

    override func serviceExtensionTimeWillExpire() {
        MEGALogDebug("Service extension time will expire")
        if let chatId = chatId, let msgId = msgId, let message = MEGAChatSdk.shared.message(forChat: chatId, messageId: msgId) {
            if message.type == .unknown {
                postNotification(withError: "Unknown message")
            } else {
                let error = !generateNotification(with: message, immediately: true)
                postNotification(withError: error ? "No chat room for message" : nil, message: message)
            }
        } else {
            analyticsEventUseCase.sendAnalyticsEvent(.nse(.willExpireAndMessageNotFound))
            postNotification(withError: "Service Extension time will expire and message not found")
        }
    }

    // MARK: - Private
    
    private func generateNotification(with message: MEGAChatMessage, immediately: Bool) -> Bool {
        guard let chatId = chatId, let chatRoom = MEGAChatSdk.shared.chatRoom(forChatId: chatId) else {
            return false
        }
        let notificationManager = MEGALocalNotificationManager(chatRoom: chatRoom, message: message)
        bestAttemptContent?.userInfo = ["chatId": chatId, "msgId": message.messageId]
        bestAttemptContent?.body = notificationManager.bodyString()
        bestAttemptContent?.sound = UNNotificationSound.default
        let displayName = chatRoom.userDisplayName(forUserHandle: message.userHandle)
        if chatRoom.isGroup {
            bestAttemptContent?.title = chatRoom.title ?? ""
        }
        setupDisplayName(displayName: displayName, for: chatRoom)
        
        let chatIdBase64 = MEGASdk.base64Handle(forUserHandle: chatId) ?? ""
        bestAttemptContent?.threadIdentifier = chatIdBase64
        
        if immediately {
            return true
        }
        
        var readyToPost = true
        if displayName == nil {
            MEGAChatSdk.shared.loadUserAttributes(forChatId: chatId, usersHandles: [message.userHandle] as [NSNumber], delegate: ChatRequestDelegate { [weak self] result in
                guard case .success = result,
                      let chatRoom = MEGAChatSdk.shared.chatRoom(forChatId: chatId) else {
                    return
                }
                let displayName = chatRoom.userDisplayName(forUserHandle: message.userHandle)
                self?.setupDisplayName(displayName: displayName, for: chatRoom)
                self?.waitingForUserAttributes = false
                if !(self?.waitingForThumbnail ?? true) {
                    self?.postNotification(withError: nil, message: message)
                }
            })
            readyToPost = false
            waitingForUserAttributes = true
        }
        
        if message.type == .attachment {
            guard let nodeList = message.nodeList else {
                return readyToPost
            }
            if nodeList.size != 1 {
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

            MEGASdk.sharedNSE.getThumbnailNode(node, destinationFilePath: destinationFilePath, delegate: RequestDelegate { [weak self] result in
                guard case let .success(request) = result else {
                    return
                }
                
                if let base64Handle = node.base64Handle,
                   let notificationAttachment = notificationManager.notificationAttachment(for: request.file ?? "", withIdentifier: base64Handle) {
                    self?.bestAttemptContent?.attachments = [notificationAttachment]
                    self?.waitingForThumbnail = false
                    if !(self?.waitingForUserAttributes ?? true) {
                        self?.postNotification(withError: nil, message: message)
                    }
                }
            })
            readyToPost = false
            waitingForThumbnail = true
        }
        
        return readyToPost
    }
    
    private func postNotification(withError error: String?, message: MEGAChatMessage? = nil) {
        if let memoryUsage = MemoryUsage() {
            MEGALogDebug("Memory usage:\(memoryUsage.formattedDescription)")
        }
        MEGAChatSdk.shared.remove(self as (any MEGAChatNotificationDelegate))

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
            if let msgId = msgId, let chatId = chatId {
                let base64messageId = MEGASdk.base64Handle(forUserHandle: msgId) ?? ""
                let base64chatId = MEGASdk.base64Handle(forUserHandle: chatId) ?? ""
                MEGALogDebug("Post notification: message \(base64messageId) found in chat \(base64chatId)")
                MEGAStore.shareInstance().insertMessage(msgId, chatId: chatId)
            }
        }
        
        MEGAChatSdk.shared.saveCurrentState()
        
        // Note: As soon as we call the contentHandler, no content can be retrieved from notification center.
        if let sharedUserDefaults = UserDefaults(suiteName: MEGAGroupIdentifier) {
            let badgeCount = sharedUserDefaults.integer(forKey: MEGAApplicationIconBadgeNumber)
            sharedUserDefaults.set(badgeCount + 1, forKey: MEGAApplicationIconBadgeNumber)
            bestAttemptContent.badge = badgeCount + 1 as NSNumber
        }
        
        checkDelaysWithMessage(message)
        
        if (message?.status == .seen) || message?.isDeleted ?? false {
            contentHandler(UNNotificationContent()) // Don't deliver the notification to the user.
        } else {
            contentHandler(bestAttemptContent)
        }
    }
    
    private func removePreviousGenericNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
            var identifiers = [String]()
            for request in requests where request.content.body == NotificationService.genericBody {
                identifiers.append(request.identifier)
            }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        }
        UNUserNotificationCenter.current().getDeliveredNotifications { (notifications) in
            var identifiers = [String]()
            for notification in notifications where notification.request.content.body == NotificationService.genericBody {
                identifiers.append(notification.request.identifier)
            }
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
        }
    }
    
    private func processNotification() {
        MEGALogDebug("Process notification")
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
        
        if let childContext = MEGAStore.shareInstance().stack.newBackgroundContext() {
            if let moMessage = MEGAStore.shareInstance().fetchMessage(msgId: msgId, chatId: chatId, context: childContext) {
                MEGAStore.shareInstance().delete(message: moMessage, context: childContext)
                postNotification(withError: "Already notified")
            }
        }
        
        if let message = MEGAChatSdk.shared.message(forChat: chatId, messageId: msgId) {
            if message.type != .unknown && generateNotification(with: message, immediately: false) {
                MEGALogDebug("Message exists in karere cache")
                postNotification(withError: nil, message: message)
                return
            }
        }
        
        MEGAChatSdk.shared.add(self as (any MEGAChatNotificationDelegate))
        MEGAChatSdk.shared.pushReceived(withBeep: true, chatId: chatId, delegate: ChatRequestDelegate { [weak self] result in
            guard case let .failure(error) = result else { return }
            self?.postNotification(withError: "Error in pushReceived \(error)")
        })
    }
    
    private func restartExtensionProcess(with session: String) {
        NotificationService.session.mutate { $0 = nil }
        MEGASdk.sharedNSE.localLogout(with: RequestDelegate { result in
            guard case .success = result else {
                if case let .failure(error) = result {
                    self.postNotification(withError: "SDK error in localLogout \(error)")
                }
                return
            }
            MEGAChatSdk.shared.localLogout(with: ChatRequestDelegate { result in
                guard case .success = result else {
                    if case let .failure(error) = result {
                        self.postNotification(withError: "MEGAChat error in localLogout \(error)")
                    }
                    return
                }
                if NotificationService.initExtensionProcess(with: session) {
                    NotificationService.session.mutate { $0 = session }
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
        
        guard let base64Handle = node.base64Handle else {
            return nil
        }
        
        do {
            try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
            return destinationURL.appendingPathComponent(base64Handle).path
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
        }
    }
    
    /// Check delays between chatd, api, pushserver and Apple/device/NSE.
    ///
    /// 1. chatd -> api
    /// 2. api -> pushserver
    /// 3. pushserver -> Apple/device/NSE
    ///
    /// And send an event to stats if needed (delay > 20.0).
    /// - Parameters:
    ///    - message: chat message retrieved from Karere.
    private func checkDelaysWithMessage(_ message: MEGAChatMessage?) {
        if message != nil,
           let megatime = megatime,
           let msgTime = message?.timestamp?.timeIntervalSince1970 {
            if (megatime - msgTime) > MEGAMinDelayInSecondsToSendAnEvent {
                #if !DEBUG
                analyticsEventUseCase.sendAnalyticsEvent(.nse(.delayBetweenChatdAndApi))
                #endif
                MEGALogWarning("Delay between chatd and api")
            }
            MEGALogDebug("Delay between chatd and api: \(megatime - msgTime)")
        }
        
        if let megatime = megatime,
            let megatime2 = megatime2 {
            if (megatime2 - megatime) > MEGAMinDelayInSecondsToSendAnEvent {
                #if !DEBUG
                analyticsEventUseCase.sendAnalyticsEvent(.nse(.delayBetweenApiAndPushserver))
                #endif
                MEGALogWarning("Delay between api and pushserver")
            }
            MEGALogDebug("Delay between api and pushserver: \(megatime2 - megatime)")
        }
        
        if let megatime2 = megatime2 {
            if (pushReceivedTi - megatime2) > MEGAMinDelayInSecondsToSendAnEvent {
                #if !DEBUG
                analyticsEventUseCase.sendAnalyticsEvent(.nse(.delayBetweenPushserverAndNSE))
                #endif
                MEGALogWarning("Delay between pushserver and Apple/device/NSE")
            }
            MEGALogDebug("Delay between pushserver and Apple/device/NSE: \(pushReceivedTi - megatime2)")
        }
    }

    // MARK: - Lean init, login and connect
    
    private static func initExtensionProcess(with session: String) -> Bool {
        MEGALogDebug("Init extension process")
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
        if !setLogToConsole.wrappedValue {
            setLogToConsole.mutate { $0 = true }
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
            MEGALogError("Failed to locate/create \(nseCacheURL.path) directory")
        }
        
        guard let nseCacheContent = try? fileManager.contentsOfDirectory(atPath: nseCacheURL.path),
            let groupSupportPathContent = try? fileManager.contentsOfDirectory(atPath: groupSupportURL.path)
            else {
                MEGALogError("Error enumerating groupSupportPathContent")
                return
        }
        
        let cacheSessionName = session.dropFirst(Int(MEGADropFirstCharactersFromSession))
        for filename in nseCacheContent where filename.contains(cacheSessionName) {
            let pathToRemove = nseCacheURL.appendingPathComponent(filename).path
            fileManager.mnz_removeItem(atPath: pathToRemove)
        }
        
        for filename in groupSupportPathContent where filename.contains(cacheSessionName) {
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
    
    private static func initChat(with session: String) -> Bool {
        MEGALogDebug("Init chat")

        var chatInit = MEGAChatSdk.shared.initState()
        if chatInit == .notDone {
            MEGALogDebug("Init state == notDone -> Init Karere Lean Mode")
            chatInit = MEGAChatSdk.shared.initKarereLeanMode(withSid: session)
            if chatInit == .error {
                MEGALogError("Init Karere Lean Mode fails -> logout")
                MEGAChatSdk.shared.logout()
                return false
            }
            MEGALogDebug("Reset client Id")
            MEGAChatSdk.shared.resetClientId()
        } else {
            MEGALogDebug("Init state != notDone -> Reconnect")
            MEGASdk.sharedNSE.reconnect()
            MEGAChatSdk.shared.reconnect()
        }
        
        MEGAChatSdk.shared.setBackgroundStatus(true)
        return true
    }
    
    private static func loginToMEGA(with session: String) {
        MEGALogDebug("Login to MEGA")
        MEGASdk.sharedNSE.fastLogin(withSession: session, delegate: RequestDelegate { result in
            guard case let .failure(error) = result else {
                return
            }
            
            MEGALogError("Login error \(error)")
        })
    }

    // MARK: - MEGAChatNotificationDelegate

    func onChatNotification(_ api: MEGAChatSdk, chatId: UInt64, message: MEGAChatMessage) {
        if chatId != self.chatId || message.messageId != self.msgId {
            let base64messageId = MEGASdk.base64Handle(forUserHandle: message.messageId) ?? ""
            let base64chatId = MEGASdk.base64Handle(forUserHandle: chatId) ?? ""
            MEGALogWarning("On chat: \(base64chatId) notification for message: \(base64messageId) different from the one that trigger the push")
            return
        }

        if generateNotification(with: message, immediately: false) {
            postNotification(withError: nil, message: message)
        }
    }

    private func observeAndLogMemoryPressure() {
        memoryPressureSource.setEventHandler { [weak self] in
            guard let self else { return }
            
            let event: DispatchSource.MemoryPressureEvent  = memoryPressureSource.mask
            
            switch event {
            case DispatchSource.MemoryPressureEvent.normal:
                MEGALogDebug("Memory pressure: normal")
            case DispatchSource.MemoryPressureEvent.warning:
                MEGALogWarning("Memory pressure: warning")
            case DispatchSource.MemoryPressureEvent.critical:
                MEGALogError("Memory pressure: critical")
            default:
                break
            }
            
            if let usage = MemoryUsage() {
                MEGALogDebug("Pressure Warning: Memory usage:\(usage.formattedDescription)")
            }
            
        }
        memoryPressureSource.resume()
    }
}
