
import Foundation

final class MeetingParticipantsLayoutViewController: UIViewController, ViewType {
    
    @IBOutlet private weak var callsCollectionView: CallsCollectionView!
    @IBOutlet private weak var titleView: CallTitleView!
    @IBOutlet private weak var localUserView: LocalUserView!
    @IBOutlet weak var optionsMenuButton: UIBarButtonItem!
    
    @IBOutlet private weak var speakerAvatarImageView: UIImageView!
    @IBOutlet weak var speakerRemoteVideoImageView: UIImageView!
    @IBOutlet private var speakerViews: Array<UIView>!
    @IBOutlet weak var pageControl: UIPageControl!
    
    // MARK: - Internal properties
    var viewModel: MeetingParticipantsLayoutViewModel!

    private var statusBarHidden = false {
      didSet(newValue) {
        setNeedsStatusBarAppearanceUpdate()
      }
    }
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .dark
        }
        
        viewModel.invokeCommand = { [weak self] in
            self?.executeCommand($0)
        }
        
        navigationItem.titleView = titleView

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
            self.callsCollectionView.collectionViewLayout.invalidateLayout()
            self.localUserView.positionView(by: self.localUserView.center)
        })
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                forceDarkNavigationUI()
            }
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        statusBarHidden
    }
    
    // MARK: - Execute command
    func executeCommand(_ command: MeetingParticipantsLayoutViewModel.Command) {
        switch command {
        case .configView(let title, let subtitle, let isVideoEnabled):
            titleView.configure(title: title, subtitle: subtitle)
            callsCollectionView.configure(with: self)
            localUserView.configure()
            if isVideoEnabled {
                executeCommand(.switchLocalVideo)
            }
        case .switchMenusVisibility:
            statusBarHidden.toggle()
            navigationController?.setNavigationBarHidden(!(navigationController?.navigationBar.isHidden ?? false), animated: true)
            callsCollectionView.collectionViewLayout.invalidateLayout()
            localUserView.positionView(by: localUserView.center)
            forceDarkNavigationUI()
        case .toggleLayoutButton:
            titleView.toggleLayoutButton()
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
            callsCollectionView.addedParticipant(in: participants)
        case .deleteParticipantAt(let index, let participants):
            callsCollectionView.deletedParticipant(in: participants, at: index)
        case .updateParticipantAt(let index, let participants):
            callsCollectionView.updateParticipant(in: participants, at: index)
        case .updateSpeakerViewFor(let participant):
            updateSpeaker(participant)
        case .localVideoFrame(let width, let height, let buffer):
            localUserView.frameData(width: width, height: height, buffer: buffer)
        case .participantAdded(let name):
            showNotification(message: String(format: NSLocalizedString("%@ joined the call.", comment: "Message to inform the local user that someone has joined the current group call"), name), color: UIColor.mnz_turquoise(for: traitCollection))
        case .participantRemoved(let name):
            showNotification(message: String(format: NSLocalizedString("%@ left the call.", comment: "Message to inform the local user that someone has left the current group call"), name), color: UIColor.mnz_turquoise(for: traitCollection))
        case .reconnecting:
            showNotification(message: NSLocalizedString("Reconnecting...", comment: "Title shown when the user lost the connection in a call, and the app will try to reconnect the user again"), color: UIColor.systemOrange)
        case .reconnected:
            showNotification(message: NSLocalizedString("online", comment: ""), color: UIColor.systemGreen)
        case .updatedCameraPosition(let position):
            localUserView.transformLocalVideo(for: position)
            break
        case .showRenameAlert(let title):
            showRenameAlert(title: title)
        case .enableRenameButton(let enabled):
            guard let renameAlertController = presentedViewController as? UIAlertController, let enableButton = renameAlertController.actions.last else {
                return
            }
            enableButton.isEnabled = enabled
        }
    }
    
    // MARK: - UI Actions
    @IBAction func didTapBackButton() {
        viewModel.dispatch(.tapOnBackButton)
    }

    @IBAction func didTapLayoutModeButton() {
        viewModel.dispatch(.tapOnLayoutModeButton)
    }
    
    @IBAction func didTapOptionsButton() {
        viewModel.dispatch(.tapOnOptionsMenuButton(presenter: navigationController ?? self, sender: optionsMenuButton))
    }
    
    @IBAction func didTapBackgroundView() {
        viewModel.dispatch(.tapOnView)
    }
    
    //MARK: - Private
    
    private func configureLayout(mode: CallLayoutMode, participantsCount: Int) {
        titleView.switchLayoutMode(mode)
        speakerViews.forEach { $0.isHidden = mode == .grid }
        pageControl.isHidden = mode == .speaker
        callsCollectionView.changeLayoutMode(mode)
    }
    
    private func updateSpeaker(_ participant: CallParticipantEntity?) {
        guard let speaker = participant else {
            return
        }
        speaker.speakerVideoDataDelegate = self
        speakerAvatarImageView.mnz_setImage(forUserHandle: speaker.participantId, name: speaker.name)
        speakerRemoteVideoImageView.isHidden = speaker.video != .on
    }
    
    private func showNotification(message: String, color: UIColor) {
        let notification = CallNotificationView.instanceFromNib
        view.addSubview(notification)
        notification.show(message: message, backgroundColor: color)
    }
    
    private func updateNumberOfPageControl(for participantsCount: Int) {
        pageControl.numberOfPages = Int(ceil(Double(participantsCount) / 6.0))
        if pageControl.isHidden && participantsCount > 6 {
            pageControl.isHidden = false
            callsCollectionView.collectionViewLayout.invalidateLayout()
            callsCollectionView.layoutIfNeeded()
        } else if !pageControl.isHidden && participantsCount <= 6 {
            pageControl.isHidden = true
            callsCollectionView.collectionViewLayout.invalidateLayout()
            callsCollectionView.layoutIfNeeded()
        }
    }
    
    func showRenameAlert(title: String) {
        let renameAlertController = UIAlertController(title: NSLocalizedString("calls.options.rename", comment: ""), message: NSLocalizedString("renameNodeMessage", comment: "Hint text to suggest that the user have to write the new name for the file or folder"), preferredStyle: .alert)

        renameAlertController.addTextField { textField in
            textField.text = title
            textField.returnKeyType = .done
            textField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
        }

        renameAlertController.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: "Button title to cancel something"), style: .cancel, handler: { [weak self] _ in
            self?.viewModel?.dispatch(.discardChangeTitle)
        }))
        renameAlertController.addAction(UIAlertAction(title: NSLocalizedString("rename", comment: "Title for the action that allows you to rename a file or folder"), style: .default, handler: { [weak self] action in
            guard let newTitle = renameAlertController.textFields?.first?.text else {
                return
            }
            self?.viewModel?.dispatch(.setNewTitle(newTitle))
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
        if #available(iOS 13.0, *) {
            guard let navigationBar = navigationController?.navigationBar else  { return }
            AppearanceManager.forceNavigationBarUpdate(navigationBar, traitCollection: traitCollection)
        }
    }
}

// MARK: - Use case protocol -
protocol CallManagerUseCaseProtocol {
    func endCall(callId: MEGAHandle, chatId: MEGAHandle)
    func muteUnmuteCall(callId: MEGAHandle, chatId: MEGAHandle, muted: Bool)
    func addCall(_ call: CallEntity)
    func startCall(_ call: CallEntity)
}

// MARK: - Use case implementation -
struct CallManagerUseCase: CallManagerUseCaseProtocol {
    
    let megaCallManager: MEGACallManager

    init(megaCallManager: MEGACallManager = (UIApplication.shared.delegate as! AppDelegate).megaCallManager!) {
        self.megaCallManager = megaCallManager
    }

    func addCall(_ call: CallEntity) {
        megaCallManager.addCall(withCallId: call.callId, uuid: call.uuid)
    }
    
    func startCall(_ call: CallEntity) {
        megaCallManager.startCall(withChatId: call.chatId)
    }
    
    func endCall(callId: MEGAHandle, chatId: MEGAHandle) {
        megaCallManager.endCall(withCallId: callId, chatId: chatId)
    }
    
    func muteUnmuteCall(callId: MEGAHandle, chatId: MEGAHandle, muted: Bool) {
        megaCallManager.muteUnmuteCall(withCallId: callId, chatId: chatId, muted: muted)
    }
}

extension MeetingParticipantsLayoutViewController: CallParticipantVideoDelegate {
    func frameData(width: Int, height: Int, buffer: Data!) {
        speakerRemoteVideoImageView.image = UIImage.mnz_convert(toUIImage: buffer, withWidth: width, withHeight: height)
    }
}

extension MeetingParticipantsLayoutViewController: CallsCollectionViewScrollDelegate {
    func collectionViewDidChangeOffset(to page: Int) {
        pageControl.currentPage = page
    }
}
