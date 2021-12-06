
import UIKit

protocol AudioRecordingInputBarDelegate: AnyObject {
    func trashButtonTapped()
    func audioRecordingStarted()
    func audioRecordingEnded()
}

class AudioRecordingInputBar: UIView {
    @IBOutlet weak var trashView: EnlargementView!
    @IBOutlet weak var lockView: EnlargementView!
    @IBOutlet weak var voiceView: CondensationView!
    @IBOutlet weak var audioWavesholderView: UIView!
    @IBOutlet weak var audioWavesBackgroundView: UIView!
    @IBOutlet weak var recordTimeLabel: UILabel!

    @IBOutlet weak var suggestionLabel: UILabel!
    @IBOutlet weak var viewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var placeholderViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var audioWavesholderViewTrailingConstraint: NSLayoutConstraint!
    
    enum RecordError: Error {
        case durationShorterThanASecond
    }
    
    var audioWavesView: AudioWavesView!
    var locked = false
    
    lazy var audioRecorder = AudioRecorder()
    var player: AVAudioPlayer?
    weak var delegate: AudioRecordingInputBarDelegate?
    
    private lazy var trashedTapGesture: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer(target: self, action:#selector(trashTapGesture))
        return recognizer
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        
        addGestureRecognizer(trashedTapGesture)
                
        suggestionLabel.text = Strings.Localizable.dragLeftToCancelReleaseToSend
        audioWavesView = AudioWavesView.instanceFromNib
        audioWavesholderView.addSubview(audioWavesView)
        audioWavesView.autoPinEdgesToSuperviewEdges()
        updateAppearance()

        audioRecorder.updateHandler = {[weak self] timeString, level in
            guard let `self` = self else {
                return
            }
            
            self.recordTimeLabel.text = timeString
            self.audioWavesView.updateAudioView(withLevel: level)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
    
    func startRecording() {
        do {
            let success = try audioRecorder.start()
            delegate?.audioRecordingStarted()
            MEGALogDebug("Audio recorder started \(success)")
        } catch {
            MEGALogDebug("Audio recorder failed to start with error: \(error.localizedDescription)")
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
        voiceView.imageView.image = Asset.Images.Chat.sendChatDisabled.image
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
            self.placeholderViewTopConstraint = placeholderViewTopConstraint
            placeholderViewTopConstraint?.isActive = true
            self.layoutIfNeeded()
        })
    }
    
    @discardableResult
    func stopRecording(_ ignoreFile: Bool = false) throws -> String? {
        let path = try audioRecorder.stopRecording()
        
        let audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
        if audioPlayer.duration >= 1.0 && !ignoreFile {
            return path
        } else {
            if audioPlayer.duration < 1.0 && !ignoreFile {
                throw RecordError.durationShorterThanASecond
            }
            try FileManager.default.removeItem(atPath: path)
        }
        
        return nil
    }
    
    func cancelRecording() {
        do {
            try stopRecording(true)
        } catch {
            MEGALogDebug("Stop recording error \(error.localizedDescription)")
        }
    }
    
    @objc func trashTapGesture(_ tapGesture: UITapGestureRecognizer) {
        guard locked else {
            return
        }
        
        delegate?.trashButtonTapped()
    }
    
    private func updateAppearance() {
        suggestionLabel.textColor = UIColor.mnz_secondaryGray(for: traitCollection)
        audioWavesBackgroundView.backgroundColor = UIColor.mnz_secondaryBackground(for: traitCollection)
    }
    
    deinit {
        if audioRecorder.isRecording {
            delegate?.audioRecordingEnded()
            cancelRecording()
        }
    }
}


