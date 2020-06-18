

import UIKit

class ChatTitleView: UIView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var statusView: UIView!
    
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
        updateUIElements()
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
                subtitleLabel.text = AMLocalizedString("Inactive chat", "Subtitle of chat screen when the chat is inactive");
            } else if chatRoom.hasCustomTitle {
                subtitleLabel.text = chatRoom.participantsNames
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
            }
        }
    }
    
    private func updateStatusView() {
        statusView.isHidden = chatRoom.isGroup
        
        if let status = chatRoom.onlineStatus {
            statusView.isHidden = (status == .invalid)
            //FIXME: V5 merging issue
//            statusView.backgroundColor = UIColor.mnz_color(forStatusChange: status)
        }
    }
    
    private func updateUIElements() {
        //FIXME: V5 merging issue
//        titleLabel.font = UIFont.mnz_SFUISemiBold(withSize: 15)
        titleLabel.textColor = .white
        
//        subtitleLabel.font = UIFont.mnz_SFUIRegular(withSize: 12)
//        subtitleLabel.textColor = .mnz_grayE3E3E3()
    }
}


