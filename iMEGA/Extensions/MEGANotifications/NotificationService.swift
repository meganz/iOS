
import UserNotifications

class NotificationService: UNNotificationServiceExtension, MEGAChatDelegate {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    var session: String!
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let tempSession = SAMKeychain.password(forService: "MEGA", account: "sessionV3") {
            session = tempSession
        } else {
            postNotification()
            return
        }
        
        copyDatabasesFromMainApp()
        initChat()
        loginToMEGA()
        MEGASdkManager.sharedMEGAChatSdk()?.add(self)
    }
    
    override func serviceExtensionTimeWillExpire() {
        postNotification()
    }
    
    // MARK: Private
    
    func postNotification() {
        // TODO: We may show here a notification letting the user know there are pending notifications whose content is not available
        
        guard let contentHandler = contentHandler else {
            return
        }
        
        guard let bestAttemptContent = bestAttemptContent else {
            return
        }
        
        contentHandler(bestAttemptContent)
    }

    // MARK: Lean init, login and connect
    
    // As part of the lean init, a cache is required. It will not be generated from scratch.
    func copyDatabasesFromMainApp() {
        let fileManager = FileManager.default
        
        guard let applicationSupportDirectoryURL = try? fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
            print("Failed to locate/create .applicationSupportDirectory.")
            postNotification()
            return
        }
        
        guard let groupContainerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: MEGAGroupIdentifier) else {
            postNotification()
            return
        }
        
        let groupSupportURL = groupContainerURL.appendingPathComponent(MEGAExtensionGroupSupportFolder)
        if !fileManager.fileExists(atPath: groupSupportURL.path) {
            postNotification()
            return
        }
        
        guard let incomingDate = try? newestMegaclientModificationDateForDirectory(at: groupSupportURL),
            let extensionDate = try? newestMegaclientModificationDateForDirectory(at: applicationSupportDirectoryURL)
            else {
                postNotification()
                return
        }
        
        if incomingDate <= extensionDate {
            return
        }
        
        guard let applicationSupportContent = try? fileManager.contentsOfDirectory(atPath: applicationSupportDirectoryURL.path),
            let groupSupportPathContent = try? fileManager.contentsOfDirectory(atPath: groupSupportURL.path)
            else {
                postNotification()
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
    
    func newestMegaclientModificationDateForDirectory(at url: URL) throws -> Date {
        let fileManager = FileManager.default
        var newestDate = Date.init(timeIntervalSince1970: 0)
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
    
    func initChat() {
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
    
    func loginToMEGA() {
        let loginDelegate = MEGAGenericRequestDelegate { [weak self] (request, error) in
            if error?.type != .apiOk {
                self!.postNotification()
                return
            }
            
            MEGASdkManager.sharedMEGAChatSdk()?.connectInBackground()
        }!
        MEGASdkManager.sharedMEGASdk()?.fastLogin(withSession: session, delegate: loginDelegate)
    }
    
    func onChatConnectionStateUpdate(_ api: MEGAChatSdk!, chatId: UInt64, newState: Int32) {
        if chatId == ~UInt64(0) && newState == Int32(MEGAChatConnection.online.rawValue) {
            // TODO: At this point we are ready to process the notification properly
            
        }
    }

}
