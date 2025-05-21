import FirebaseCrashlytics
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import PanModal
import SwiftUI
import UIKit

final class MeetingFloatingPanelViewController: UIViewController {
    
    enum Constants {
        static let viewShortFormHeight: CGFloat = 164.0
        static let viewMaxWidth: CGFloat = 500.0
        static let backgroundViewCornerRadius: CGFloat = 13.0
        static let dragIndicatorCornerRadius: CGFloat = 2.5
        static let maxParticipantsToListInWaitingRoom = 4
    }

    @IBOutlet private weak var dragIndicatorView: UIView!
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var participantsTableView: UITableView!

    @IBOutlet private weak var optionsStackView: UIStackView!
    @IBOutlet private weak var shareLinkLabel: UILabel!
    
    @IBOutlet private weak var optionsStackViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet private var floatingViewSuperViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet private var floatingViewConstantViewWidthConstraint: NSLayoutConstraint!

    private var callParticipants: [CallParticipantEntity] = []
    private let viewModel: MeetingFloatingPanelViewModel
    private let userImageUseCase: any UserImageUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let chatRoomUserUseCase: any ChatRoomUserUseCaseProtocol
    private let megaHandleUseCase: any MEGAHandleUseCaseProtocol
    private let chatUseCase: any ChatUseCaseProtocol

    private let callControlsViewHost: UIViewController
    
    private var isAllowNonHostToAddParticipantsEnabled = false
    private var callParticipantsListView: ParticipantsListView?
    
    init(viewModel: MeetingFloatingPanelViewModel,
         userImageUseCase: some UserImageUseCaseProtocol,
         accountUseCase: any AccountUseCaseProtocol,
         chatRoomUseCase: any ChatRoomUseCaseProtocol,
         chatRoomUserUseCase: any ChatRoomUserUseCaseProtocol,
         megaHandleUseCase: any MEGAHandleUseCaseProtocol,
         chatUseCase: some ChatUseCaseProtocol,
         callControlsViewHost: UIViewController
    ) {
        self.viewModel = viewModel
        self.userImageUseCase = userImageUseCase
        self.accountUseCase = accountUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.chatRoomUserUseCase = chatRoomUserUseCase
        self.megaHandleUseCase = megaHandleUseCase
        self.chatUseCase = chatUseCase
        self.callControlsViewHost = callControlsViewHost
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark

        backgroundView.backgroundColor = TokenColors.Background.surface1
        backgroundView.layer.cornerRadius = Constants.backgroundViewCornerRadius
        dragIndicatorView.layer.cornerRadius = Constants.dragIndicatorCornerRadius

        shareLinkLabel.textColor = TokenColors.Text.accent
        
        registerTableViewCells()
        
        viewModel.invokeCommand = { [weak self] in
            self?.executeCommand($0)
        }
        viewModel.dispatch(.onViewReady)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.dispatch(.onViewAppear)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        addCallControlsView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if view.frame.width > Constants.viewMaxWidth {
            self.floatingViewSuperViewWidthConstraint.isActive = false
            self.floatingViewConstantViewWidthConstraint.isActive = true
        } else {
            self.floatingViewConstantViewWidthConstraint.isActive = false
            self.floatingViewSuperViewWidthConstraint.isActive = true
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.panModalSetNeedsLayoutUpdate()
            self?.panModalTransition(to: .shortForm)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - Dispatch action
    func executeCommand(_ command: MeetingFloatingPanelViewModel.Command) {
        switch command {
        case .configView(let canInviteParticipants,
                         let isOneToOneCall,
                         let isMeeting,
                         let allowNonHostToAddParticipantsEnabled,
                         let isMyselfAModerator):
            updateUI(canInviteParticipants: canInviteParticipants,
                     isOneToOneCall: isOneToOneCall,
                     isMeeting: isMeeting,
                     allowNonHostToAddParticipantsEnabled: allowNonHostToAddParticipantsEnabled,
                     isMyselfAModerator: isMyselfAModerator)
        case .microphoneMuted(let muted):
            if let myHandle = accountUseCase.currentUserHandle,
               let participant = callParticipants.first(where: { $0.participantId == myHandle }) {
                participant.audio = muted ? .off : .on
                participantsTableView.reloadData()
            }
        case .cameraTurnedOn(let on):
            if let myHandle = accountUseCase.currentUserHandle,
               let participant = callParticipants.first(where: { $0.participantId == myHandle }) {
                participant.video = on ? .on : .off
                participantsTableView.reloadData()
            }
        case .reloadParticipantsList(let participants):
            callParticipants = participants
            participantsTableView.reloadData()
        case .transitionToShortForm:
            panModalSetNeedsLayoutUpdate()
            panModalTransition(to: .shortForm)
        case .transitionToLongForm:
            panModalTransition(to: .longForm)
            panModalSetNeedsLayoutUpdate()
        case .updateAllowNonHostToAddParticipants(let enabled):
            isAllowNonHostToAddParticipantsEnabled = enabled
            participantsTableView.reloadSections([0], with: .automatic)
        case .reloadViewData(let participantListView):
            callParticipantsListView = participantListView
            callParticipants = participantListView.participants
            participantsTableView.reloadData()
        }
    }
    
    // MARK: - Actions
    
    @IBAction func shareLink(_ sender: UIButton) {
        viewModel.dispatch(
            .participantListShareLinkButtonPressed(
                presenter: self,
                sender: sender
            )
        )
    }
    
    // MARK: - Private methods
    
    private func updateUI(canInviteParticipants: Bool,
                          isOneToOneCall: Bool,
                          isMeeting: Bool,
                          allowNonHostToAddParticipantsEnabled: Bool,
                          isMyselfAModerator: Bool) {
        // checking if the implicitly unwrapped optional are loaded from XIBS yet [MEET-4517]
        if isOneToOneCall {
            if optionsStackView != nil {
                optionsStackView.arrangedSubviews.forEach({ $0.removeFromSuperview() })
            }
            if optionsStackViewHeightConstraint != nil {
                optionsStackViewHeightConstraint.constant = 0.0
            }
        }
        if shareLinkLabel != nil {
            shareLinkLabel.text = isMeeting ? Strings.Localizable.Meetings.Action.shareLink : Strings.Localizable.Meetings.Panel.shareLink
        }
        isAllowNonHostToAddParticipantsEnabled = allowNonHostToAddParticipantsEnabled
    }
}

extension MeetingFloatingPanelViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let callParticipantsListView else { return 0 }
        switch callParticipantsListView.sections[indexPath.section] {
        case .participants:
            return callParticipants.isNotEmpty ? 60 : 250
        default:
            return 60
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        guard let callParticipantsListView else { return 0 }
        return callParticipantsListView.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let callParticipantsListView else { return 0 }
        switch callParticipantsListView.sections[section] {
        case .hostControls:
            return callParticipantsListView.hostControlsRows.count
        case .invite:
            return callParticipantsListView.inviteSectionRow.count
        case .participants:
            if callParticipants.isEmpty {
                return 1
            } else if callParticipantsListView.selectedTab == .waitingRoom {
                return callParticipants.count <= Constants.maxParticipantsToListInWaitingRoom ? callParticipants.count : Constants.maxParticipantsToListInWaitingRoom + 1
            } else {
                return callParticipants.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let callParticipantsListView else { return UITableViewCell() }
        switch callParticipantsListView.sections[indexPath.section] {
        case .hostControls:
            switch callParticipantsListView.hostControlsRows[indexPath.row] {
            case .allowNonHostToInvite:
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: AllowNonHostToInviteTableViewCell.reuseIdentifier, for: indexPath) as? AllowNonHostToInviteTableViewCell else { return UITableViewCell() }
                    cell.allowNonHostSwitchEnabled(isAllowNonHostToAddParticipantsEnabled)
                    cell.switchToggleHandler = { [weak self] allowNonHostToAddParticipantsSwitch in
                        self?.viewModel.dispatch(.allowNonHostToAddParticipants(enabled: allowNonHostToAddParticipantsSwitch.isOn))
                    }
                    return cell
            case .listSelector:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: ParticipantsListSelectorTableViewCell.reuseIdentifier, for: indexPath) as? ParticipantsListSelectorTableViewCell else { return UITableViewCell() }
                cell.configureFor(tabs: callParticipantsListView.tabs, selectedTab: callParticipantsListView.selectedTab)
                cell.segmentedControlChangeHandler = { [weak self] selectedTab in
                    self?.viewModel.dispatch(.selectParticipantsList(selectedTab: selectedTab))
                }
                return cell
            }
        case .invite:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MeetingInviteParticipantTableViewCell.reuseIdentifier, for: indexPath) as? MeetingInviteParticipantTableViewCell else { return UITableViewCell() }
            cell.cellTappedHandler = { [weak self] in
                self?.viewModel.dispatch(.inviteParticipantsRowTapped)
            }
            return cell
        case .participants:
            switch callParticipantsListView.selectedTab {
            case .inCall:
                return participantInCallCell(at: indexPath)
            case .notInCall:
                return callParticipants.isEmpty ? emptyParticipantsListCell(at: indexPath) : participantNotInCallCell(at: indexPath)
            case .waitingRoom:
                guard callParticipants.isNotEmpty else {
                    return emptyParticipantsListCell(at: indexPath)
                }
                switch indexPath.row {
                case Constants.maxParticipantsToListInWaitingRoom:
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: SeeAllParticipantsInWaitingRoomTableViewCell.reuseIdentifier, for: indexPath) as? SeeAllParticipantsInWaitingRoomTableViewCell else { return UITableViewCell() }
                    cell.seeAllButtonTappedHandler = { [weak self] in
                        self?.viewModel.dispatch(.seeMoreParticipantsInWaitingRoomTapped)
                    }
                    return cell
                default:
                    return participantInWaitingRoomCell(at: indexPath)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let callParticipantsListView else { return nil }
        switch callParticipantsListView.sections[section] {
        case .invite:
            guard callParticipants.isNotEmpty, let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: MeetingParticipantTableViewHeader.reuseIdentifier) as? MeetingParticipantTableViewHeader else { return UIView(frame: .zero) }
            
            header.configureWith(config: callParticipantsListView.headerConfig, parent: tableView)
            return header
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let callParticipantsListView else { return 0 }
        switch callParticipantsListView.sections[section] {
        case .invite:
            return UITableView.automaticDimension
        default:
            return 0
        }
    }
    
    private func registerTableViewCells() {
        participantsTableView.register(MeetingParticipantTableViewCell.nib, forCellReuseIdentifier: MeetingParticipantTableViewCell.reuseIdentifier)
        participantsTableView.register(MeetingInviteParticipantTableViewCell.nib, forCellReuseIdentifier: MeetingInviteParticipantTableViewCell.reuseIdentifier)
        participantsTableView.register(AllowNonHostToInviteTableViewCell.nib, forCellReuseIdentifier: AllowNonHostToInviteTableViewCell.reuseIdentifier)
        participantsTableView.register(ParticipantsListSelectorTableViewCell.nib, forCellReuseIdentifier: ParticipantsListSelectorTableViewCell.reuseIdentifier)
        participantsTableView.register(ParticipantNotInCallTableViewCell.nib, forCellReuseIdentifier: ParticipantNotInCallTableViewCell.reuseIdentifier)
        participantsTableView.register(ParticipantInWaitingRoomTableViewCell.nib, forCellReuseIdentifier: ParticipantInWaitingRoomTableViewCell.reuseIdentifier)
        participantsTableView.register(SeeAllParticipantsInWaitingRoomTableViewCell.nib, forCellReuseIdentifier: SeeAllParticipantsInWaitingRoomTableViewCell.reuseIdentifier)
        participantsTableView.register(MeetingParticipantTableViewHeader.self, forHeaderFooterViewReuseIdentifier: MeetingParticipantTableViewHeader.reuseIdentifier)
        participantsTableView.register(EmptyParticipantsListTableViewCell.nib, forCellReuseIdentifier: EmptyParticipantsListTableViewCell.reuseIdentifier)
    }
    
    private func participantInCallCell(at indexPath: IndexPath) -> MeetingParticipantTableViewCell {
        guard let cell = participantsTableView.dequeueReusableCell(withIdentifier: MeetingParticipantTableViewCell.reuseIdentifier, for: indexPath) as? MeetingParticipantTableViewCell, let participant = callParticipants[safe: indexPath.row] else {
            reportWrongParticipantIndex(for: indexPath)
            return MeetingParticipantTableViewCell()
        }
        cell.viewModel = MeetingParticipantViewModel(
            participant: participant,
            userImageUseCase: userImageUseCase,
            accountUseCase: accountUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: chatRoomUserUseCase,
            megaHandleUseCase: megaHandleUseCase
        ) { [weak self] participant, button in
            guard let self else { return }
            viewModel.dispatch(.onContextMenuTap(presenter: self, sender: button, participant: participant))
        }
        return cell
    }
    
    private func participantNotInCallCell(at indexPath: IndexPath) -> ParticipantNotInCallTableViewCell {
        guard let cell = participantsTableView.dequeueReusableCell(withIdentifier: ParticipantNotInCallTableViewCell.reuseIdentifier, for: indexPath) as? ParticipantNotInCallTableViewCell else { return ParticipantNotInCallTableViewCell() }
        cell.viewModel = ParticipantNotInCallViewModel(
            participant: callParticipants[indexPath.row],
            userImageUseCase: userImageUseCase,
            accountUseCase: accountUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: chatRoomUserUseCase,
            megaHandleUseCase: megaHandleUseCase,
            chatUseCase: chatUseCase
        ) { [weak self] participant in
            guard let self else { return }
            viewModel.dispatch(.callAbsentParticipant(participant))
        }
        return cell
    }
    
    private func participantInWaitingRoomCell(at indexPath: IndexPath) -> ParticipantInWaitingRoomTableViewCell {
        guard let cell = participantsTableView.dequeueReusableCell(withIdentifier: ParticipantInWaitingRoomTableViewCell.reuseIdentifier, for: indexPath) as? ParticipantInWaitingRoomTableViewCell else { return ParticipantInWaitingRoomTableViewCell() }
        cell.viewModel = ParticipantInWaitingRoomViewModel(
            participant: callParticipants[indexPath.row],
            userImageUseCase: userImageUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: chatRoomUserUseCase,
            megaHandleUseCase: megaHandleUseCase,
            admitButtonEnabled: callParticipantsListView?.waitingRoomConfig?.allowIndividualWaitlistAdmittance ?? false,
            admitButtonTappedHandler: { [weak self] participant in
                self?.viewModel.dispatch(.onAdmitParticipantTap(participant: participant))
            },
            denyButtonMenuTappedHandler: { [weak self] participant in
                self?.viewModel.dispatch(.onDenyParticipantTap(participant: participant))
            })
        return cell
    }
    
    private func emptyParticipantsListCell(at indexPath: IndexPath) -> EmptyParticipantsListTableViewCell {
        guard let callParticipantsListView, let cell = participantsTableView.dequeueReusableCell(withIdentifier: EmptyParticipantsListTableViewCell.reuseIdentifier, for: indexPath) as? EmptyParticipantsListTableViewCell else { return EmptyParticipantsListTableViewCell() }
        cell.configure(for: callParticipantsListView.selectedTab)
        return cell
    }
    
    private func addCallControlsView() {
        guard let swiftUIView = callControlsViewHost.view else { return }
        
        addChild(callControlsViewHost)
        participantsTableView.tableHeaderView?.addSubview(callControlsViewHost.view)
        
        callControlsViewHost.view.translatesAutoresizingMaskIntoConstraints = false
        callControlsViewHost.didMove(toParent: self)
        
        NSLayoutConstraint.activate([
            swiftUIView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            swiftUIView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            swiftUIView.heightAnchor.constraint(equalToConstant: 105)
        ])
        
        view.bringSubviewToFront(swiftUIView)
    }
}

extension MeetingFloatingPanelViewController {
    private func reportWrongParticipantIndex(for indexPath: IndexPath) {
        let userInfo: [String: Any] = [
            "callParticipantsListView data": String(describing: callParticipantsListView),
            "indexPath": indexPath
        ]
        let error = NSError.init(
            domain: "nz.mega.meetingfloatingpanelviewcontroller",
            code: 0,
            userInfo: userInfo
        )
        Crashlytics.crashlytics().record(error: error)
    }
}

extension MeetingFloatingPanelViewController: PanModalPresentable {
    var panScrollable: UIScrollView? {
        participantsTableView
    }
    
    var longFormHeight: PanModalHeight {
        .maxHeight
    }
    
    var shortFormHeight: PanModalHeight {
        .contentHeight(Constants.viewShortFormHeight)
    }
    
    var panModalBackgroundColor: UIColor {
        MEGAAssets.UIColor.black000000.withAlphaComponent(0)
    }

    var anchorModalToLongForm: Bool {
        false
    }
    
    var allowsTapToDismiss: Bool {
        false
    }
    
    var allowsDragToDismiss: Bool {
        false
    }
    
    var backgroundInteraction: PanModalBackgroundInteraction {
        .forward
    }
    
    var showDragIndicator: Bool {
        false
    }
    
    var allowsExtendedPanScrolling: Bool {
        true
    }
    
    func willTransition(to state: PanModalPresentationController.PresentationState) {
        viewModel.dispatch(.panelTransitionIsLongForm(state == .longForm))
    }
}
