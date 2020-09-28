
import UIKit

protocol VoiceClipInputBarDelegate: class {
    func removeVoiceClipView(withClipPath path: String?)
    func voiceRecordingStarted()
    func voiceRecordingEnded()
}

class VoiceClipInputBar: UIView {
    
    @IBOutlet weak var audioWavesholderView: UIView!
    
    @IBOutlet weak var startRecordingView: UIView!
    @IBOutlet weak var trashView: UIView!
    @IBOutlet weak var sendView: UIView!
    @IBOutlet weak var sendImageView: UIImageView!
    
    @IBOutlet private weak var sendViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var sendViewHorizontalConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var trashViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var trashViewHorizontalConstraint: NSLayoutConstraint!
    
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
        
        updateAppearance()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13.0, *),
            traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
        
        if audioRecorder.isRecording && !sendViewTrailingConstraint.isActive {
            self.sendViewHorizontalConstraint.isActive = false
            self.trashViewHorizontalConstraint.isActive = false
            self.sendViewTrailingConstraint.isActive = true
            self.trashViewLeadingConstraint.isActive = true
        }
    }
    
    @IBAction func recordButtonTapped(_ sender: UIButton) {
        recordingStartedAnimation()
    }
    
    @IBAction func trashButtonTapped(_ sender: UIButton) {
        delegate?.removeVoiceClipView(withClipPath: stopRecording(true))
        delegate?.voiceRecordingEnded()
        recordingCompletedAnimation()
    }
    
    @IBAction func sendButtonTapped(_ sender: UIButton) {
        delegate?.removeVoiceClipView(withClipPath: stopRecording())
        delegate?.voiceRecordingEnded()
        recordingCompletedAnimation()
    }
    
    // MARK:- Private methods
    
    private func recordingStartedAnimation() {
        sendView.isHidden = false
        trashView.isHidden = false
        
        startRecordingAudio()
        delegate?.voiceRecordingStarted()
        
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
    
    private func recordingCompletedAnimation() {
        recordTimeLabel.isHidden = true
        audioWavesView.reset()
        startRecordingView.alpha = 0.0
        startRecordingView.isHidden = false
        
        UIView.animate(withDuration: 0.4, animations: {
            self.sendViewTrailingConstraint.isActive = false
            self.trashViewLeadingConstraint.isActive = false
            self.sendViewHorizontalConstraint.isActive = true
            self.trashViewHorizontalConstraint.isActive = true
            self.startRecordingView.alpha = 1.0
            self.layoutIfNeeded()
        }, completion: { _ in
            self.sendView.isHidden = true
            self.trashView.isHidden = true
        })
    }
    
    private func startRecordingAudio() {
        recordTimeLabel.isHidden = false
        
        do {
            let success = try audioRecorder.start()
            MEGALogDebug("started audio recording successfully: \(success)")
        } catch {
            MEGALogDebug("error starting the audio recorder \(error.localizedDescription)")
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
            let path = try audioRecorder.stopRecording()
            let audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            if audioPlayer.duration > 1.0 && !ignoreFile {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                return path
            } else {
                do {
                    try FileManager.default.removeItem(atPath: path)
                } catch {
                    MEGALogDebug("error removing audio recorded file with error: \(error.localizedDescription)")
                }
            }
        } catch {
            MEGALogDebug("error stopping the audio recorder \(error.localizedDescription)")
        }
        
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        return nil
    }
    
    private func updateAppearance() {
        backgroundColor = UIColor.mnz_voiceRecordingViewBackground(traitCollection)
    }
    
    deinit {
        if audioRecorder.isRecording {
            delegate?.voiceRecordingEnded()
            stopRecording(true)
        }
    }
}
