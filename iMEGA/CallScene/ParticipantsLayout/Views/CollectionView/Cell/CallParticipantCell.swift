import MEGADomain

class CallParticipantCell: UICollectionViewCell {
    @IBOutlet weak var videoImageView: UIImageView!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var micImageView: UIImageView!
    
    private(set) var participant: CallParticipantEntity? {
        willSet {
            videoImageView?.image = nil
            participant?.videoDataDelegate = nil
        }
    }
    
    func configure(for participant: CallParticipantEntity, in layoutMode: ParticipantsLayoutMode) {
        self.participant = participant
        nameLabel.text = participant.name
        nameLabel.superview?.isHidden = layoutMode == .speaker
        participant.videoDataDelegate = self

        if participant.audio == .on && !participant.audioDetected {
            micImageView.isHidden = true
        } else {
            micImageView.isHidden = false
            micImageView.image = participant.audioDetected ? .micActive : .micMuted
        }
        
        if participant.video == .on {
            if videoImageView.isHidden {
                videoImageView.isHidden = false
                avatarImageView.isHidden = true
            }
        } else {
            if avatarImageView.isHidden {
                avatarImageView.isHidden = false
                videoImageView.isHidden = true
            }
        }
        
        if participant.hasScreenShare && !participant.hasCamera {
            avatarImageView.isHidden = false
            videoImageView.isHidden = true
        }
        
        layer.cornerRadius = 8
        borderWidth = 0
        
        if participant.audioDetected {
            borderColor = ._00_C_29_A
            borderWidth = 1
        }
        
        switch layoutMode {
        case .grid:
            micImageView.superview?.layer.cornerRadius = 2
            nameLabel.superview?.isHidden = false
        case .speaker:
            nameLabel.superview?.isHidden = true
            micImageView.superview?.layer.cornerRadius = 12
            if participant.isSpeakerPinned {
                borderColor = .systemYellow
                borderWidth = 1
            }
        }
    }
    
    func setAvatar(image: UIImage) {
        avatarImageView.image = image
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        participant = nil
    }
}

extension CallParticipantCell: CallParticipantVideoDelegate {
    func videoFrameData(width: Int, height: Int, buffer: Data!) {
        videoImageView.image = UIImage.mnz_convert(toUIImage: buffer, withWidth: width, withHeight: height)
    }
}
