import ChatRepo
import MEGAAppSDKRepo
import MEGAChatSdk
import MEGASdk

@objc class MEGASdkCleanUp: NSObject {
    @objc static func localLogout() {
        let semaphore = DispatchSemaphore(value: 0)
        
        let sdkDelegate = RequestDelegate { _ in
            let chatSdkDelegate = ChatRequestDelegate { _, _ in
                DispatchQueue.global(qos: .userInteractive).async {
                    semaphore.signal()
                }
            }
            MEGAChatSdk.shared .localLogout(with: chatSdkDelegate)
        }
        
        MEGASdk.shared.localLogout(with: sdkDelegate)
        
        _ = semaphore.wait(timeout: .now() + DispatchTimeInterval.seconds(4))
    }
    
    @objc static func localLogoutAndCleanUp() {
        localLogout()
        deleteSharedSdks()
    }
    
    @objc static func deleteSharedSdks() {
        MEGAChatSdk.shared.deleteMegaChatApi()
        MEGASdk.shared.deleteMegaApi()
        MEGASdk.sharedFolderLink.deleteMegaApi()
    }
}
