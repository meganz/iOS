
import Foundation

final class MeetingParticipantsLayoutViewController: UIViewController, ViewType {
    
    @IBOutlet private weak var callCollectionView: CallCollectionView!
    @IBOutlet private weak var localUserView: LocalUserView!
    
    @IBOutlet private weak var speakerAvatarImageView: UIImageView!
    @IBOutlet private weak var speakerRemoteVideoImageView: UIImageView!
    @IBOutlet private weak var speakerMutedImageView: UIImageView!
    @IBOutlet private weak var speakerNameLabel: UILabel!
    @IBOutlet private var speakerViews: Array<UIView>!
    @IBOutlet private weak var pageControl: UIPageControl!
    @IBOutlet private weak var stackViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var stackViewTopConstraint: NSLayoutConstraint!
    
    private var reconncectingNotificationView: CallNotificationView?
    private var meetingCompatibilityWarning: MeetingCompatibilityWarning?
    private var appBecomeActiveObserver: NSObjectProtocol?

    // MARK: - Internal properties
    private let viewModel: MeetingParticipantsLayoutViewModel
    private var titleView: CallTitleView
    lazy private var layoutModeBarButton = UIBarButtonItem(image: Asset.Images.Chat.speakerView.image,
                                               style: .plain,
                                               target: self,
                                               action: #selector(MeetingParticipantsLayoutViewController.didTapLayoutModeButton))
    lazy private var optionsMenuButton = UIBarButtonItem(image: UIImage(named: "moreGrid"),
                                                     style: .plain,
                                                     target: self,
                                                     action: #selector(MeetingParticipantsLayoutViewController.didTapOptionsButton))
    
    private var statusBarHidden = false {
      didSet(newValue) {
        setNeedsStatusBarAppearanceUpdate()
      }
    }
    
    private var isUserAGuest: Bool?
    private var emptyMeetingMessageView: EmptyMeetingMessageView?
    
    init(viewModel: MeetingParticipantsLayoutViewModel) {
        self.viewModel = viewModel
        self.titleView = CallTitleView.instanceFromNib
        super.init(nibName: nil, bundle: nil)

        // When answering with device locked and opening MEGA from CallKit, onViewDidAppear is not called, so it is needed to notify viewModel about view had appeared.
        self.appBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.callCollectionView.layoutIfNeeded()
            self.viewModel.dispatch(.onViewReady)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stackViewTopConstraint.constant = UIApplication.shared.windows[0].safeAreaInsets.top
        stackViewBottomConstraint.constant = UIApplication.shared.windows[0].safeAreaInsets.bottom
        
        navigationController?.navigationBar.isTranslucent = true
        overrideUserInterfaceStyle = .dark
        
        viewModel.invokeCommand = { [weak self] in
            self?.executeCommand($0)
        }
        
        navigationItem.titleView = titleView
        
        viewModel.dispatch(.onViewLoaded)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.dispatch(.onViewReady)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if UIDevice.current.iPhoneDevice {
            if UIDevice.current.orientation.isLandscape {
                viewModel.dispatch(.switchIphoneOrientation(.landscape))
            } else {
                viewModel.dispatch(.switchIphoneOrientation(.portrait))
            }
        }
        coordinator.animate(alongsideTransition: { _ in
            self.callCollectionView.collectionViewLayout.invalidateLayout()
            self.localUserView.repositionView()
            self.emptyMeetingMessageView?.invalidateIntrinsicContentSize()
        })
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            forceDarkNavigationUI()
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        statusBarHidden
    }
    
    // MARK: - Execute command
    func executeCommand(_ command: MeetingParticipantsLayoutViewModel.Command) {
        switch command {
        case .configView(let title, let subtitle, let isUserAGuest, let isOneToOne):
            self.isUserAGuest = isUserAGuest
            configureNavigationBar(title, subtitle)
            callCollectionView.configure(with: self)
            if isOneToOne {
                navigationItem.rightBarButtonItems = nil
            }
            let bottomPadding = MeetingFloatingPanelViewController.Constants.viewShortFormHeight + 16.0
            meetingCompatibilityWarning = MeetingCompatibilityWarning(inView: view, bottomPadding: bottomPadding) { [weak self] in
                self?.removeMeetingCompatibilityWarning()
            }
        case .configLocalUserView(let position):
            localUserView.configure(for: position)
        case .switchMenusVisibility:
            statusBarHidden.toggle()
            navigationController?.setNavigationBarHidden(!(navigationController?.navigationBar.isHidden ?? false), animated: true)
            localUserView.updateOffsetWithNavigation(hidden: statusBarHidden)
            forceDarkNavigationUI()
        case .enableLayoutButton(let enabled):
            layoutModeBarButton.isEnabled = enabled
        case .switchLayoutMode(let layoutMode, let participantsCount):
            configureLayout(mode: layoutMode, participantsCount: participantsCount)
        case .switchLocalVideo:
            localUserView.switchVideo()
        case .updateName(let name):
            titleView.configure(title: name, subtitle: nil)
        case .updateDuration(let duration):
            titleView.configure(title: nil, subtitle: duration)
        case .updatePageControl(let count):
            updateNumberOfPageControl(for: count)
        case .insertParticipant(let participants):
            callCollectionView.addedParticipant(in: participants)
        case .deleteParticipantAt(let index, let participants):
            callCollectionView.deletedParticipant(in: participants, at: index)
        case .reloadParticipantAt(let index, let participants):
            callCollectionView.reloadParticipant(in: participants, at: index)
        case .updateSpeakerViewFor(let participant):
            updateSpeaker(participant)
        case .localVideoFrame(let width, let height, let buffer):
            localUserView.frameData(width: width, height: height, buffer: buffer)
        case .participantAdded(let name):
            showNotification(message: Strings.Localizable.Meetings.Message.joinedCall(name), color: UIColor.mnz_turquoise(for: traitCollection))
        case .participantRemoved(let name):
            showNotification(message: Strings.Localizable.Meetings.Message.leftCall(name), color: UIColor.mnz_turquoise(for: traitCollection))
        case .reconnecting:
            showReconnectingNotification()
        case .reconnected:
            removeReconnectingNotification()
            showNotification(message: Strings.Localizable.online, color: UIColor.systemGreen)
        case .updateCameraPositionTo(let position):
            localUserView.addBlurEffect()
            localUserView.transformLocalVideo(for: position)
        case .updatedCameraPosition:
            localUserView.removeBlurEffect()
        case .showRenameAlert(let title, let isMeeting):
            showRenameAlert(title: title, isMeeting: isMeeting)
        case .enableRenameButton(let enabled):
            guard let renameAlertController = presentedViewController as? UIAlertController, let enableButton = renameAlertController.actions.last else {
                return
            }
            enableButton.isEnabled = enabled
        case .showNoOneElseHereMessage:
            showNoOneElseHereMessageView()
        case .showWaitingForOthersMessage:
            showWaitingForOthersMessageView()
        case .hideEmptyRoomMessage:
            removeEmptyRoomMessageView()
        case .startCompatibilityWarningViewTimer:
            meetingCompatibilityWarning?.startCompatibilityWarningViewTimer()
        case .removeCompatibilityWarningView:
            removeMeetingCompatibilityWarning()
        case .updateHasLocalAudio(let audio):
            localUserView.localAudio(enabled: audio)
        case .selectPinnedCellAt(let indexPath):
            callCollectionView.configurePinnedCell(at: indexPath)
        case .shouldHideSpeakerView(let hidden):
            speakerViews.forEach { $0.isHidden = hidden }
        case .ownPrivilegeChangedToModerator:
            showNotification(message: Strings.Localizable.Meetings.Notifications.moderatorPrivilege, color: UIColor.mnz_turquoise(for: traitCollection))
        case .lowNetworkQuality:
            showNotification(message: Strings.Localizable.poorConnection, color: UIColor.systemOrange)
        case .updateAvatar(let image, let participant):
            callCollectionView.updateAvatar(image: image, for: participant)
        case .updateSpeakerAvatar(let image):
            speakerAvatarImageView.image = image
        case .updateMyAvatar(let image):
            localUserView.updateAvatar(image: image)
        }
    }
    
    // MARK: - UI Actions
    @objc func didTapBackButton() {
        viewModel.dispatch(.tapOnBackButton)
    }

    @objc func didTapLayoutModeButton() {
        viewModel.dispatch(.tapOnLayoutModeButton)
    }
    
    @objc func didTapOptionsButton() {
        viewModel.dispatch(.tapOnOptionsMenuButton(presenter: navigationController ?? self, sender: optionsMenuButton))
    }
    
    @IBAction func didTapBagkgroundView(_ sender: UITapGestureRecognizer) {
        let yPosition = sender.location(in: callCollectionView).y
        viewModel.dispatch(.tapOnView(onParticipantsView: yPosition > 0 && yPosition < callCollectionView.frame.height))
    }
    
    //MARK: - Private
    
    private func configureLayout(mode: ParticipantsLayoutMode, participantsCount: Int) {
        switch mode {
        case .grid:
            layoutModeBarButton.image = Asset.Images.Chat.speakerView.image
        case .speaker:
            layoutModeBarButton.image = UIImage(named: "galleryView")
        }
        speakerViews.forEach { $0.isHidden = mode == .grid || participantsCount == 0 }
        pageControl.isHidden = mode == .speaker || participantsCount <= 6
        callCollectionView.changeLayoutMode(mode)
    }
    
    private func updateSpeaker(_ participant: CallParticipantEntity?) {
        guard let speaker = participant else {
            return
        }
        speaker.speakerVideoDataDelegate = self
        viewModel.dispatch(.fetchSpeakerAvatar)
        speakerRemoteVideoImageView.isHidden = speaker.video != .on
        speakerMutedImageView.isHidden = speaker.audio == .on
        speakerNameLabel.text = speaker.name
    }
    
    private func showNotification(message: String, color: UIColor) {
        let notification = CallNotificationView.instanceFromNib
        view.addSubview(notification)
        notification.show(message: message, backgroundColor: color, autoFadeOut: true)
    }
    
    private func updateNumberOfPageControl(for participantsCount: Int) {
        pageControl.numberOfPages = Int(ceil(Double(participantsCount) / 6.0))
        if pageControl.isHidden && participantsCount > 6 {
            pageControl.isHidden = false
        } else if !pageControl.isHidden && participantsCount <= 6 {
            pageControl.isHidden = true
        }
    }
    
    func showRenameAlert(title: String, isMeeting: Bool) {
        let actionTitle = isMeeting ? Strings.Localizable.Meetings.Action.rename : Strings.Localizable.renameGroup
        let renameAlertController = UIAlertController(title: actionTitle, message: Strings.Localizable.renameNodeMessage, preferredStyle: .alert)

        renameAlertController.addTextField { textField in
            textField.text = title
            textField.returnKeyType = .done
            textField.enablesReturnKeyAutomatically = true
            textField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
        }

        renameAlertController.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel, handler: { [weak self] _ in
            self?.viewModel.dispatch(.discardChangeTitle)
        }))
        renameAlertController.addAction(UIAlertAction(title: Strings.Localizable.rename, style: .default, handler: { [weak self] action in
            guard let newTitle = renameAlertController.textFields?.first?.text else {
                return
            }
            self?.viewModel.dispatch(.setNewTitle(newTitle))
        }))
        renameAlertController.actions.last?.isEnabled = false
        
        present(renameAlertController, animated: true, completion: nil)
    }

    @objc func textFieldDidChange(_ textField: UITextField) {
        guard let text = textField.text else {
            return
        }
        viewModel.dispatch(.renameTitleDidChange(text))
    }

    private func forceDarkNavigationUI() {
        guard let navigationBar = navigationController?.navigationBar else  { return }
        AppearanceManager.forceNavigationBarUpdate(navigationBar, traitCollection: traitCollection)
    }
    
    private func configureNavigationBar(_ title: String, _ subtitle: String) {
        titleView.configure(title: title, subtitle: subtitle)
        if !(isUserAGuest ?? false) {
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: Asset.Images.Chat.backArrow.image, style: .plain, target: self, action: #selector(self.didTapBackButton))
        }
        navigationItem.rightBarButtonItems = [optionsMenuButton,
                                              layoutModeBarButton]
        
        layoutModeBarButton.isEnabled = !(UIDevice.current.iPhoneDevice && UIDevice.current.orientation.isLandscape)
    }
    
    private func showReconnectingNotification() {
        let notification = CallNotificationView.instanceFromNib
        view.addSubview(notification)
        notification.show(message: Strings.Localizable.reconnecting, backgroundColor: UIColor.systemOrange, autoFadeOut: false)
        reconncectingNotificationView = notification
    }
    
    private func removeReconnectingNotification() {
        guard let notification = reconncectingNotificationView else { return }
        notification.removeFromSuperview()
        reconncectingNotificationView = nil
    }
    
    private func showWaitingForOthersMessageView() {
        let emptyMessage = EmptyMeetingMessageView.instanceFromNib
        emptyMessage.messageLabel.text = Strings.Localizable.Meetings.Message.waitingOthers
        view.addSubview(emptyMessage)
        emptyMessage.autoCenterInSuperview()
        emptyMeetingMessageView = emptyMessage
    }
    
    private func showNoOneElseHereMessageView() {
        let emptyMessage = EmptyMeetingMessageView.instanceFromNib
        emptyMessage.messageLabel.text = Strings.Localizable.Meetings.Message.noOtherParticipants
        view.addSubview(emptyMessage)
        emptyMessage.autoCenterInSuperview()
        emptyMeetingMessageView = emptyMessage
    }
    
    private func removeEmptyRoomMessageView() {
        emptyMeetingMessageView?.removeFromSuperview()
        emptyMeetingMessageView = nil
    }
        
    private func removeMeetingCompatibilityWarning() {
        meetingCompatibilityWarning?.stopCompatibilityWarningViewTimer()
        meetingCompatibilityWarning?.removeCompatibilityWarningView()
    }
}

extension MeetingParticipantsLayoutViewController: CallParticipantVideoDelegate {
    func frameData(width: Int, height: Int, buffer: Data!) {
        speakerRemoteVideoImageView.image = UIImage.mnz_convert(toUIImage: buffer, withWidth: width, withHeight: height)
    }
}

extension MeetingParticipantsLayoutViewController: CallCollectionViewDelegate {
    func collectionViewDidChangeOffset(to page: Int, visibleIndexPaths: [IndexPath]) {
        pageControl.currentPage = page
        viewModel.dispatch(.indexVisibleParticipants(visibleIndexPaths.map { $0.item }))
    }
    
    func collectionViewDidSelectParticipant(participant: CallParticipantEntity, at indexPath: IndexPath) {
        viewModel.dispatch(.tapParticipantToPinAsSpeaker(participant, indexPath))
    }
    
    func fetchAvatar(for participant: CallParticipantEntity) {
        viewModel.dispatch(.fetchAvatar(participant: participant))
    }
    
    func participantCellIsVisible(_ participant: CallParticipantEntity, at indexPath: IndexPath) {
        viewModel.dispatch(.particpantIsVisible(participant, index: indexPath.item))
    }
}

// MARK:- UIGestureRecognizerDelegate

extension MeetingParticipantsLayoutViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Avoid detecting the tap gesture when the compatibility popup is shown to the user.
        if meetingCompatibilityWarning?.meetingCompatibilityWarningView?.superview != nil {
            return false
        }
        return true
    }
}
