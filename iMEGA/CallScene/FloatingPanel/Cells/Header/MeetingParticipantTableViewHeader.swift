import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGAUI
import SwiftUI

final class MeetingParticipantTableViewHeader: UITableViewHeaderFooterView {
    
    struct ViewConfig: Equatable {
        static func == (lhs: MeetingParticipantTableViewHeader.ViewConfig, rhs: MeetingParticipantTableViewHeader.ViewConfig) -> Bool {
            lhs.title == rhs.title &&
            lhs.actionButtonNormalTitle == rhs.actionButtonNormalTitle &&
            lhs.actionButtonDisabledTitle == rhs.actionButtonDisabledTitle &&
            lhs.actionButtonHidden == rhs.actionButtonHidden &&
            lhs.actionButtonEnabled == rhs.actionButtonEnabled &&
            lhs.callAllButtonHidden == rhs.callAllButtonHidden &&
            lhs.infoViewModel == rhs.infoViewModel
        }
        
        var title: String
        var actionButtonNormalTitle: String
        var actionButtonDisabledTitle: String
        var actionButtonHidden: Bool
        var actionButtonEnabled: Bool
        var callAllButtonHidden: Bool
        var actionButtonTappedHandler: () -> Void
        var infoViewModel: MeetingInfoHeaderData?
    }
    
    private var titleLabel: UILabel!
    private var warningLabel: UILabel!
    private var closeButton: UIButton!
    private var warningStack: UIStackView!
    private var actionButton: UIButton!
    private var callAllIcon: UIImageView!
    private var actionButtonTappedHandler: (() -> Void)?
    private var closeButtonTappedHandler: (() -> Void)?
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        isOpaque = true
        overrideUserInterfaceStyle = .dark
        titleLabel = UILabel()
        actionButton = UIButton()
        callAllIcon = UIImageView(image: MEGAAssets.UIImage.phoneCallAll)
        
        callAllIcon.contentMode = .center
        closeButton = UIButton()
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        warningLabel = UILabel()
        titleLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        titleLabel.textColor = .white // static color does change when dark/light mode changes
        warningLabel.preferredMaxLayoutWidth = 300
        warningLabel.font  = UIFont.preferredFont(forTextStyle: .caption2).bold()
        actionButton.setTitleColor(TokenColors.Link.primary, for: .normal)
        actionButton.setTitleColor(TokenColors.Link.primary.withAlphaComponent(0.4), for: .disabled)
        actionButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        callAllIcon.translatesAutoresizingMaskIntoConstraints = false
        
        let stackH = UIStackView(
            arrangedSubviews: [
                titleLabel,
                actionButton,
                callAllIcon
            ]
        )
        stackH.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        stackH.isLayoutMarginsRelativeArrangement = true
        stackH.axis = .horizontal
        stackH.translatesAutoresizingMaskIntoConstraints = false
        
        warningStack = UIStackView(
            arrangedSubviews: [
                warningLabel,
                closeButton
            ]
        )
        warningStack.axis = .horizontal
        warningStack.translatesAutoresizingMaskIntoConstraints = false
        warningStack.layoutMargins = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        warningStack.isLayoutMarginsRelativeArrangement = true
        let stackV = UIStackView(
            arrangedSubviews: [
                stackH,
                warningStack
            ]
        )
        stackV.translatesAutoresizingMaskIntoConstraints = false
        stackV.axis = .vertical
        contentView.addSubview(stackV)
        contentView.wrap(stackV)
        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    func configureWith(config: ViewConfig, parent: UIView) {
        actionButtonTappedHandler = config.actionButtonTappedHandler
        titleLabel.text = config.title
        actionButton.setTitle(config.actionButtonNormalTitle, for: .normal)
        actionButton.setTitle(config.actionButtonDisabledTitle, for: .disabled)
        actionButton.isHidden = config.actionButtonHidden
        actionButton.isEnabled = config.actionButtonEnabled
        callAllIcon.isHidden = config.callAllButtonHidden
        
        if let info = config.infoViewModel {
            let theme = BannerView.Config.Theme.darkMeetingsFloatingPanel
            closeButtonTappedHandler = info.dismissTapped
            warningLabel.text = info.copy
            warningLabel.textColor = theme.foregroundUIColor
            closeButton.tintColor = theme.foregroundUIColor
            warningStack.backgroundColor = UIColor(theme.background)
            warningLabel.numberOfLines = 0
            warningStack.isHidden = false
        } else {
            warningStack.isHidden = true
        }
    }
    
    @objc private func actionButtonTapped(_ sender: UIButton) {
        actionButtonTappedHandler?()
    }
    
    @objc private func closeButtonTapped(_ sender: UIButton) {
        closeButtonTappedHandler?()
    }
}
