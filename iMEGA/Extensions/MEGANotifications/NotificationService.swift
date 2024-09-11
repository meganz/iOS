import ChatRepo
import Firebase
import MEGADomain
import MEGAL10n
import MEGASDKRepo
import SAMKeychain
import UserNotifications

class NotificationService: UNNotificationServiceExtension, MEGAChatNotificationDelegate {
    private static var session: String?
    private static var setLogToConsole = false
    private static let genericBody = Strings.Localizable.youMayHaveNewMessages
    private let memoryPressureSource = DispatchSource.makeMemoryPressureSource(
        eventMask: .all,
        queue: nil
    )
    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?
    private var chatMessageData: ChatMessageData?
    
    private var megatime: TimeInterval? // set by the api
    private var megatime2: TimeInterval? // set by the pushserver
    private var pushReceivedTi = Date().timeIntervalSince1970
    private let userDefaults = UserDefaults.init(suiteName: MEGAGroupIdentifier)!
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
        MEGALogDebug("Adding chatSDK delegate")
        MEGAChatSdk.shared.add(self)
    }
    
    deinit {
        MEGAChatSdk.shared.remove(self)
    }
    
    // MARK: - UNNotificationServiceExtension
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        MEGALogDebug("Push received: request identifier: \(request.identifier)\n user info: \(request.content.userInfo)")
        
        if request.content.isStartScheduledMeetingNotification == true {
            processStartScheduledMeetingNotification(withContentHandler: contentHandler, request: request)
            return
        }
        
        self.contentHandler = contentHandler
        self.bestAttemptContent = Self.content(from: request)
        
        if let bestAttemptContent {
            self.chatMessageData = Self.chatMessageData(from: bestAttemptContent)
            MEGALogDebug("Chat Message data set: \(String(describing: chatMessageData))")
        }
        
        removePreviousGenericNotifications()
        
        megatime = request.content.userInfo["megatime"] as? TimeInterval
        megatime2 = request.content.userInfo["megatime2"] as? TimeInterval
        
        guard let session = SAMKeychain.password(forService: "MEGA", account: "sessionV3") else {
            MEGALogError("didReceive, no session in keychain")
            postNotification(withError: "No session in the Keychain")
            return
        }
        
        guard
            let chatMessageData
        else {
            MEGALogError("didReceive, missing chat message data")
            postNotification(withError: "Malformed request")
            return
        }
        
        if let currentSession = NotificationService.session {
            MEGALogDebug("We have session")
            guard currentSession == session else {
                MEGALogDebug("Restart extension process: NSE session != Keychain session")
                // restartExtensionProcess calls processNotification internally
                restartExtensionProcess(with: session, chatId: chatMessageData.chatId)
                return
            }
            
            if userDefaults.bool(forKey: MEGAInvalidateNSECache) {
                
                MEGALogDebug("Restart extension process: app invalidates the NSE cache")
                // restartExtensionProcess calls processNotification internally
                restartExtensionProcess(with: session, chatId: chatMessageData.chatId)
                return
            } else {
                MEGALogWarning("We have session but MEGAInvalidateNSECache is FALSE, initialising without DB copy ...")
                // my guess we should init process but do not copy DB
                NotificationService.initExtensionProcess(
                    delegate: self,
                    userDefaults: userDefaults,
                    loginRequired: { Self.mustLoginToProcessPush(chatId: chatMessageData.chatId) },
                    copyDBRequired: false,
                    with: session,
                    completion: { success in
                        if success {
                            MEGALogDebug("Did receive with session, login succeeded")
                            NotificationService.session = session
                            self.processNotification()
                        } else {
                            MEGALogError("Did receive with session, login failed")
                            self.postNotification(withError: "Login failed [restartExtensionProcess]")
                        }
                    }
                )
            }
        } else {
            
            NotificationService.initExtensionProcess(
                delegate: self,
                userDefaults: userDefaults,
                loginRequired: { Self.mustLoginToProcessPush(chatId: chatMessageData.chatId )},
                copyDBRequired: true,
                with: session,
                completion: { [weak self] success in
                    if success {
                        MEGALogDebug("didReceive, login success")
                        NotificationService.session = session
                        self?.processNotification()
                    } else {
                        MEGALogError("didReceive, login failed")
                        self?.postNotification(withError: "login failed")
                    }
                })
        }
    }
    
    private func message(for data: ChatMessageData) -> MEGAChatMessage? {
        MEGAChatSdk.shared.message(
            forChat: data.chatId,
            messageId: data.messageId
        )
    }
    
    override func serviceExtensionTimeWillExpire() {
        MEGALogDebug("Service extension time will expire")
        if
            let chatMessageData,
            let message = message(for: chatMessageData)
        {
            if message.type == .unknown {
                postNotification(withError: "Unknown message type")
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
    // swiftlint:disable cyclomatic_complexity
    private func generateNotification(with message: MEGAChatMessage, immediately: Bool) -> Bool {
        MEGALogDebug("generateNotification: messageId \(Self.convertToBase64(message.messageId)), immediately \(immediately)")
        guard
            let chatMessageData,
            let chatRoom = MEGAChatSdk.shared.chatRoom(forChatId: chatMessageData.chatId)
        else {
            if let chatId = chatMessageData?.chatId {
                MEGALogError("generateNotification: no chatRoom for chat id = \(Self.convertToBase64(chatId)))")
            } else {
                MEGALogError("generateNotification: no chatId")
            }
            return false
        }
        let notificationManager = MEGALocalNotificationManager(chatRoom: chatRoom, message: message)
        bestAttemptContent?.userInfo = ["chatId": chatMessageData.chatId, "msgId": message.messageId]
        bestAttemptContent?.body = notificationManager.bodyString()
        bestAttemptContent?.sound = UNNotificationSound.default
        let displayName = chatRoom.userDisplayName(forUserHandle: message.userHandle)
        if chatRoom.isGroup {
            bestAttemptContent?.title = chatRoom.title ?? ""
        }
        setupDisplayName(displayName: displayName, for: chatRoom)
        
        bestAttemptContent?.threadIdentifier = chatMessageData.chatIdBase64
        
        if immediately {
            return true
        }
        
        var readyToPost = true
        if displayName == nil {
            MEGAChatSdk.shared.loadUserAttributes(forChatId: chatMessageData.chatId, usersHandles: [message.userHandle] as [NSNumber], delegate: ChatRequestDelegate { [weak self] result in
                guard case .success = result,
                      let chatRoom = MEGAChatSdk.shared.chatRoom(forChatId: chatMessageData.chatId) else {
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
    // swiftlint:enable cyclomatic_complexity
    private func postNotification(withError error: String?, message: MEGAChatMessage? = nil) {
        MEGALogDebug("postNotification: \(String(describing: error)) message is not nil: \(message != nil)")
        
        guard let contentHandler = contentHandler else {
            MEGALogError("contentHandler is nil")
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
            if let chatMessageData {
                MEGALogDebug("Post notification: message \(chatMessageData.messageIdBase64) found in chat \(chatMessageData.chatIdBase64)")
                MEGAStore.shareInstance().insertMessage(chatMessageData.messageId, chatId: chatMessageData.chatId)
            }
        }
        
        MEGAChatSdk.shared.saveCurrentState()
        
        // Note: As soon as we call the contentHandler, no content can be retrieved from notification center.
        let badgeCount = userDefaults.integer(forKey: MEGAApplicationIconBadgeNumber)
        userDefaults.set(badgeCount + 1, forKey: MEGAApplicationIconBadgeNumber)
        bestAttemptContent.badge = badgeCount + 1 as NSNumber
        
        checkDelaysWithMessage(message)
        
        if (message?.status == .seen) || message?.isDeleted ?? false {
            MEGALogWarning("Message seen or deleted, will be silenced")
            contentHandler(UNNotificationContent()) // Don't deliver the notification to the user.
        } else {
            MEGALogDebug("Render best attempt")
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
        // this code assumes we are called after login succeeded
        assert(NotificationService.session != nil, "session must be set")
        MEGALogDebug("Process notification")
        guard
            let bestAttemptContent,
            let chatMessage = chatMessageData
        else {
            postNotification(withError: "No chatId/msgId in the notification")
            return
        }
        
        MEGALogDebug("Checking if has cached chat data")
        guard Self.hasLocalDataForChat(chatId: chatMessage.chatId) else {
            MEGALogDebug("No cached chat data")
            postNotification(withError: "No local data for chat saved")
            return
        }
        
        MEGALogDebug("Has cached chat data")
        
        bestAttemptContent.categoryIdentifier = "nz.mega.chat.message"
        
        if let childContext = MEGAStore.shareInstance().stack.newBackgroundContext() {
            if let moMessage = MEGAStore.shareInstance().fetchMessage(msgId: chatMessage.messageId, chatId: chatMessage.chatId, context: childContext) {
                MEGAStore.shareInstance().delete(message: moMessage, context: childContext)
                postNotification(withError: "Already notified")
            }
        }
        
        if let message = MEGAChatSdk.shared.message(forChat: chatMessage.chatId, messageId: chatMessage.messageId) {
            // it's possible that once we are logged in , chat SDK already fetched message so we can display it now
            // and we can be finished processing
            MEGALogDebug("message in chat sdk exists")
            guard message.type != .unknown else {
                MEGALogError("Message exists in cache but unknown type or generate failed")
                postNotification(withError: "Unknown type")
                return
            }
            
            if generateNotification(with: message, immediately: false) {
                MEGALogDebug("generate cached success, will post")
                postNotification(withError: nil, message: message)
                return
            } else {
                MEGALogError("Message exists in cache but generate failed")
            }
        }
        
        reportPushMessageReceived(chatId: chatMessage.chatId)
    }
    
    private static func hasLocalDataForChat(chatId: ChatIdEntity) -> Bool {
        // this method must be called after MEGAChatSDK was initialized
        let hasLocalData = MEGAChatSdk.shared.chatRoom(forChatId: chatId) != nil
        MEGALogDebug("ChatSDk \(hasLocalData ? "has" : "do not have" ) data for chat room id: \(convertToBase64(chatId))")
        return hasLocalData
    }
    
    private static func mustLoginToProcessPush(chatId: ChatIdEntity) -> Bool {
        // If we do NOT have local data, then we can avoid login and
        // jump directly to show generic message.
        // Ergo, we must login before we can process message further, if we
        // have local data saved for given chat
        hasLocalDataForChat(chatId: chatId)
    }
    
    private func restartExtensionProcess(
        with session: String,
        chatId: ChatIdEntity
    ) {
        MEGALogDebug("Restarting extension process")
        NotificationService.session = nil
        MEGASdk.sharedNSE.localLogout(with: RequestDelegate {[weak self] result in
            guard let self else { return }
            guard case .success = result else {
                if case let .failure(error) = result {
                    self.postNotification(withError: "SDK error in localLogout \(error)")
                }
                return
            }
            MEGAChatSdk.shared.localLogout(with: ChatRequestDelegate {[weak self] result in
                guard let self else { return }
                guard case .success = result else {
                    if case let .failure(error) = result {
                        self.postNotification(withError: "MEGAChat error in localLogout \(error)")
                    }
                    return
                }
                MEGALogDebug("Restart extension, login start")
                NotificationService.initExtensionProcess(
                    delegate: self,
                    userDefaults: userDefaults,
                    loginRequired: { Self.mustLoginToProcessPush(chatId: chatId) },
                    copyDBRequired: true,
                    with: session,
                    completion: { success in
                        if success {
                            MEGALogDebug("Restart extension, login succeeded")
                            NotificationService.session = session
                            self.processNotification()
                        } else {
                            MEGALogError("Restart extension, login failed")
                            self.postNotification(withError: "Login failed [restartExtensionProcess]")
                        }
                    }
                )
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
    private static func initExtensionProcess(
        delegate: any MEGAChatNotificationDelegate,
        userDefaults: UserDefaults,
        loginRequired: () -> Bool,
        copyDBRequired: Bool,
        with session: String,
        completion: @escaping (_ success: Bool) -> Void
    ) {
        
        MEGALogDebug("Init extension process")
        if copyDBRequired {
            copyDatabasesFromMainApp(with: session)
        }
        
        /*
         initialisation process for SDK/ChatSDK in NSE:
         1. init SDK (it's a singleton)
         2. copy databases (if needed)
         3. init lean chatSDK
         a). if init failed, we bail and exit
         b). we have give it a chance to early exit if ChatSDK can't render
         push and we'll show generic message
         4. call fast login SDK
         a). if we were reusing NSE process, we reconnect SDKs
         5. when login SDK succeeds -> start processing incoming chat message notifications
         a) only now can call pushReceived
         */
        
        var shouldReconnect = false
        var chatInit = MEGAChatSdk.shared.initState()
        if chatInit == .notDone {
            MEGALogDebug("Init state == notDone -> Init Karere Lean Mode")
            chatInit = MEGAChatSdk.shared.initKarereLeanMode(withSid: session)
            
            MEGALogDebug("Reset client Id")
            MEGAChatSdk.shared.resetClientId()
        } else {
            MEGALogDebug("Will reconnect")
            shouldReconnect = true
        }
        
        guard chatInit != .error else {
            MEGALogError("Init Karere Lean Mode fails -> logout")
            MEGAChatSdk.shared.logout()
            completion(false)
            return
        }
        
        // Here, we are given a chance to early out in case
        // ChatSDK has no data regarding the chat id we are looking for.
        // ChatSDK running in NSE cannot currently fetch data of chats it does not have stored,
        // so we can jump directly to showing user generic message
        // Hence, if our SDK DB has cached given chat data, we must login to process the message
        MEGALogDebug("Checking if need to proceed to login")
        guard loginRequired() else {
            MEGALogDebug("Login not needed")
            completion(true)
            return
        }
        MEGALogDebug("Login needed")
        
        loginToMEGA(with: session,
                    completion: { success in
            guard success else {
                MEGALogError("Init loginToMEGA failed")
                completion(false)
                return
            }
            if shouldReconnect {
                MEGALogDebug("Init state != notDone -> Reconnect")
                MEGASdk.sharedNSE.reconnect()
                MEGAChatSdk.shared.reconnect()
            }
            
            MEGAChatSdk.shared.setBackgroundStatus(true)
            
            MEGALogDebug("Init chat success")
            
            MEGALogDebug("set false MEGAInvalidateNSECache")
            userDefaults.set(false, forKey: MEGAInvalidateNSECache)
            
            completion(true)
        })
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
    
    // this method can be called multiple time so we need to check if
    // message being passed in is the one NSE was allocated to handle
    func onChatNotification(_ api: MEGAChatSdk, chatId: UInt64, message: MEGAChatMessage) {
        MEGALogDebug("onChatNotification chatId: \(Self.convertToBase64(chatId)) messageId: \(Self.convertToBase64(message.messageId))")
        
        guard
            let chat = chatMessageData
        else {
            MEGALogWarning("onChatNotification before chatMessageData saved")
            return
        }
        
        guard
            chatId == chat.chatId && message.messageId == chat.messageId else {
            MEGALogWarning("On chat: \(String(describing: chatMessageData?.chatIdBase64)) notification for message: \(String(describing: chatMessageData?.messageIdBase64)) different from the one that trigger the push")
            return
        }
        
        MEGALogDebug("onChatNotification generateNotification")
        if generateNotification(with: message, immediately: false) {
            MEGALogDebug("onChatNotification will post")
            postNotification(withError: nil, message: message)
        } else {
            MEGALogDebug("onChatNotification generateNotification failed")
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
    
    /// it's necessary to do SDK call pushReceived ONLY _after_ LOGIN requested succeeded to avoid race condition
    private static func loginToMEGA(with session: String, completion: @escaping (_ success: Bool) -> Void) {
        MEGALogDebug("Login to MEGA")
        MEGASdk.sharedNSE.fastLogin(withSession: session, delegate: RequestDelegate { result in
            switch result {
            case let .failure(error):
                MEGALogError("Login error \(error)")
                completion(false)
            case .success:
                MEGALogDebug("Login success")
                completion(true)
            }
        })
    }
    
    private func reportPushMessageReceived(chatId: ChatIdEntity) {
        MEGALogDebug("reportPushMessageReceived \(Self.convertToBase64(chatId))")
        if let memoryUsage = MemoryUsage() {
            MEGALogDebug("Memory usage:\(memoryUsage.formattedDescription)")
        }
        MEGAChatSdk.shared.pushReceived(
            withBeep: true,
            chatId: chatId,
            delegate: ChatRequestDelegate { [weak self] result in
                guard let self else { return }
                switch result {
                case .success:
                    processPushReceivedSuccess()
                case .failure(let error):
                    if error.type == .MegaChatErrorTypeExist {
                        MEGALogError("pushReceived: previous PUSH is being processed")
                    } else {
                        MEGALogError("pushReceived callback failure \(String(describing: error.name))")
                    }
                    postNotification(withError: "Error in pushReceived \(error)")
                }
            })
    }
    
    private func processPushReceivedSuccess() {
        guard let chatMessageData else {
            MEGALogError("No chatMessageData saved")
            return
        }
        guard let message = message(for: chatMessageData) else {
            MEGALogError("No data in SDK for \(chatMessageData)")
            return
        }
        
        MEGALogDebug("Found \(chatMessageData)")
        if generateNotification(with: message, immediately: false) {
            MEGALogDebug("Will post \(chatMessageData)")
            postNotification(withError: nil, message: message)
        } else {
            MEGALogDebug("Generate failed \(chatMessageData)")
        }
    }
    
    private func observeAndLogMemoryPressure() {
        memoryPressureSource.setEventHandler { [weak self] in
            guard let self else { return }
            
            let event: DispatchSource.MemoryPressureEvent  = memoryPressureSource.mask
            print(event)
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
    
    struct ChatMessageData: CustomDebugStringConvertible {
        var chatId: ChatIdEntity
        var chatIdBase64: String
        
        var messageId: UInt64
        var messageIdBase64: String
        
        var debugDescription: String {
            "message \(messageIdBase64) in chat \(chatIdBase64)"
        }
    }
    
    private static func content(from request: UNNotificationRequest) -> UNMutableNotificationContent? {
        guard let content = (request.content.mutableCopy() as? UNMutableNotificationContent) else {
            MEGALogError("request is not in valid type")
            return nil
        }
        return content
    }
    
    private static func convertToBase64(_ id: UInt64) -> String {
        MEGASdk.base64Handle(forUserHandle: id) ?? ""
    }
    
    private static func convertFromBase64(_ base64: String) -> UInt64 {
        MEGASdk.handle(forBase64UserHandle: base64)
    }
    
    private static func chatMessageData(from content: UNMutableNotificationContent) -> ChatMessageData? {
        guard
            let dict = content.userInfo["megadata"] as? [String: String],
            let chatIdBase64 = dict["chatid"],
            let msgIdBase64 = dict["msgid"]
        else {
            MEGALogError("Malformed megadata field")
            return nil
        }
        
        return .init(
            chatId: Self.convertFromBase64(chatIdBase64),
            chatIdBase64: chatIdBase64,
            messageId: Self.convertFromBase64(msgIdBase64),
            messageIdBase64: msgIdBase64
        )
    }
    
}
