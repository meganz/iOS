import ChatRepo
import CoreGraphics
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAFoundation
import MEGAL10n
import MessageKit

class ChatViewIntroductionHeaderView: MessageReusableView {
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var mainLeadingDistance: NSLayoutConstraint!
    @IBOutlet weak var mainTrailingDistance: NSLayoutConstraint!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var topStackView: UIStackView!
    @IBOutlet weak var confidentialityStackView: UIStackView!
    @IBOutlet weak var authenticityStackView: UIStackView!
    @IBOutlet weak var participantsInformationStackView: UIStackView!
    @IBOutlet weak var noteToSelfStackView: UIStackView!

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var avatarImageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var avatarImageViewWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var chattingWithTextLabel: UILabel!
    @IBOutlet weak var participantsLabel: UILabel!
    
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var confidentialityImageView: UIImageView!
    @IBOutlet weak var confidentialityTextLabel: UILabel!

    @IBOutlet weak var authenticityImageView: UIImageView!
    @IBOutlet weak var authenticityTextLabel: UILabel!
    
    @IBOutlet weak var noteToSelfImageView: UIImageView!
    @IBOutlet weak var noteToSelfTextLabel: UILabel!
    
    private let contentSpacing: CGFloat = 20.0
    
    private let chatRoomUseCase = ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo)

    var chatRoom: ChatRoomEntity? {
        didSet {
            updateStatus()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureImages()
        updateAppearance()
    }
    
    private func configureImages() {
        confidentialityImageView.image = MEGAAssets.UIImage.image(named: "lock_welcomeMessage")
        authenticityImageView.image = MEGAAssets.UIImage.image(named: "checkmark_welcomeMessage")
        noteToSelfImageView.image = MEGAAssets.UIImage.image(named: "noteToSelfSmall")
    }
    
    private func updateStatus() {
        guard let chatRoom = chatRoom else {
            return
        }
        
        participantsLabel.text = chatRoom.isNoteToSelf ? Strings.Localizable.Chat.Messages.NoteToSelf.Header.title : participantNames(for: chatRoom)

        updateAvatar(for: chatRoom)
        updateStatusView(for: chatRoom)
        updateAppearance()
    }
    
    private func updateAvatar(for chatRoom: ChatRoomEntity) {
        if chatRoom.isGroup || chatRoom.isNoteToSelf {
            avatarImageView.isHidden = true
        } else {
            guard let userHandle = chatRoom.peers.first?.handle else { return }
            avatarImageView.image = UIImage.mnz_image(forUserHandle: userHandle, name: chatRoom.title ?? "", size: CGSize(width: 80, height: 80), delegate: self)
        }
    }
    
    private func updateStatusView(for chatRoom: ChatRoomEntity) {
        noteToSelfStackView.isHidden = true
        if chatRoom.chatType == .oneToOne {
            if let userHandle = chatRoom.oneToOneRoomOtherParticipantUserHandle() {
                let status = chatRoomUseCase.userStatus(forUserHandle: userHandle)
                statusView.isHidden = (status == .invalid)
                statusView.backgroundColor = status.uiColor
                
                statusLabel.isHidden = (status == .invalid)
                statusLabel.text = status.localizedIdentifier
            }
        } else if chatRoom.isMeeting {
            statusView.isHidden = true
            chattingWithTextLabel.isHidden = true
            guard let scheduledMeeting = MEGAChatSdk.shared.scheduledMeetings(byChat: chatRoom.chatId).first?.toScheduledMeetingEntity() else {
                statusLabel.isHidden = true
                return
            }
            
            participantsLabel.text = scheduledMeeting.title
            statusLabel.text = ScheduledMeetingDateBuilder(
                scheduledMeeting: scheduledMeeting
            ).buildDateDescriptionString()
        } else if chatRoom.isNoteToSelf {
            configureStatusViewForNoteToSelf()
        } else {
            statusView.isHidden = true
            statusLabel.isHidden = true
        }
    }
    
    private func configureStatusViewForNoteToSelf() {
        chattingWithTextLabel.isHidden = true
        descriptionLabel.isHidden = true
        authenticityStackView.isHidden = true
        confidentialityStackView.isHidden = true
        noteToSelfStackView.isHidden = false
        statusView.isHidden = true
        statusLabel.isHidden = true
    }
    
    private func formattedDateForScheduleMeeting(_ scheduledMeeting: ScheduledMeetingEntity) -> String {
        var dateFormatter: any DateFormatting = DateFormatter.timeShort()
        let start = dateFormatter.localisedString(from: scheduledMeeting.startDate)
        let end = dateFormatter.localisedString(from: scheduledMeeting.endDate)
        dateFormatter = DateFormatter.dateMedium()
        let fullDate = dateFormatter.localisedString(from: scheduledMeeting.startDate)
        return "\(fullDate) · \(start) - \(end)"
    }
    
    private func updateAppearance() {
        chattingWithTextLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        participantsLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        statusLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        chattingWithTextLabel.textColor = TokenColors.Components.interactive
        descriptionLabel.textColor = TokenColors.Text.secondary
        participantsLabel.textColor = TokenColors.Text.primary
        statusLabel.textColor = TokenColors.Text.secondary

        chattingWithTextLabel.text = Strings.Localizable.chattingWith
        descriptionLabel.text = Strings.Localizable.Chat.IntroductionHeader.Privacy.description
        
        let confidentialityText = Strings.Localizable.confidentialityExplanation
        setAttributedText(with: confidentialityText, label: confidentialityTextLabel)
        
        let authenticityText = Strings.Localizable.authenticityExplanation
        setAttributedText(with: authenticityText, label: authenticityTextLabel)
        
        if let userHandle = chatRoom?.peers.first?.handle {
            let status = chatRoomUseCase.userStatus(forUserHandle: userHandle)
            statusView.backgroundColor = status.uiColor
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateAppearance()
    }
    
    private func setAttributedText(with string: String, label: UILabel) {
        let title = (string as NSString).mnz_stringBetweenString("[S]", andString: "[/S]")!
        let description = (string as NSString).replacingOccurrences(of: String(format: "[S]%@[/S]", title), with: "")
        
        let titleAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .subheadline),
                                                               NSAttributedString.Key.foregroundColor: UIColor.mnz_red()]
        let titleAttributedString = NSMutableAttributedString(string: title, attributes: titleAttributes)
        
        let descriptionAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .subheadline),
                                                                     NSAttributedString.Key.foregroundColor: TokenColors.Text.secondary]
        let descriptionAttributedString = NSMutableAttributedString(string: description, attributes: descriptionAttributes)
        
        titleAttributedString.append(descriptionAttributedString)
        label.attributedText = titleAttributedString
        label.adjustsFontForContentSizeCategory = true
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let maxSize = CGSize(width: size.width - mainLeadingDistance.constant - mainTrailingDistance.constant, height: size.height)
        let participantsInformationAvailableWidth = avatarImageView.isHidden ? maxSize.width : maxSize.width - avatarImageViewWidthConstraint.constant
        let participantsInformationAvailableSize = CGSize(width: participantsInformationAvailableWidth, height: size.height)
        
        let chattingWithTextLabelSize = chattingWithTextLabel.sizeThatFits(participantsInformationAvailableSize)
        let participantsLabelSize = participantsLabel.sizeThatFits(participantsInformationAvailableSize)
        let statusLabelSize = statusLabel.text?.isEmpty ?? true ? .zero : statusLabel.sizeThatFits(participantsInformationAvailableSize)
        let participantInformationHeight = statusLabelSize == .zero ?
                                                                chattingWithTextLabelSize.height + participantsInformationStackView.spacing + participantsLabelSize.height
                                                                : chattingWithTextLabelSize.height + participantsInformationStackView.spacing + participantsLabelSize.height + participantsInformationStackView.spacing + statusLabelSize.height
        
        let participantsInformationHeight = max(avatarImageViewHeightConstraint.constant, participantInformationHeight)
        
        let totalHeight = calculateFittingHeight(with: participantsInformationHeight, maxSize: maxSize)
        
        return CGSize(width: size.width, height: totalHeight)
    }
    
    private func calculateFittingHeight(with participantsInfoHeight: CGFloat, maxSize: CGSize) -> CGFloat {
        let descriptionHeight = calculateLabelHeight(for: descriptionLabel, maxSize: maxSize, includeSpacing: true)
        let confidentialityHeight = calculateStackViewHeight(for: confidentialityStackView, imageView: confidentialityImageView, label: confidentialityTextLabel, maxSize: maxSize, includeSpacing: true)
        let authenticityHeight = calculateStackViewHeight(for: authenticityStackView, imageView: authenticityImageView, label: authenticityTextLabel, maxSize: maxSize, includeSpacing: false)
        let noteToSelfHeight = calculateStackViewHeight(for: noteToSelfStackView, imageView: noteToSelfImageView, label: noteToSelfTextLabel, maxSize: maxSize, includeSpacing: false)

        return topConstraint.constant
            + participantsInfoHeight
            + descriptionHeight
            + confidentialityHeight
            + authenticityHeight
            + noteToSelfHeight
            + bottomConstraint.constant
    }

    private func calculateLabelHeight(for label: UILabel, maxSize: CGSize, includeSpacing: Bool) -> CGFloat {
        guard !label.isHidden else { return 0 }
        return label.sizeThatFits(maxSize).height + (includeSpacing ? mainStackView.spacing : 0)
    }

    private func calculateStackViewHeight(for stackView: UIStackView, imageView: UIImageView, label: UILabel, maxSize: CGSize, includeSpacing: Bool) -> CGFloat {
        guard !stackView.isHidden else { return 0 }
        let labelHeight = label.sizeThatFits(maxSize).height
        let imageHeight = imageView.bounds.height
        let spacing = stackView.spacing
        return labelHeight + imageHeight + spacing + (includeSpacing ? mainStackView.spacing : 0)
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
