
import UIKit

protocol VoiceClipInputBarDelegate: class {
    func removeVoiceClipView(withClipPath path: String?)
}

class VoiceClipInputBar: UIView {
    
    @IBOutlet weak var audioWavesholderView: UIView!

    @IBOutlet weak var startRecordingView: UIView!
    @IBOutlet weak var trashView: UIView!
    @IBOutlet weak var sendView: UIView!
    @IBOutlet weak var sendImageView: UIImageView!

    @IBOutlet weak var sendViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var sendViewHorizontalConstraint: NSLayoutConstraint!

    @IBOutlet weak var trashViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var trashViewHorizontalConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var recordTimeLabel: UILabel!
    
    var audioWavesView: AudioWavesView!
    lazy var audioRecorder = AudioRecorder()
    weak var delegate: VoiceClipInputBarDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        sendImageView.renderImage(withColor: .white)
        
        audioWavesView = AudioWavesView.instanceFromNib
        audioWavesholderView.addSubview(audioWavesView)
        audioWavesView.autoPinEdgesToSuperviewEdges()
    }

    @IBAction func recordButtonTapped(_ sender: UIButton) {
        sendView.isHidden = false
        trashView.isHidden = false
        
        startRecordingAudio()
        
        UIView.animate(withDuration: 0.4, animations: {
            self.sendViewHorizontalConstraint.isActive = false
            self.trashViewHorizontalConstraint.isActive = false
            self.sendViewTrailingConstraint.isActive = true
            self.trashViewLeadingConstraint.isActive = true
            self.startRecordingView.alpha = 0.0
            self.layoutIfNeeded()
        }, completion: { _ in
            self.startRecordingView.isHidden = true
            self.startRecordingView.alpha = 1.0
        })
    }
    
    @IBAction func trashButtonTapped(_ sender: UIButton) {
        delegate?.removeVoiceClipView(withClipPath: stopRecording(true))
    }
    
    @IBAction func sendButtonTapped(_ sender: UIButton) {
        delegate?.removeVoiceClipView(withClipPath: stopRecording())
    }
    
    private func startRecordingAudio() {
        self.recordTimeLabel.isHidden = false
        
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
}
