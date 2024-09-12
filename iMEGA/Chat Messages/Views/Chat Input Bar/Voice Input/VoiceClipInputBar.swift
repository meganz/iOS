import MEGADesignToken
import UIKit

protocol VoiceClipInputBarDelegate: AnyObject {
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
    
    @IBOutlet private weak var sendViewHorizontalConstraint: NSLayoutConstraint!
    @IBOutlet private weak var trashViewHorizontalConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var recordTimeLabel: UILabel!
    
    var audioWavesView: AudioWavesView!
    lazy var audioRecorder = AudioRecorder()
    weak var delegate: (any VoiceClipInputBarDelegate)?
    
    private var padding: CGFloat = 20.0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        sendImageView.renderImage(withColor: UIColor.whiteFFFFFF)
        
        audioWavesView = AudioWavesView.instanceFromNib        
        audioWavesholderView.wrap(audioWavesView)
        
        updateAppearance()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if audioRecorder.isRecording {
            recordingUIUpdates()
        }
    }
    
    // MARK: - Private methods
    
    private func recordingUIUpdates() {
        trashViewHorizontalConstraint.constant = trashViewPaddingWhenRecording()
        sendViewHorizontalConstraint.constant = sendViewPaddingWhenRecording()
    }
    
    private func trashViewPaddingWhenRecording() -> CGFloat {
        buttonsPadding + safeAreaInsets.left
    }
    
    private var buttonsPadding: CGFloat {
        let boundWidth = bounds.width / CGFloat(2.0)
        let viewWidth = trashView.bounds.width / CGFloat(2.0)
        return viewWidth - boundWidth + padding
    }
    
    private func sendViewPaddingWhenRecording() -> CGFloat {
        var sendViewPadding = (bounds.width / 2.0) - (sendView.bounds.width / 2.0) - padding
        sendViewPadding -= safeAreaInsets.right
        return sendViewPadding
    }
    
    private func recordingStartedAnimation() {
        sendView.isHidden = false
        trashView.isHidden = false
        
        startRecordingAudio()
        delegate?.voiceRecordingStarted()
        
        UIView.animate(withDuration: 0.4, animations: {
            self.recordingUIUpdates()
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
            self.sendViewHorizontalConstraint.constant = 0
            self.trashViewHorizontalConstraint.constant = 0
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
    
    func cancelRecordingIfNeeded() {
        if audioRecorder.isRecording {
            delegate?.voiceRecordingEnded()
            stopRecording(true)
        }
    }
    
    private func updateAppearance() {
        backgroundColor = UIColor.mnz_voiceRecordingViewBackground(traitCollection)
        sendView.backgroundColor = TokenColors.Button.primary
    }
}
