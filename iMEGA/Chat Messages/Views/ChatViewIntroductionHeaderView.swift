
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
    
    var chatRoom: MEGAChatRoom? {
        didSet {
            updateStatus()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateAppearance()
    }
    
    private func updateStatus() {
        guard let chatRoom = chatRoom else {
            return
        }
        
        participantsLabel.text = chatRoom.participantNames

        if chatRoom.isGroup {
            avatarImageView.isHidden = true
            avatarImageViewHeightConstraint.constant = 0.0
            avatarImageViewWidthConstraint.constant = 0.0
        } else {
            let userHandle = chatRoom.peerHandle(at: 0)
            avatarImageView.image = UIImage.mnz_image(forUserHandle: userHandle, name: chatRoom.title ?? "", size: CGSize(width: 88, height: 88), delegate: self)
        }
        

        if let status = chatRoom.onlineStatus {
            statusView.isHidden = (status == .invalid)
            statusView.backgroundColor = UIColor.mnz_color(for: status)
            
            statusLabel.isHidden = (status == .invalid)
            statusLabel.text = NSString.chatStatusString(status)
        } else {
            statusView.isHidden = true
            statusLabel.isHidden = true
        }
        updateAppearance()
    }
    
    private func updateAppearance () {
        chattingWithTextLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        participantsLabel.font = UIFont.systemFont(ofSize: 24, weight: .regular)
        statusLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        
        chattingWithTextLabel.textColor = UIColor.mnz_red(for: traitCollection)
        descriptionLabel.textColor = UIColor.mnz_primaryGray(for: traitCollection)
        participantsLabel.textColor = UIColor.mnz_label()
        statusLabel.textColor = UIColor.mnz_primaryGray(for: traitCollection)

        chattingWithTextLabel.text = Strings.Localizable.chattingWith
        descriptionLabel.text = Strings.Localizable.chatIntroductionMessage
        
        let confidentialityText = Strings.Localizable.confidentialityExplanation
        setAttributedText(with: confidentialityText, label: confidentialityTextLabel)
        
        let authenticityText = Strings.Localizable.authenticityExplanation
        setAttributedText(with: authenticityText, label: authenticityTextLabel)
        
        guard let status = chatRoom?.onlineStatus else {
            return
        }
        statusView.backgroundColor = UIColor.mnz_color(for: status)

    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateAppearance()
    }
    
    private func setAttributedText(with string: String, label: UILabel) {
        let title = (string as NSString).mnz_stringBetweenString("[S]", andString: "[/S]")!
        let description = (string as NSString).replacingOccurrences(of: String(format: "[S]%@[/S]", title), with: "")
        
        let titleAttributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 15.0, weight: .regular),
                                                               NSAttributedString.Key.foregroundColor: UIColor.mnz_red(for: traitCollection)]
        let titleAttributedString = NSMutableAttributedString(string: title, attributes: titleAttributes)
        
        let descriptionAttributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 15.0, weight: .regular),
                                                                     NSAttributedString.Key.foregroundColor: UIColor.mnz_primaryGray(for: traitCollection)]
        let descriptionAttributedString = NSMutableAttributedString(string: description, attributes: descriptionAttributes)
        
        titleAttributedString.append(descriptionAttributedString)
        label.attributedText = titleAttributedString
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let topConstraint: CGFloat = mainStackViewTopConstraint.constant
        let bottomConstraint: CGFloat = mainStackViewBottomConstraint.constant
        let viewPadding: CGFloat = topConstraint + bottomConstraint
        
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
        
        let participantsInformationAreaHeight =  participantsInformationStackView.spacing
            + participantsInformationHeight
        let descriptionAreaHeight = descriptionStackView.spacing
            + descriptionLabelSize.height
        let confidentialityAreaHeight = confidentialityAndAuthenticityStackView.spacing
            + confidentialityStackView.spacing
            + confidentialityImageView.bounds.height
            + confidentialityLabelSize.height
        let authenticityAreaHeight = authenticityStackView.spacing
            + authenticityImageView.bounds.height
            + authenticityLabelSize.height
        
        
        let totalHeight = viewPadding
            + mainStackView.spacing
            + participantsInformationAreaHeight
            + descriptionAreaHeight
            + confidentialityAreaHeight
            + authenticityAreaHeight
        
        return CGSize(width: size.width, height: totalHeight)
    }
}

extension ChatViewIntroductionHeaderView: MEGARequestDelegate {
    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        guard error.type == .apiOk else {
            MEGALogError("ChatMessageHeaderView: Could not fetch avatar image")
            return
        }
        //        fix me

//        avatarImageView.image = chatRoom?.avatarImage(delegate: nil)
    }
}
