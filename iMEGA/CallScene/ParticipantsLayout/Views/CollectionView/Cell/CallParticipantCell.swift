
class CallParticipantCell: UICollectionViewCell {
    @IBOutlet weak var videoImageView: UIImageView!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var mutedImageView: UIImageView!
    
    func configure(for participant: CallParticipantEntity, in layoutMode: CallLayoutMode) {
        avatarImageView.mnz_setImage(forUserHandle: participant.participantId, name: participant.name)
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
}

extension CallParticipantCell: CallParticipantVideoDelegate {
    func frameData(width: Int, height: Int, buffer: Data!) {
        videoImageView.image = UIImage.mnz_convert(toUIImage: buffer, withWidth: width, withHeight: height)
    }
}
