
import MessageKit

class ChatViewIntroductionHeaderView: MessageReusableView {
    
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var mainStackViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainStackViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var participantsInformationStackView: UIStackView!

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var avatarImageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var avatarImageViewWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var chattingWithTextLabel: UILabel!
    @IBOutlet weak var participantsLabel: UILabel!
    
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var descriptionStackView: UIStackView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var confidentialityAndAuthenticityStackView: UIStackView!

    @IBOutlet weak var confidentialityStackView: UIStackView!
    @IBOutlet weak var confidentialityImageView: UIImageView!
    @IBOutlet weak var confidentialityTextLabel: UILabel!

    @IBOutlet weak var authenticityStackView: UIStackView!
    @IBOutlet weak var authenticityImageView: UIImageView!
    @IBOutlet weak var authenticityTextLabel: UILabel!
    
    var chatRoom: MEGAChatRoom! {
        didSet {
            updateStatus()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        chattingWithTextLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        participantsLabel.font = UIFont.systemFont(ofSize: 24, weight: .regular)
        statusLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)

        //FIXME: V5 merging issue
        chattingWithTextLabel.textColor = .red
        participantsLabel.textColor = UIColor.black
        statusLabel.textColor = .red
        
        chattingWithTextLabel.text = AMLocalizedString("chattingWith", "Title show above the name of the persons with whom you're chatting")
        descriptionLabel.text = AMLocalizedString("chatIntroductionMessage", "Full text: MEGA protects your chat with end-to-end (user controlled) encryption providing essential safety assurances: Confidentiality - Only the author and intended recipients are able to decipher and read the content. Authenticity - There is an assurance that the message received was authored by the stated sender, and its content has not been tampered with during transport or on the server.")
        
        let confidentialityText = AMLocalizedString("confidentialityExplanation", "Chat advantages information. Full text: Mega protects your chat with end-to-end (user controlled) encryption providing essential safety assurances: [S]Confidentiality.[/S] Only the author and intended recipients are able to decipher and read the content. [S]Authenticity.[/S] The system ensures that the data received is from the sender displayed, and its content has not been manipulated during transit.");
        setAttributedText(with: confidentialityText, label: confidentialityTextLabel)
        
        let authenticityText = AMLocalizedString("authenticityExplanation", "Chat advantages information. Full text: Mega protects your chat with end-to-end (user controlled) encryption providing essential safety assurances: [S]Confidentiality.[/S] Only the author and intended recipients are able to decipher and read the content. [S]Authenticity.[/S] The system ensures that the data received is from the sender displayed, and its content has not been manipulated during transit.")
        setAttributedText(with: authenticityText, label: authenticityTextLabel)
    }
    
    private func updateStatus() {
        participantsLabel.text = chatRoom.participantsNames
        
        if chatRoom.isGroup {
            avatarImageView.isHidden = true
            avatarImageViewHeightConstraint.constant = 0.0
            avatarImageViewWidthConstraint.constant = 0.0
        } else {
            avatarImageView.image = chatRoom.avatarImage(delegate: self)
        }
        

        if let status = chatRoom.onlineStatus {
            statusView.isHidden = (status == .invalid)
            //FIXME: V5 merging issue
            statusView.backgroundColor = UIColor.red
            
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
        
        //FIXME: V5 merging issue
        let titleAttributes = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 15.0, weight: .regular),
                                                               NSAttributedString.Key.foregroundColor: UIColor.red]
        let titleAttributedString = NSMutableAttributedString(string: title, attributes: titleAttributes)
        
        let descriptionAttributes = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 15.0, weight: .regular),
                                     NSAttributedString.Key.foregroundColor: UIColor.red]
        let descriptionAttributedString = NSMutableAttributedString(string: description, attributes: descriptionAttributes)
        
        titleAttributedString.append(descriptionAttributedString)
        label.attributedText = titleAttributedString
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let viewPadding: CGFloat = mainStackViewTopConstraint.constant + mainStackViewBottomConstraint.constant
        
        let participantsInformationAvailableWidth = avatarImageView.isHidden ? size.width : size.width - avatarImageViewWidthConstraint.constant
        let participantsInformationAvailableSize = CGSize(width: participantsInformationAvailableWidth, height: size.height)
        
        let chattingWithTextLabelSize = chattingWithTextLabel.sizeThatFits(participantsInformationAvailableSize)
        let participantsLabelSize = participantsLabel.sizeThatFits(participantsInformationAvailableSize)
        let statusLabelSize = statusLabel.sizeThatFits(participantsInformationAvailableSize)
        
        let participantsInformationHeight = max(avatarImageViewHeightConstraint.constant,
                                                chattingWithTextLabelSize.height
                                                    + participantsLabelSize.height
                                                    + statusLabelSize.height + 20)
        
        let descriptionLabelSize = descriptionLabel.sizeThatFits(size)
        let confidentialityLabelSize = confidentialityTextLabel.sizeThatFits(size)
        let authenticityLabelSize = authenticityTextLabel.sizeThatFits(size)
        
        let totalHeight = viewPadding
            + mainStackView.spacing
            + participantsInformationStackView.spacing
            + participantsInformationHeight
            + descriptionStackView.spacing
            + descriptionLabelSize.height
            + confidentialityAndAuthenticityStackView.spacing
            + confidentialityStackView.spacing
            + confidentialityImageView.bounds.height
            + confidentialityLabelSize.height
            + authenticityStackView.spacing
            + authenticityImageView.bounds.height
            + authenticityLabelSize.height
        
        return CGSize(width: size.width, height: totalHeight)
    }
}

extension ChatViewIntroductionHeaderView: MEGARequestDelegate {
    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        guard error.type == .apiOk else {
            MEGALogError("ChatMessageHeaderView: Could not fetch avatar image")
            return
        }
        
        avatarImageView.image = chatRoom.avatarImage(delegate: nil)
    }
}
