

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
            statusView.backgroundColor = UIColor.mnz_color(forStatusChange: status)
        }
    }
    
    private func updateUIElements() {
        titleLabel.font = UIFont.mnz_SFUISemiBold(withSize: 15)
        titleLabel.textColor = .white
        
        subtitleLabel.font = UIFont.mnz_SFUIRegular(withSize: 12)
        subtitleLabel.textColor = .mnz_grayE3E3E3()
    }
}

extension UIView {
    class var instanceFromNib: Self {
        return Bundle(for: Self.self)
            .loadNibNamed(String(describing: Self.self), owner: nil, options: nil)?.first as! Self
    }
}

extension MEGAChatRoom {
    var onlineStatus: MEGAChatStatus? {
        if isGroup {
            return nil
        }
        
        return MEGASdkManager.sharedMEGAChatSdk()?.userOnlineStatus(peerHandle(at: 0))
    }
    
    var participantsNames: String {
        return (0..<peerCount).reduce("") { (result, index) in
            if let nickname = userNickname(atIndex: index)?.trim {
                let appendResult = (index == peerCount-1) ? nickname : "\(nickname), "
                return result + appendResult
            } else if let peerFirstname = peerFirstname(at: index)?.trim {
                let appendResult = (index == peerCount-1) ? peerFirstname : "\(peerFirstname), "
                return result + appendResult
            } else if let peerLastname = peerLastname(at: index)?.trim {
                let appendResult = (index == peerCount-1) ? peerLastname : "\(peerLastname), "
                return result + appendResult
            } else if let peerEmail = peerEmail(byHandle: peerHandle(at: index))?.trim {
                let appendResult = (index == peerCount-1) ? peerEmail : "\(peerEmail), "
                return result + appendResult
            }
            
            return ""
        }
    }
}
