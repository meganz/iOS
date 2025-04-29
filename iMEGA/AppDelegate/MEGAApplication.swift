import UIKit

#if DEBUG
import FLEX
#endif

@objc class MEGAApplication: UIApplication {
    
    override func sendEvent(_ event: UIEvent) {
        if event.type == .touches && event.allTouches?.randomElement()?.phase == .ended {
            MEGAChatSdk.shared.signalPresenceActivity()
        }
#if DEBUG
        if event.allTouches?.count == 4 {
            FLEXManager.shared.showExplorer()
        }
#endif
        
        super.sendEvent(event)
    }
}
