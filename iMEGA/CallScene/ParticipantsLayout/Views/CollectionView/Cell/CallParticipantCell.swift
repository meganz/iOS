import MEGADomain

class CallParticipantCell: UICollectionViewCell {
    @IBOutlet weak var videoImageView: UIImageView!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var mutedImageView: UIImageView!
    
    private(set) var participant: CallParticipantEntity? {
        willSet {
            videoImageView?.image = nil
            participant?.videoDataDelegate = nil
        }
    }
    
    func configure(for participant: CallParticipantEntity, in layoutMode: ParticipantsLayoutMode) {
        self.participant = participant
        nameLabel.text = participant.name
        mutedImageView.isHidden = participant.audio == .on
        nameLabel.superview?.isHidden = layoutMode == .speaker
        participant.videoDataDelegate = self

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
        
        if layoutMode == .speaker && participant.isSpeakerPinned {
            borderWidth = 1
            borderColor = .systemYellow
        } else {
            borderWidth = 0
            borderColor = .clear
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
    func frameData(width: Int, height: Int, buffer: Data!) {
        videoImageView.image = UIImage.mnz_convert(toUIImage: buffer, withWidth: width, withHeight: height)
    }
}
