import Combine
import MEGADomain
import MEGAL10n
import MEGAPresentation

enum ParticipantNoInWaitingRoomViewAction: ActionType {
    case onViewReady
    case admitButtonTapped
    case denyButtonTapped
}

final class ParticipantInWaitingRoomViewModel: ViewModelType, CommonParticipantViewModel {
    
    enum Command: CommandType, Equatable {
        case updateAvatarImage(image: UIImage)
        case updateName(name: String)
    }
    
    let participant: CallParticipantEntity
    var userImageUseCase: any UserImageUseCaseProtocol
    var chatRoomUseCase: any ChatRoomUseCaseProtocol
    var chatRoomUserUseCase: any ChatRoomUserUseCaseProtocol
    let megaHandleUseCase: any MEGAHandleUseCaseProtocol
    private let admitButtonTappedHandler: (CallParticipantEntity) -> Void
    private let denyButtonTappedHandler: (CallParticipantEntity) -> Void
    let admitButtonEnabled: Bool
    var subscriptions = Set<AnyCancellable>()
    var avatarRefetchTask: Task<Void, Never>?

    var invokeCommand: ((Command) -> Void)?
    var loadNameTask: Task<Void, Never>?
    
    init(participant: CallParticipantEntity,
         userImageUseCase: some UserImageUseCaseProtocol,
         chatRoomUseCase: some ChatRoomUseCaseProtocol,
         chatRoomUserUseCase: some ChatRoomUserUseCaseProtocol,
         megaHandleUseCase: some MEGAHandleUseCaseProtocol,
         admitButtonEnabled: Bool,
         admitButtonTappedHandler: @escaping (CallParticipantEntity) -> Void,
         denyButtonMenuTappedHandler: @escaping (CallParticipantEntity) -> Void
    ) {
        self.participant = participant
        self.userImageUseCase = userImageUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.chatRoomUserUseCase = chatRoomUserUseCase
        self.megaHandleUseCase = megaHandleUseCase
        self.admitButtonEnabled = admitButtonEnabled
        self.admitButtonTappedHandler = admitButtonTappedHandler
        self.denyButtonTappedHandler = denyButtonMenuTappedHandler
    }
    
    deinit {
        avatarRefetchTask?.cancel()
        loadNameTask?.cancel()
    }
    
    func dispatch(_ action: ParticipantNoInWaitingRoomViewAction) {
        switch action {
        case .onViewReady:
            loadNameTask = Task { @MainActor [weak self] in
                guard let self else { return }
                if let name = await fetchName() {
                    invokeCommand?(
                        .updateName(name: name)
                    )
                    if let image = await fetchUserAvatar(name: name) {
                        invokeCommand?(.updateAvatarImage(image: image))
                    }
                }
                    
                requestAvatarChange()
            }
        case .admitButtonTapped:
            admitButtonTappedHandler(participant)
        case .denyButtonTapped:
            denyButtonTappedHandler(participant)
        }
    }
    
    func updateAvatar(image: UIImage) {
        invokeCommand?(.updateAvatarImage(image: image))
    }
}
