import ChatRepo
import MEGADesignToken
import MEGADomain
import MEGAL10n
import UIKit

class ChatTitleView: UIView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var statusView: UIView!
    
    private let chatRoomUseCase = ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo)

    var lastGreen: Int? {
        didSet {
            updateSubtitleLabel()
        }
    }
    
    var chatRoom: ChatRoomEntity! {
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
        titleLabel.text = chatRoom.isNoteToSelf ?
        Strings.Localizable.Chat.Messages.NoteToSelf.title :
        chatRoom.title
    }
    
    private func updateSubtitleLabel() {
        if chatRoom.isArchived {
            subtitleLabel.text = Strings.Localizable.archived
        } else if chatRoom.isNoteToSelf {
            subtitleLabel.isHidden = true
        } else if chatRoom.isGroup {
            if !chatRoom.ownPrivilege.isUserInChat {
                subtitleLabel.text = Strings.Localizable.inactiveChat
            } else if chatRoom.hasCustomTitle {
                subtitleLabel.text = participantNames(for: chatRoom)
            } else {
                let participantsCount = Int(chatRoom.peerCount) + 1
                subtitleLabel.text = Strings.Localizable.Chat.Info.numberOfParticipants(participantsCount)
            }
            
        } else {
            if let userHandle = chatRoom.peers.first?.handle {
                let status = chatRoomUseCase.userStatus(forUserHandle: userHandle)
                subtitleLabel.text = status.localizedIdentifier
                switch status {
                case .offline, .away:
                    if let lastGreen = lastGreen {
                        subtitleLabel.text = NSString.mnz_lastGreenString(fromMinutes: lastGreen)
                    }
                default:
                    subtitleLabel.isHidden = (status == .invalid)
                    subtitleLabel.text = status.localizedIdentifier
                }
            }
        }
    }
    
    private func updateStatusView() {
        guard chatRoom.chatType == .oneToOne else {
            statusView.isHidden = true
            return
        }

        if let userHandle = chatRoom.peers.first?.handle {
            let status = chatRoomUseCase.userStatus(forUserHandle: userHandle)
            statusView.isHidden = (status == .invalid)
            statusView.backgroundColor = status.uiColor
        }
    }
    
    private func updateAppearance() {
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = UIColor.primaryTextColor()
        
        subtitleLabel.font = UIFont.systemFont(ofSize: 12)
        subtitleLabel.textColor = TokenColors.Text.secondary
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(traitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            self.updateAppearance()
        }
    }
}
