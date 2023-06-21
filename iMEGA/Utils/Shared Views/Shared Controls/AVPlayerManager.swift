import Foundation
import AVKit
import Combine

@objc protocol AVPlayerManagerProtocol {
    
    ///  Creates a new AVPlayerViewController for the given node or return the current active AVPlayerViewController that is currently playing in Picture in Picture mode.
    /// - Parameters:
    ///   - node: MegaNode
    ///   - folderLink: Bool
    ///   - sdk: MegaSDK used for streaming the node
    /// - Returns: Creates or returns active AVPlayerViewcontroller
    func makePlayerController(for node: MEGANode, folderLink: Bool, sdk: MEGASdk) -> AVPlayerViewController
    
    ///  Creates a new AVPlayerViewController for the given node or return the current active AVPlayerViewController that is currently playing in Picture in Picture mode.
    /// - Parameters:
    ///   - url: URL
    /// - Returns: Creates or returns active AVPlayerViewcontroller
    func makePlayerController(for url: URL) -> AVPlayerViewController
    
    /// Call this to assign the passed AVPlayerViewController to this manager
    /// - Parameter to:AVPlayerViewController that will set its delegate to this manager
    func assignDelegate(to: AVPlayerViewController)

    /// Determines if the given controller is currently in Picture in Picture mode
    /// - Parameter controller: AVPlayerViewController
    /// - Returns: True if in PIP Mode, else false
    func isPIPModeActive(for controller: AVPlayerViewController) -> Bool
}

@objc final class AVPlayerManager: NSObject, AVPlayerManagerProtocol {
    
    // Public Shared Manager
    @objc static let shared: any AVPlayerManagerProtocol = AVPlayerManager(sdk: MEGASdk.shared)
    
    private let sdk: MEGASdk
    private weak var activeVideoViewController: MEGAAVViewController?
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func makePlayerController(for node: MEGANode, folderLink: Bool, sdk: MEGASdk) -> AVPlayerViewController {
        
        guard let activeVideoViewController,
              activeVideoViewController.fileFingerprint() == node.fingerprint else {
            return MEGAAVViewController(node: node, folderLink: folderLink, apiForStreaming: sdk)
        }
        
        return activeVideoViewController
    }
    
    func makePlayerController(for url: URL) -> AVPlayerViewController {
        guard let activeVideoViewController,
              activeVideoViewController.fileFingerprint() == sdk.fingerprint(forFilePath: url.path) else {
            return MEGAAVViewController(url: url)
        }
        return activeVideoViewController
    }
    
    func assignDelegate(to: AVPlayerViewController) {
        to.delegate = self
    }
    
    func isPIPModeActive(for controller: AVPlayerViewController) -> Bool {
        controller == activeVideoViewController
    }
}

// MARK: AVPlayerViewControllerDelegate
extension AVPlayerManager: AVPlayerViewControllerDelegate {
        
    func playerViewController(_ playerViewController: AVPlayerViewController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        
        guard playerViewController.presentingViewController == nil else {
            completionHandler(true)
            return
        }
        
        UIApplication.mnz_presentingViewController().present(playerViewController, animated: true)

        completionHandler(true)
    }
        
    func playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(_ playerViewController: AVPlayerViewController) -> Bool { false }
    
    func playerViewControllerWillStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
        activeVideoViewController = playerViewController as? MEGAAVViewController
    }
    
    func playerViewControllerDidStopPictureInPicture(_ playerViewController: AVPlayerViewController) {
        activeVideoViewController = nil
    }
}
