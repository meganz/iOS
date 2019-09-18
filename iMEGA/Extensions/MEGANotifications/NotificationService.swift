
import UserNotifications

class NotificationService: UNNotificationServiceExtension, MEGAChatDelegate {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    var session:String!
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let tempSession = SAMKeychain.password(forService: "MEGA", account: "sessionV3") {
            session = tempSession
        } else {
            postNotification()
            return
        }
        
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

    // MARK: Init, login, fetchnodes and connect
    
    func initChat() {
        if MEGASdkManager.sharedMEGAChatSdk() == nil {
            MEGASdkManager.createSharedMEGAChatSdk()
        }
        
        var chatInit = MEGASdkManager.sharedMEGAChatSdk()?.initState()
        if chatInit == .notDone {
            chatInit = MEGASdkManager.sharedMEGAChatSdk()?.initKarere(withSid: session)
            // TODO: If we decide to import the db from the main app, at this point we should reset the client id
            
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
            
            let fetchNodesDelegate = MEGAGenericRequestDelegate { [weak self] (request, error) in
                if error?.type != .apiOk {
                    self!.postNotification()
                    return
                }
                
                MEGASdkManager.sharedMEGAChatSdk()?.connectInBackground()
            }
            
            MEGASdkManager.sharedMEGASdk()?.fetchNodes(with: fetchNodesDelegate)
        }
        MEGASdkManager.sharedMEGASdk()?.fastLogin(withSession: session, delegate: loginDelegate)
    }
    
    func onChatConnectionStateUpdate(_ api: MEGAChatSdk!, chatId: UInt64, newState: Int32) {
        if chatId == ~UInt64(0) && newState == Int32(MEGAChatConnection.online.rawValue) {
            // TODO: At this point we are ready to process the notification properly
            
        }
    }

}
