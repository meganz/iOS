import MEGADesignToken
import MEGAL10n
import MEGAUI
import SwiftUI

final class MeetingParticipantTableViewHeader: UITableViewHeaderFooterView {
    
    struct ViewConfig {
        var tab: ParticipantsListTab
        var participantsCount: Int
        var isMyselfModerator: Bool
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
        
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .white // static color does change when dark/light mode changes
        
        let titleColor = UIColor.isDesignTokenEnabled()
        ? TokenColors.Support.success
        : MEGAAppColor.Green._00A886.uiColor
        actionButton.setTitleColor(titleColor, for: .normal)
        actionButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .callout)
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
        addSubview(stackV)
        wrap(stackV)
    }
    
    func configureWith(config: ViewConfig) {
        configure(
            for: config.tab,
            participantsCount: config.participantsCount,
            isMyselfModerator: config.isMyselfModerator
        )
        actionButtonTappedHandler = config.actionButtonTappedHandler
        
        if let info = config.infoViewModel {
            let config = BannerView.Config(
                copy: info.copy,
                underline: true,
                theme: .dark,
                closeAction: nil,
                tapAction: info.linkTapped
            )
            
            let view = BannerView(config: config).font(.footnote)
            
            hosting.rootView = AnyView(view)
            hosting.view.isHidden = false
        } else {
            hosting.view.isHidden = true
        }
    }
    
    private func configure(
        for selectedTab: ParticipantsListTab,
        participantsCount: Int,
        isMyselfModerator: Bool
    ) {
        switch selectedTab {
        case .inCall:
            titleLabel.text = Strings.Localizable.Meetings.Panel.participantsCount(participantsCount)
            actionButton.setTitle(Strings.Localizable.Calls.Panel.ParticipantsInCall.Header.muteAll, for: .normal)
            actionButton.setTitle(Strings.Localizable.Calls.Panel.ParticipantsInCall.Header.allMuted, for: .disabled)
            actionButton.isHidden = !isMyselfModerator
            callAllIcon.isHidden = true
        case .notInCall:
            actionButton.isEnabled = true
            titleLabel.text = Strings.Localizable.Meetings.Panel.participantsNotInCallCount(participantsCount)
            actionButton.setTitle(Strings.Localizable.Calls.Panel.ParticipantsNotInCall.Header.callAll, for: .normal)
            actionButton.isHidden = callAllIcon.isHidden && participantsCount > 0 ? false : true
        case .waitingRoom:
            actionButton.isEnabled = true
            titleLabel.text = Strings.Localizable.Meetings.Panel.participantsInWaitingRoomCount(participantsCount)
            actionButton.setTitle(Strings.Localizable.Chat.Call.WaitingRoom.Alert.Button.admitAll, for: .normal)
            actionButton.isHidden = participantsCount > 0 ? false : true
            callAllIcon.isHidden = true
        }
    }
    
    func hideCallAllIcon(_ hide: Bool) {
        callAllIcon.isHidden = hide
    }
    
    func disableMuteAllButton(_ disable: Bool) {
        actionButton.isEnabled = !disable
    }
    
    @objc private func actionButtonTapped(_ sender: UIButton) {
        actionButtonTappedHandler?()
    }
}
