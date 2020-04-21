
import UIKit

class AudioRecordingInputBar: UIView {
    @IBOutlet weak var trashView: EnlargementView!
    @IBOutlet weak var lockView: EnlargementView!
    @IBOutlet weak var voiceView: CondensationView!
    @IBOutlet weak var audioWavesholderView: UIView!
    @IBOutlet weak var recordTimeLabel: UILabel!

    @IBOutlet weak var suggestionLabel: UILabel!
    @IBOutlet weak var viewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var placeholderViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var audioWavesholderViewTrailingConstraint: NSLayoutConstraint!

    var audioWavesView: AudioWavesView!
    var locked = false
    
    lazy var audioRecorder = AudioRecorder()
    var player: AVAudioPlayer?

    override func awakeFromNib() {
        super.awakeFromNib()
                
        audioWavesView = AudioWavesView.instanceFromNib
        audioWavesholderView.addSubview(audioWavesView)
        audioWavesView.autoPinEdgesToSuperviewEdges()
        
        do {
            //FIXME: - handle the error cases
            let success = try audioRecorder.start()
            print("audio start succeeded: \(success)")
        } catch {
            print(error.localizedDescription)
        }
        
        audioRecorder.updateHandler = {[weak self] timeString, level in
            guard let `self` = self else {
                return
            }
            
            self.recordTimeLabel.text = timeString
            self.audioWavesView.updateAudioView(withLevel: level)
        }
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
    
    func lock(completionBlock: @escaping (() -> Void)) {
        locked = true
        voiceView.finalRatio = (voiceView.bounds.width - trashView.bounds.width) / voiceView.bounds.width
        voiceView.selectionView.backgroundColor = #colorLiteral(red: 0, green: 0.5803921569, blue: 0.462745098, alpha: 1)
        voiceView.imageView.image = #imageLiteral(resourceName: "sendChatDisabled")
        voiceView.imageView.renderImage(withColor: .white)
        let audioWaveTrailing = self.trashView.frame.width
            + (self.trashView.frame.origin.x * 2.0)
        audioWavesholderViewTrailingConstraint.constant = audioWaveTrailing

        voiceView.tapHandler = completionBlock
        
        // The height change animation for input accessory view will always start from center instead of bottom. So need to deactivate the top constraint and perform the animation.
        let placeholderViewTopConstraint = self.placeholderViewTopConstraint
        self.placeholderViewTopConstraint.isActive = false
        self.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.4, animations: {
            self.voiceView.progress = 1.0
            self.lockView.alpha = 0.0
            self.viewHeightConstraint.constant = 100.0
            self.layoutIfNeeded()
            self.suggestionLabel.alpha = 0.0
        }, completion: { _ in
            self.lockView.removeFromSuperview()
            self.suggestionLabel.removeFromSuperview()
            self.placeholderViewTopConstraint = placeholderViewTopConstraint
            placeholderViewTopConstraint?.isActive = true
            self.layoutIfNeeded()
        })
    }
    
    @discardableResult
    func stopRecording(_ ignoreFile: Bool = false) -> String? {
        do {
            //FIXME: - handle the error cases
            if let path = try? audioRecorder.stopRecording() {
                let audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                if audioPlayer.duration > 1.0 && !ignoreFile {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    return path
                } else {
                    do {
                        try FileManager.default.removeItem(atPath: path)
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
        } catch {
            //
        }
        
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        return nil
    }
    
    func cancelRecording() {
        stopRecording(true)
    }
}



