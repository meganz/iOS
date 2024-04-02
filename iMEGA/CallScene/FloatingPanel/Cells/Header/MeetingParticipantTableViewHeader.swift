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
    private var actionButton: UIButton!
    private var callAllIcon: UIImageView!
    private var header: UIView!
    private var actionButtonTappedHandler: (() -> Void)?
    private let hosting = UIHostingController(
        rootView: AnyView(BannerView(config: .empty))
    )
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        titleLabel = UILabel()
        actionButton = UIButton()
        callAllIcon = UIImageView(image: UIImage.phoneCallAll)
        callAllIcon.contentMode = .center
        
        titleLabel.font = UIFont.preferredFont(forTextStyle: .callout)
        titleLabel.textColor = .white // static color does change when dark/light mode changes
        
        let titleColor = UIColor.isDesignTokenEnabled()
        ? TokenColors.Support.success
        : MEGAAppColor.Green._00A886.uiColor
        actionButton.setTitleColor(titleColor, for: .normal)
        actionButton.setTitleColor(titleColor.withAlphaComponent(0.4), for: .disabled)
        actionButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        
        header = hosting.view

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        callAllIcon.translatesAutoresizingMaskIntoConstraints = false
        header.translatesAutoresizingMaskIntoConstraints = false
        
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
        
        let stackV = UIStackView(
            arrangedSubviews: [
                stackH,
                header
            ]
        )
        stackV.translatesAutoresizingMaskIntoConstraints = false
        stackV.axis = .vertical
        contentView.addSubview(stackV)
        contentView.wrap(stackV)
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
            let config = BannerView.Config(
                copy: info.copy,
                underline: true,
                theme: .darkMeetingsFloatingPanel,
                closeAction: info.dismissTapped,
                tapAction: info.linkTapped
            )
            
            let view = BannerView(config: config).font(.footnote)
            hosting.rootView = AnyView(view)
            // meetings only support single interface style - dark
            // override this to force just single theme
            hosting.overrideUserInterfaceStyle = .dark
            let size = hosting.sizeThatFits(in: parent.frame.size)
            // Seem to be reliable way to have the dynamic height of the table view header working
            // by forcing the height calculated by SwiftUI
            let heightConstraintId = "123"
            if let constraint = hosting.view.constraints.first(where: { $0.identifier == heightConstraintId}) {
                constraint.constant = size.height
            } else {
                let anchor =  hosting.view.heightAnchor.constraint(equalToConstant: size.height)
                anchor.identifier = heightConstraintId
                NSLayoutConstraint.activate([
                    anchor
                ])
            }
            hosting.view.isHidden = false
        } else {
            hosting.view.isHidden = true
        }
        
    }
    
    @objc private func actionButtonTapped(_ sender: UIButton) {
        actionButtonTappedHandler?()
    }
}
