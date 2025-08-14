import UIKit

@objc class MEGAApplication: UIApplication {
    
    override func sendEvent(_ event: UIEvent) {
        if event.type == .touches && event.allTouches?.randomElement()?.phase == .ended {
            MEGAChatSdk.shared.signalPresenceActivity()
        }
        
        super.sendEvent(event)
    }
}
