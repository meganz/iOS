
import Foundation

class CallTitleView: UIStackView {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    
    override var intrinsicContentSize: CGSize {
       return UIView.layoutFittingExpandedSize
     }
    
    public func configure(title: String?, subtitle: String?) {
        if title != nil {
            titleLabel.text = title
        }
        if subtitle != nil {
            subtitleLabel.text = subtitle
        }
    }
}

class CallParticipantCell: UICollectionViewCell {
    @IBOutlet weak var videoImageView: MEGARemoteImageView!
    @IBOutlet weak var avatarImageView: UIImageView!
    
}

final class CallsViewController: UIViewController, ViewType {
    
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var titleView: CallTitleView!
    @IBOutlet private weak var localVideoImageView: MEGALocalImageView!


    //banner announcements
    //own avatar
    
    // MARK: - Internal properties
    var viewModel: CallViewModel!
    var callParticipants = [CallParticipantEntity]()

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.invokeCommand = { [weak self] in
            self?.executeCommand($0)
        }
        
        navigationItem.titleView = titleView

        viewModel.dispatch(.onViewReady)
    }
    
    // MARK: - Execute command
    func executeCommand(_ command: CallViewModel.Command) {
        switch command {
        case .configView(let title, let subtitle):
            titleView.configure(title: title, subtitle: subtitle)
            configureLocalVideoImage()
        case .switchMenusVisibility:
            navigationController?.setNavigationBarHidden(!(navigationController?.navigationBar.isHidden ?? false), animated: true)
        case .switchLayoutMode:
            break
        case .switchLocalVideo:
            localVideoImageView.isHidden = !localVideoImageView.isHidden
        case .updateName(let name):
            titleView.configure(title: name, subtitle: nil)
        case .updateDuration(let duration):
            titleView.configure(title: nil, subtitle: duration)
        case .showMenuOptions:
            break
        case .insertParticipant(let participants):
            callParticipants = participants
            collectionView.insertItems(at: [IndexPath(item: callParticipants.count - 1, section: 0)])
        case .deleteParticipantAt(let index, let participants):
            callParticipants = participants
            //TODO: remove video listener if exists before deleting cell
            collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
        case .updateParticipantAvFlagsAt(let index, let participants):
            callParticipants = participants
            collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
        }
    }
    
    // MARK: - UI Actions
    @IBAction func didTapBackButton() {
        viewModel.dispatch(.tapOnBackButton)
    }

    @IBAction func didTapLayoutModeButton() {
//        viewModel.dispatch(.tapOnLayoutModeButton)
        viewModel.dispatch(.switchLocalVideo(delegate: localVideoImageView))
    }
    
    @IBAction func didTapOptionsButton() {
        viewModel.dispatch(.tapOnOptionsButton)
    }
    
    @IBAction func didTapBackgroundView() {
        viewModel.dispatch(.tapOnView)
    }
    
    //MARK: - Private
    private func configureLocalVideoImage() {
        localVideoImageView.transform = CGAffineTransform(scaleX: -1, y: 1)
        localVideoImageView.layer.masksToBounds = true
        localVideoImageView.layer.cornerRadius = 4
        localVideoImageView.remoteVideoEnable(true)
        localVideoImageView.corner = .topRight
    }
}

extension CallsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return callParticipants.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CallParticipantCell", for: indexPath) as? CallParticipantCell else {
            fatalError("Error dequeueReusableCell CallParticipantCell")
        }
        let participant = callParticipants[indexPath.item]
        cell.avatarImageView.mnz_setImage(forUserHandle: participant.participantId, name: participant.name)
        
        if participant.video == .on {
            if cell.videoImageView.isHidden {
                cell.videoImageView.isHidden = false
                //Confirm that re adding remote video doesn't crash
                MEGASdkManager.sharedMEGAChatSdk().addChatRemoteVideo(participant.chatId, cliendId: participant.clientId, hiRes: false, delegate: cell.videoImageView)
                cell.avatarImageView.isHidden = true
            }
        } else {
            if cell.avatarImageView.isHidden {
                MEGASdkManager.sharedMEGAChatSdk().removeChatRemoteVideo(participant.chatId, cliendId: participant.clientId, hiRes: false, delegate: cell.videoImageView)
                cell.avatarImageView.isHidden = false
                cell.videoImageView.isHidden = true
            }
        }
        return cell
    }
}

// MARK: - Use case protocol -
protocol CallManagerUseCaseProtocol {
    func endCall(callId: MEGAHandle, chatId: MEGAHandle)
    func muteUnmuteCall(callId: MEGAHandle, chatId: MEGAHandle, muted: Bool)
    func addCall(_ call: MEGAChatCall)
    func startCall(_ call: MEGAChatCall)
}

// MARK: - Use case implementation -
struct CallManagerUseCase: CallManagerUseCaseProtocol {
    
    let megaCallManager: MEGACallManager

    init(megaCallManager: MEGACallManager = (UIApplication.shared.delegate as! AppDelegate).megaCallManager!) {
        self.megaCallManager = megaCallManager
    }

    func addCall(_ call: MEGAChatCall) {
        megaCallManager.add(call)
    }
    
    func startCall(_ call: MEGAChatCall) {
        megaCallManager.start(call)
    }
    
    func endCall(callId: MEGAHandle, chatId: MEGAHandle) {
        megaCallManager.endCall(withCallId: callId, chatId: chatId)
    }
    
    func muteUnmuteCall(callId: MEGAHandle, chatId: MEGAHandle, muted: Bool) {
        megaCallManager.muteUnmuteCall(withCallId: callId, chatId: chatId, muted: muted)
    }
}
