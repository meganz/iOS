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
        participant.videoDataDelegate = self
        layer.cornerRadius = 8
        borderWidth = 0
        
        if !participant.isScreenShareCell {
            nameLabel.text = participant.name
            nameLabel.superview?.isHidden = layoutMode == .speaker
            
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
                videoImageView.isHidden = true
                avatarImageView.isHidden = false
            }
            
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
                if participant.isSpeakerPinned {
                    borderColor = .systemYellow
                    borderWidth = 1
                }
            }
            
            if participant.audioDetected {
                borderColor = UIColor.green00C29A
                borderWidth = 1
            }
        } else {
            nameLabel.isHidden = true
            nameLabel.superview?.isHidden = true
            micImageView.isHidden = true
            avatarImageView.isHidden = true
            videoImageView.isHidden = false
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
