

import UIKit

class ChatTitleView: UIView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var statusView: UIView!
    
    var lastGreen: Int? {
        didSet{
            updateSubtitleLabel()
        }
    }
    
    var chatRoom: MEGAChatRoom! {
        didSet {
            guard chatRoom != nil else {
                return
            }
            
            updateTitleLabel()
            updateSubtitleLabel()
            updateStatusView()
        }
    }
    
    var tapHandler: (() -> Void)?
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: CGFloat.greatestFiniteMagnitude,
                      height: super.intrinsicContentSize.height)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateAppearance()
    }
    
    @IBAction func didTap(tapGesture: UITapGestureRecognizer) {
        if let handler = tapHandler {
            handler()
        }
    }
    
    
    private func updateTitleLabel() {
        titleLabel.text = chatRoom.title
    }
    
    private func updateSubtitleLabel() {
        if chatRoom.isArchived {
            subtitleLabel.text = AMLocalizedString("archived", "Title of flag of archived chats.")
        } else if chatRoom.isGroup {
            if chatRoom.ownPrivilege.rawValue < MEGAChatRoomPrivilege.ro.rawValue {
                subtitleLabel.text = AMLocalizedString("Inactive chat", "Subtitle of chat screen when the chat is inactive")
            } else if chatRoom.hasCustomTitle {
                subtitleLabel.text = chatRoom.participantNames
            } else if chatRoom.peerCount > 0 {
                subtitleLabel.text = String(format: AMLocalizedString("%d participants", "Plural of participant. 2 participants") , chatRoom.peerCount + 1)
            } else {
                subtitleLabel.text = String(format: AMLocalizedString("%d participant", "Singular of participant. 1 participants") , 1)
            }
            
        } else {
            //TODO: lastGreenString
            if let status = chatRoom.onlineStatus {
                subtitleLabel.isHidden = (status == .invalid)
                subtitleLabel.text = NSString.chatStatusString(status)
                switch status {
                case .offline, .away:
                    if let lastGreen = lastGreen {
                        subtitleLabel.text = NSString.mnz_lastGreenString(fromMinutes: lastGreen)
                    }
                default:
                    subtitleLabel.isHidden = (status == .invalid)
                    subtitleLabel.text = NSString.chatStatusString(status)
                }
            }
            
         
        }
    }
    
    private func updateStatusView() {
        statusView.isHidden = chatRoom.isGroup
        
        if let status = chatRoom.onlineStatus {
            statusView.isHidden = (status == .invalid)
            statusView.backgroundColor = UIColor.mnz_color(for: status)
        }
    }
    
    private func updateAppearance() {
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = UIColor.mnz_label()
        
        subtitleLabel.font = UIFont.systemFont(ofSize: 12)
        subtitleLabel.textColor = UIColor.mnz_subtitles(for: traitCollection)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(traitCollection)
        
        if #available(iOS 13, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                self.updateAppearance()
            }
        }
    }
}


