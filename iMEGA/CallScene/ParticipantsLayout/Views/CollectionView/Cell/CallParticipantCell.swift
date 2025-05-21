import MEGAAssets
import MEGADesignToken
import MEGADomain

class CallParticipantCell: UICollectionViewCell {
    @IBOutlet weak var videoImageView: UIImageView!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var micImageView: UIImageView!
    @IBOutlet weak var raisedHandView: UIView!
    @IBOutlet weak var raisedHandImageView: UIImageView!
    
    private(set) var participant: CallParticipantEntity? {
        willSet {
            videoImageView?.image = nil
            participant?.videoDataDelegate = nil
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureImages()
    }
    
    func configure(for participant: CallParticipantEntity, in layoutMode: ParticipantsLayoutMode) {
        self.participant = participant
        participant.videoDataDelegate = self
        layer.cornerRadius = 8
        borderWidth = 0
        
        if !participant.isScreenShareCell {
            nameLabel.isHidden = false
            nameLabel.text = participant.name
            nameLabel.superview?.isHidden = layoutMode == .speaker
            
            updateMic(audioEnabled: participant.audio == .on, audioDetected: participant.audioDetected)
            
            let isVideoOn = participant.video == .on
            videoImageView.isHidden = !isVideoOn
            avatarImageView.isHidden = isVideoOn
            
            if participant.hasScreenShare && !participant.hasCamera {
                avatarImageView.isHidden = false
                videoImageView.isHidden = true
            }
            
            switch layoutMode {
            case .grid:
                micImageView.superview?.layer.cornerRadius = 2
                nameLabel.superview?.isHidden = false
            case .speaker:
                nameLabel.superview?.isHidden = true
                micImageView.superview?.layer.cornerRadius = 12
            }
            
            updateAudioDetectedAndBorderColor(
                audioEnabled: participant.audio == .on,
                audioDetected: participant.audioDetected,
                isPinned: isParticipantPinnedInSpeakerLayout(
                    participant: participant,
                    layoutMode: layoutMode
                )
            )
            updateRaiseHand(participant.raisedHand)
        } else {
            nameLabel.isHidden = true
            nameLabel.superview?.isHidden = true
            micImageView.isHidden = true
            avatarImageView.isHidden = true
            videoImageView.isHidden = false
            raisedHandView.isHidden = true
        }
    }
    
    func setAvatar(image: UIImage) {
        avatarImageView.image = image
    }
    
    func updateMic(audioEnabled: Bool, audioDetected: Bool) {
        if audioEnabled && !audioDetected {
            micImageView.isHidden = true
        } else {
            micImageView.isHidden = false
            micImageView.image = audioDetected ? MEGAAssets.UIImage.micActive : MEGAAssets.UIImage.micMuted
        }
    }
    
    func updateAudioDetectedAndBorderColor(
        audioEnabled: Bool,
        audioDetected: Bool,
        isPinned: Bool
    ) {
        if audioDetected {
            borderColor = MEGAAssets.UIColor.green00C29A
            borderWidth = 1
            micImageView.isHidden = false
            micImageView.image = MEGAAssets.UIImage.micActive
        } else {
            updateMic(audioEnabled: audioEnabled, audioDetected: audioDetected)
            if isPinned {
                borderColor = MEGAAssets.UIColor.whiteFFFFFF
                borderWidth = 1
            } else {
                borderWidth = 0
            }
        }
    }
    
    func updateRaiseHand(_ raised: Bool) {
        raisedHandView.isHidden = !raised
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        participant = nil
    }
    
    func isParticipantPinnedInSpeakerLayout(participant: CallParticipantEntity, layoutMode: ParticipantsLayoutMode) -> Bool {
        participant.isSpeakerPinned && layoutMode == .speaker
    }
    
    private func configureImages() {
        raisedHandImageView.image = MEGAAssets.UIImage.image(named: "raisedHand")
    }
}

// MARK: - CallParticipantVideoDelegate

extension CallParticipantCell: CallParticipantVideoDelegate {
    func videoFrameData(width: Int, height: Int, buffer: Data!, type: VideoFrameType) {
        guard let participant = participant else { return }
        if participant.isScreenShareCell {
            if type == .screenShare {
                videoImageView.image = UIImage.mnz_convert(toUIImage: buffer, withWidth: width, withHeight: height)
            }
        } else {
            if type == .cameraVideo {
                videoImageView.image = UIImage.mnz_convert(toUIImage: buffer, withWidth: width, withHeight: height)
            }
        }
    }
}
