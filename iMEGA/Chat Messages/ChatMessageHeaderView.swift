
import MessageKit

class ChatMessageHeaderView: MessageReusableView {
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var chattingWithTextLabel: UILabel!
    @IBOutlet weak var participantsLabel: UILabel!
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var confidentialityTextLabel: UILabel!
    @IBOutlet weak var authenticityTextLabel: UILabel!
    @IBOutlet weak var avatarImageViewHeightConstraint: NSLayoutConstraint!

    
    var chatRoom: MEGAChatRoom! {
        didSet {
//            updateStatus()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
//        chattingWithTextLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
//        participantsLabel.font = UIFont.systemFont(ofSize: 24, weight: .regular)
//        statusLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
//
//        chattingWithTextLabel.textColor = UIColor(fromHexString: "#F0373A")
//        participantsLabel.textColor = UIColor.black
//        statusLabel.textColor = UIColor(fromHexString: "#848484")
        
//        chattingWithTextLabel.text = AMLocalizedString("chattingWith", "Title show above the name of the persons with whom you're chatting")
        descriptionLabel.text = AMLocalizedString("chatIntroductionMessage", "Full text: MEGA protects your chat with end-to-end (user controlled) encryption providing essential safety assurances: Confidentiality - Only the author and intended recipients are able to decipher and read the content. Authenticity - There is an assurance that the message received was authored by the stated sender, and its content has not been tampered with during transport or on the server.")
        
        let confidentialityText = AMLocalizedString("confidentialityExplanation", "Chat advantages information. Full text: Mega protects your chat with end-to-end (user controlled) encryption providing essential safety assurances: [S]Confidentiality.[/S] Only the author and intended recipients are able to decipher and read the content. [S]Authenticity.[/S] The system ensures that the data received is from the sender displayed, and its content has not been manipulated during transit.");
        setAttributedText(with: confidentialityText, label: confidentialityTextLabel)
        
        let authenticityText = AMLocalizedString("authenticityExplanation", "Chat advantages information. Full text: Mega protects your chat with end-to-end (user controlled) encryption providing essential safety assurances: [S]Confidentiality.[/S] Only the author and intended recipients are able to decipher and read the content. [S]Authenticity.[/S] The system ensures that the data received is from the sender displayed, and its content has not been manipulated during transit.")
        setAttributedText(with: authenticityText, label: authenticityTextLabel)
    }
    
    private func updateStatus() {
        participantsLabel.text = chatRoom.participantsNames
 
        if chatRoom.isGroup {
            avatarImageViewHeightConstraint.constant = 0.0
        } else {
            let avatarImage = chatRoom.avatarImage(delegate: self)
            avatarImageView.image =  avatarImage
        }
        

        if let status = chatRoom.onlineStatus {
            statusView.isHidden = (status == .invalid)
            statusView.backgroundColor = UIColor.mnz_color(forStatusChange: status)
            
            statusLabel.isHidden = (status == .invalid)
            statusLabel.text = NSString.chatStatusString(status)
        } else {
            statusView.isHidden = true
            statusLabel.isHidden = true
        }
    }
    
    private func setAttributedText(with string: String, label: UILabel) {
        let title = (string as NSString).mnz_stringBetweenString("[S]", andString: "[/S]")!
        let description = (string as NSString).replacingOccurrences(of: String(format: "[S]%@[/S]", title), with: "")
        
        let titleAttributes = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 15.0, weight: .regular),
                                                               NSAttributedString.Key.foregroundColor: UIColor.mnz_redMain()!]
        let titleAttributedString = NSMutableAttributedString(string: title, attributes: titleAttributes)
        
        let descriptionAttributes = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 15.0, weight: .regular),
                                                                     NSAttributedString.Key.foregroundColor: UIColor.mnz_gray777777()!]
        let descriptionAttributedString = NSMutableAttributedString(string: description, attributes: descriptionAttributes)
        
        titleAttributedString.append(descriptionAttributedString)
        label.attributedText = titleAttributedString
    }
}

extension ChatMessageHeaderView: MEGARequestDelegate {
    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        guard error.type == .apiOk else {
            MEGALogError("ChatMessageHeaderView: Could not fetch avatar image")
            return
        }
        
        avatarImageView.image = chatRoom.avatarImage(delegate: nil)
    }
}
