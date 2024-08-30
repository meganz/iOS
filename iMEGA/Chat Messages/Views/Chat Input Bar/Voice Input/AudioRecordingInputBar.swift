import MEGADesignToken
import MEGAL10n
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
    weak var delegate: (any AudioRecordingInputBarDelegate)?
    
    private lazy var trashedTapGesture: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(trashTapGesture))
        return recognizer
    }()

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        addGestureRecognizer(trashedTapGesture)
                
        suggestionLabel.text = Strings.Localizable.dragLeftToCancelReleaseToSend
        audioWavesView = AudioWavesView.instanceFromNib
        audioWavesholderView.wrap(audioWavesView)
        if UIColor.isDesignTokenEnabled() {
            trashView.imageView.image = UIImage(resource: .rubbishBin).withTintColor(TokenColors.Icon.primary, renderingMode: .alwaysTemplate)
        }
        updateAppearance()

        audioRecorder.updateHandler = {[weak self] timeString, level in
            guard let `self` = self else {
                return
            }
            
            self.recordTimeLabel.text = timeString
            self.audioWavesView.updateAudioView(withLevel: level)
        }
        backgroundColor = UIColor.isDesignTokenEnabled()
            ? TokenColors.Background.page
            : .systemBackground
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
        let width = voiceView.bounds.width - trashView.bounds.width
        voiceView.finalRatio = width / voiceView.bounds.width
        voiceView.imageView.image = UIImage(resource: .sendChatDisabled)
        if UIColor.isDesignTokenEnabled() {
            voiceView.selectionView.backgroundColor = TokenColors.Button.primary
            voiceView.imageView.renderImage(withColor: TokenColors.Icon.inverseAccent)
        } else {
            voiceView.selectionView.backgroundColor = UIColor.green009476
            voiceView.imageView.renderImage(withColor: UIColor.whiteFFFFFF)
        }
        let audioWaveTrailing = self.trashView.frame.width
            + (self.trashView.frame.origin.x * CGFloat(2.0))
        audioWavesholderViewTrailingConstraint.constant = audioWaveTrailing

        voiceView.tapHandler = completionBlock
        
        // The height change animation for input accessory view will always start from center instead of bottom. So need to deactivate the top constraint and perform the animation.
        guard let placeholderViewTopConstraint = self.placeholderViewTopConstraint else { return }
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
            placeholderViewTopConstraint.isActive = true
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
    
    func cancelRecordingIfNeeded() {
        if audioRecorder.isRecording {
            delegate?.audioRecordingEnded()
            cancelRecording()
        }
    }
    
    private func updateAppearance() {
        if UIColor.isDesignTokenEnabled() {
            suggestionLabel.textColor = TokenColors.Text.secondary
            audioWavesBackgroundView.backgroundColor = TokenColors.Background.surface1
        } else {
            suggestionLabel.textColor = UIColor.mnz_secondaryGray(for: traitCollection)
            audioWavesBackgroundView.backgroundColor = UIColor.mnz_secondaryBackground(for: traitCollection)
        }
    }
}
