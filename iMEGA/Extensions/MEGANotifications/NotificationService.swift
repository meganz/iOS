
import UserNotifications

class NotificationService: UNNotificationServiceExtension, MEGAChatNotificationDelegate {
    static var session: String!
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    var chatId: UInt64!
    var msgId: UInt64!

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
        
        guard let megadataDictionary = bestAttemptContent?.userInfo["megadata"] as? [String : String],
            let chatIdBase64 = megadataDictionary["chatid"],
            let msgIdBase64 = megadataDictionary["msgid"]
            else {
                postNotification(withError: "No chatId/msgId in the notification")
                return
        }
        chatId = MEGASdk.handle(forBase64UserHandle: chatIdBase64)
        msgId = MEGASdk.handle(forBase64UserHandle: msgIdBase64)
        
        bestAttemptContent?.categoryIdentifier = "nz.mega.chat.message"
        
        if let message = MEGASdkManager.sharedMEGAChatSdk()?.message(forChat: chatId, messageId: msgId) {
            generateNotification(with: message, immediately: false)
            postNotification(withError: nil)
            return
        } else {
            MEGASdkManager.sharedMEGAChatSdk()?.add(self as MEGAChatNotificationDelegate)
            let delegate = MEGAChatGenericRequestDelegate { [weak self] (request, error) in
                if error.type != .MEGAChatErrorTypeOk {
                    self!.postNotification(withError: "Error in pushReceived \(error)")
                    return
                }
            }
            MEGASdkManager.sharedMEGAChatSdk()?.pushReceived(withBeep: true, chatId: chatId, delegate: delegate)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        if let message = MEGASdkManager.sharedMEGAChatSdk()?.message(forChat: chatId, messageId: msgId) {
            generateNotification(with: message, immediately: true)
            postNotification(withError: nil)
        } else {
            postNotification(withError: "Service Extension time will expire")
        }
    }
    
    // MARK: Private
    
    func generateNotification(with message: MEGAChatMessage, immediately: Bool) {
        guard let chatRoom = MEGASdkManager.sharedMEGAChatSdk()?.chatRoom(forChatId: chatId) else {
            return
        }
        let notificationManager = MEGALocalNotificationManager(chatRoom: chatRoom, message: message, silent: false)
        bestAttemptContent?.userInfo = ["chatId" : chatId!]
        bestAttemptContent?.body = notificationManager.bodyString()
        bestAttemptContent?.sound = UNNotificationSound.default
        bestAttemptContent?.title = chatRoom.title
        if chatRoom.isGroup {
            bestAttemptContent?.subtitle = notificationManager.subtitle()
        }
        
        if immediately {
            return
        }
        
        if message.type == .attachment {
            guard let nodeList = message.nodeList else {
                return
            }
            if nodeList.size?.intValue != 1 {
                return
            }
            guard let node = nodeList.node(at: 1) else {
                return
            }
            if !node.hasThumbnail() {
                return
            }
            guard let destinationFilePath = path(for: node, in: "thumbnailsV3") else {
                return
            }
            
            let delegate = MEGAGenericRequestDelegate { (request, error) in
                // TODO: Handle thumbnail
            }
            MEGASdkManager.sharedMEGASdk()?.getThumbnailNode(node, destinationFilePath: destinationFilePath, delegate: delegate)
        }
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
            print(errorString)
            bestAttemptContent.body = NSLocalizedString("You may have new messages", comment: "Content of the notification when there is unknown activity on the Chat")
            bestAttemptContent.sound = nil
        }
        
        // Note: As soon as we call the contentHandler, no content can be retrieved from notification center.
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

    // MARK: Lean init, login and connect
    
    static func initExtensionProcess() {
        guard let tempSession = SAMKeychain.password(forService: "MEGA", account: "sessionV3") else {
            return
        }
        
        session = tempSession
        copyDatabasesFromMainApp()
        initChat()
        loginToMEGA()
    }
    
    // As part of the lean init, a cache is required. It will not be generated from scratch.
    static func copyDatabasesFromMainApp() {
        let fileManager = FileManager.default
        
        guard let applicationSupportDirectoryURL = try? fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
            print("Failed to locate/create .applicationSupportDirectory.")
            return
        }
        
        guard let groupContainerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: MEGAGroupIdentifier) else {
            print("No groupContainerURL")
            return
        }
        
        let groupSupportURL = groupContainerURL.appendingPathComponent(MEGAExtensionGroupSupportFolder)
        if !fileManager.fileExists(atPath: groupSupportURL.path) {
            print("No groupSupportURL")
            return
        }
        
        guard let incomingDate = try? newestMegaclientModificationDateForDirectory(at: groupSupportURL),
            let extensionDate = try? newestMegaclientModificationDateForDirectory(at: applicationSupportDirectoryURL)
            else {
                print("Exception in newestMegaclientModificationDateForDirectory")
                return
        }
        
        if incomingDate <= extensionDate {
            return
        }
        
        guard let applicationSupportContent = try? fileManager.contentsOfDirectory(atPath: applicationSupportDirectoryURL.path),
            let groupSupportPathContent = try? fileManager.contentsOfDirectory(atPath: groupSupportURL.path)
            else {
                print("Error enumerating groupSupportPathContent")
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
                    print("Copy item at path failed with error: \(error)")
                }
            }
        }
    }
    
    static func newestMegaclientModificationDateForDirectory(at url: URL) throws -> Date {
        let fileManager = FileManager.default
        var newestDate = Date(timeIntervalSince1970: 0)
        var pathContent: [String]!
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
    
    static func loginToMEGA() {
        let loginDelegate = MEGAGenericRequestDelegate { (request, error) in
            if error.type != .apiOk {
                print("Login error \(error)")
                return
            }
            
            MEGASdkManager.sharedMEGAChatSdk()?.connectInBackground()
        }
        MEGASdkManager.sharedMEGASdk()?.fastLogin(withSession: session, delegate: loginDelegate)
    }
    
    // MARK: MEGAChatNotificationDelegate
    
    func onChatNotification(_ api: MEGAChatSdk, chatId: UInt64, message: MEGAChatMessage) {
        if chatId != self.chatId || message.messageId != self.msgId {
            print("onChatNotification for a different message")
            return
        }
        
        generateNotification(with: message, immediately: false)
        postNotification(withError: nil)
    }

}
