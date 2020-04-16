
import UIKit

class AudioRecordingInputBar: UIView {
    @IBOutlet weak var trashView: EnlargementView!
    @IBOutlet weak var lockView: EnlargementView!
    @IBOutlet weak var voiceView: CondensationView!

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        // Audio recording view height remains constant throught.
        size.height = 236.0
        return size
    }
    
    func moveToTrash(_ progress: CGFloat) {
        trashView.progress = progress
        voiceView.progress = progress
        
        // When moving to trash locView does not animate
        lockView.progress = 0.0
    }
    
    func lock(_ progress: CGFloat) {
        lockView.progress = progress
        
        // When locking, trashview and voiceview does not animate
        trashView.progress = 0.0
        voiceView.progress = 0.0
    }
}
