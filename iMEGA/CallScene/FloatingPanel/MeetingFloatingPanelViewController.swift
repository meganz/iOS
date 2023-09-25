import MEGADomain
import MEGAL10n
import PanModal
import UIKit

final class MeetingFloatingPanelViewController: UIViewController {
    
    enum Constants {
        static let viewShortFormHeight: CGFloat = 164.0
        static let viewMaxWidth: CGFloat = 500.0
        static let viewMaxHeight: CGFloat = 800.0
        static let backgroundViewCornerRadius: CGFloat = 13.0
        static let dragIndicatorCornerRadius: CGFloat = 2.5
    }

    @IBOutlet private weak var dragIndicatorView: UIView!
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var participantsTableView: UITableView!

    @IBOutlet private weak var cameraQuickActionView: MeetingQuickActionView!
    @IBOutlet private weak var muteQuickActionView: MeetingQuickActionView!
    @IBOutlet private weak var endQuickActionView: MeetingQuickActionView!
    @IBOutlet private weak var speakerQuickActionView: MeetingSpeakerQuickActionView!
    @IBOutlet private weak var flipQuickActionView: MeetingQuickActionView!

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
    private var isAllowNonHostToAddParticipantsEnabled = false
    private var shouldHideHostControls = false

    init(viewModel: MeetingFloatingPanelViewModel,
         userImageUseCase: some UserImageUseCaseProtocol,
         accountUseCase: any AccountUseCaseProtocol,
         chatRoomUseCase: any ChatRoomUseCaseProtocol,
         chatRoomUserUseCase: any ChatRoomUserUseCaseProtocol,
         megaHandleUseCase: any MEGAHandleUseCaseProtocol) {
        self.viewModel = viewModel
        self.userImageUseCase = userImageUseCase
        self.accountUseCase = accountUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.chatRoomUserUseCase = chatRoomUserUseCase
        self.megaHandleUseCase = megaHandleUseCase
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundView.backgroundColor = Colors.General.Black._2c2c2e.color
        backgroundView.layer.cornerRadius = Constants.backgroundViewCornerRadius
        dragIndicatorView.layer.cornerRadius = Constants.dragIndicatorCornerRadius
        endQuickActionView.icon = UIImage(resource: .hangCallMeetingAction)
        endQuickActionView.name = Strings.Localizable.leave
        shareLinkLabel.text = Strings.Localizable.Meetings.Panel.shareLink
        participantsTableView.register(MeetingParticipantTableViewCell.nib, forCellReuseIdentifier: MeetingParticipantTableViewCell.reuseIdentifier)
        participantsTableView.register(MeetingInviteParticipantTableViewCell.nib, forCellReuseIdentifier: MeetingInviteParticipantTableViewCell.reuseIdentifier)
        participantsTableView.register(AllowNonHostToInviteTableViewCell.nib, forCellReuseIdentifier: AllowNonHostToInviteTableViewCell.reuseIdentifier)
        participantsTableView.register(MeetingParticipantTableViewHeader.nib, forHeaderFooterViewReuseIdentifier: MeetingParticipantTableViewHeader.reuseIdentifier)

        flipQuickActionView.disabled = true
        
        let quickActionProperties = MeetingQuickActionView.Properties(
            iconTintColor: MeetingQuickActionView.Properties.StateColor(normal: .white, selected: .black),
            backgroundColor: MeetingQuickActionView.Properties.StateColor(normal: .mnz_gray474747(), selected: .white)
        )
        let quickActions = [cameraQuickActionView, muteQuickActionView, speakerQuickActionView, flipQuickActionView]
        quickActions.forEach { $0?.properties = quickActionProperties }
        
        [cameraQuickActionView: Strings.Localizable.Chat.Call.QuickAction.camera,
           muteQuickActionView: Strings.Localizable.mute,
        speakerQuickActionView: Strings.Localizable.Meetings.QuickAction.speaker,
           flipQuickActionView: Strings.Localizable.Meetings.QuickAction.flip
        ].forEach { (view, key) in
            view?.name = key
        }
        
        viewModel.invokeCommand = { [weak self] in
            self?.executeCommand($0)
        }
        viewModel.dispatch(.onViewReady)
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
                         let isOneToOneMeeting,
                         let isVideoEnabled,
                         let cameraPosition,
                         let allowNonHostToAddParticipantsEnabled,
                         let isMyselfAModerator):
            updateUI(canInviteParticipants: canInviteParticipants,
                     isOneToOneMeeting: isOneToOneMeeting,
                     isVideoEnabled: isVideoEnabled,
                     cameraPosition: cameraPosition,
                     allowNonHostToAddParticipantsEnabled: allowNonHostToAddParticipantsEnabled,
                     isMyselfAModerator: isMyselfAModerator)
        case .enabledLoudSpeaker(let enabled):
            speakerQuickActionView?.isSelected = enabled
        case .microphoneMuted(let muted):
            if let myHandle = accountUseCase.currentUserHandle,
               let participant = callParticipants.first(where: { $0.participantId == myHandle }) {
                participant.audio = muted ? .off : .on
                participantsTableView.reloadData()
            }
            muteQuickActionView.isSelected = muted
        case .updatedCameraPosition(let position):
            updatedCameraPosition(position)
        case .cameraTurnedOn(let on):
            if let myHandle = accountUseCase.currentUserHandle,
               let participant = callParticipants.first(where: { $0.participantId == myHandle }) {
                participant.video = on ? .on : .off
                participantsTableView.reloadData()
            }
            cameraQuickActionView.isSelected = on
            flipQuickActionView.disabled = !on
        case .reloadParticpantsList(let participants):
            callParticipants = participants
            participantsTableView?.reloadData()
        case .updatedAudioPortSelection(let audioPort, let bluetoothAudioRouteAvailable):
            selectedAudioPortUpdated(audioPort, isBluetoothRouteAvailable: bluetoothAudioRouteAvailable)
        case .transitionToShortForm:
            panModalSetNeedsLayoutUpdate()
            panModalTransition(to: .shortForm)
        case .updateAllowNonHostToAddParticipants(let enabled):
            isAllowNonHostToAddParticipantsEnabled = enabled
            participantsTableView.reloadSections([0], with: .automatic)
        }
    }
    
    // MARK: - Actions
    
    @IBAction func hangCall(_ sender: UIButton) {
        viewModel.dispatch(.hangCall(presenter: self, sender: sender))
    }
    
    @IBAction func shareLink(_ sender: UIButton) {
        viewModel.dispatch(.shareLink(presenter: self, sender: sender))
    }
    
    @IBAction func toggleCameraOnTapped(_ sender: UIButton) {
        viewModel.dispatch(.turnCamera(on: !cameraQuickActionView.isSelected))
    }
    
    @IBAction func toggleMuteTapped(_ sender: UIButton) {
        viewModel.dispatch(.muteUnmuteCall(mute: !muteQuickActionView.isSelected))
    }
    
    @IBAction func switchSpeakersTapped(_ sender: UIButton) {
        speakerQuickActionView.isSelected = !speakerQuickActionView.isSelected
        viewModel.dispatch(speakerQuickActionView.isSelected ? .enableLoudSpeaker : .disableLoudSpeaker)
    }
    
    @IBAction func switchCameraTapped(_ sender: UIButton) {
        guard !flipQuickActionView.disabled else { return }
        viewModel.dispatch(.switchCamera(backCameraOn: !flipQuickActionView.isSelected))
    }
    
    // MARK: - Private methods
    
    private func updatedCameraPosition(_ position: CameraPositionEntity) {
        flipQuickActionView.isSelected = position == .back
    }
    
    private func selectedAudioPortUpdated(_ selectedAudioPort: AudioPort, isBluetoothRouteAvailable: Bool) {
        if isBluetoothRouteAvailable {
            speakerQuickActionView?.addRoutingView()
        } else {
            speakerQuickActionView?.removeRoutingView()
        }
        speakerQuickActionView?.selectedAudioPortUpdated(selectedAudioPort, isBluetoothRouteAvailable: isBluetoothRouteAvailable)
    }
    
    private func updateUI(canInviteParticipants: Bool,
                          isOneToOneMeeting: Bool,
                          isVideoEnabled: Bool,
                          cameraPosition: CameraPositionEntity?,
                          allowNonHostToAddParticipantsEnabled: Bool,
                          isMyselfAModerator: Bool) {
        cameraQuickActionView.isSelected = isVideoEnabled
        if let cameraPosition = cameraPosition {
            flipQuickActionView.disabled = false
            flipQuickActionView.isSelected = cameraPosition == .back
        }
        
        if isOneToOneMeeting {
            optionsStackView.arrangedSubviews.forEach({ $0.removeFromSuperview() })
            optionsStackViewHeightConstraint.constant = 0.0
        }
        
        isAllowNonHostToAddParticipantsEnabled = allowNonHostToAddParticipantsEnabled
        shouldHideHostControls = isOneToOneMeeting || !isMyselfAModerator
    }
}

extension MeetingFloatingPanelViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return shouldHideHostControls ? 0 : 1
        case 1:
            return callParticipants.count + 1
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: AllowNonHostToInviteTableViewCell.reuseIdentifier, for: indexPath) as? AllowNonHostToInviteTableViewCell else { return UITableViewCell() }
                cell.allowNonHostSwitchEnabled(isAllowNonHostToAddParticipantsEnabled)
                cell.switchToggleHandler = { [weak self] allowNonHostToAddParticipantsSwitch in
                    self?.viewModel.dispatch(.allowNonHostToAddParticipants(enabled: allowNonHostToAddParticipantsSwitch.isOn))
                }
                return cell
            default:
                return UITableViewCell()
            }
        case 1:
            switch indexPath.row {
            case 0:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: MeetingInviteParticipantTableViewCell.reuseIdentifier, for: indexPath) as? MeetingInviteParticipantTableViewCell else { return UITableViewCell() }
                cell.cellTappedHandler = { [weak self] in
                    self?.viewModel.dispatch(.inviteParticipants)
                }
                return cell
            default:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: MeetingParticipantTableViewCell.reuseIdentifier, for: indexPath) as? MeetingParticipantTableViewCell else { return UITableViewCell() }
                cell.viewModel = MeetingParticipantViewModel(
                    participant: callParticipants[indexPath.row - 1],
                    userImageUseCase: userImageUseCase,
                    accountUseCase: accountUseCase,
                    chatRoomUseCase: chatRoomUseCase,
                    chatRoomUserUseCase: chatRoomUserUseCase,
                    megaHandleUseCase: megaHandleUseCase
                ) { [weak self] participant, button in
                    guard let self = self else { return }
                    self.viewModel.dispatch(.onContextMenuTap(presenter: self, sender: button, participant: participant))
                }
                return cell
            }
            
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 1:
            guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: MeetingParticipantTableViewHeader.reuseIdentifier) as? MeetingParticipantTableViewHeader else { return UIView(frame: .zero) }
            header.titleLabel.text = Strings.Localizable.Meetings.Panel.participantsCount(callParticipants.count)
            header.actionButton.isHidden = true
            return header
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 1:
            return 24
        default:
            return 0
        }
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
        #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
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
    
    var topOffset: CGFloat {
        guard let rootVC = UIApplication.shared.keyWindow?.rootViewController else { return 0.0 }
        if (view.frame.height - rootVC.view.safeAreaInsets.top) < Constants.viewMaxHeight {
            return rootVC.view.safeAreaInsets.top
        } else {
            return (view.frame.height - Constants.viewMaxHeight)
        }
    }
}
