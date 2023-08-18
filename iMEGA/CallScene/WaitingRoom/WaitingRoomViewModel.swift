import MEGADomain
import MEGAPermissions
import MEGAPresentation

protocol WaitingRoomViewRouting: Routing {
    func dismiss()
    func showLeaveAlert(leaveAction: @escaping () -> Void)
}

final class WaitingRoomViewModel: ObservableObject {
    private let scheduledMeeting: ScheduledMeetingEntity
    private let router: any WaitingRoomViewRouting
    private let accountUseCase: any AccountUseCaseProtocol
    private let userImageUseCase: any UserImageUseCaseProtocol
    private let localVideoUseCase: any CallLocalVideoUseCaseProtocol
    private let audioSessionUseCase: any AudioSessionUseCaseProtocol
    private let permissionHandler: any DevicePermissionsHandling

    var meetingTitle: String { scheduledMeeting.title }
    var meetingDate: String { "Mon, 20 May ·10:00-11:00" }
    
    enum WaitingRoomViewState {
        case guestJoin
        case guestJoining
        case waitForHostToLetIn
    }
    @Published var viewState: WaitingRoomViewState
    
    @Published var isVideoEnabled = false
    @Published var isMicrophoneEnabled = true
    @Published var isSpeakerEnabled = false
    
    init(scheduledMeeting: ScheduledMeetingEntity,
         router: some WaitingRoomViewRouting,
         accountUseCase: some AccountUseCaseProtocol,
         userImageUseCase: some UserImageUseCaseProtocol,
         localVideoUseCase: some CallLocalVideoUseCaseProtocol,
         audioSessionUseCase: some AudioSessionUseCaseProtocol,
         permissionHandler: some DevicePermissionsHandling) {
        self.scheduledMeeting = scheduledMeeting
        self.router = router
        self.accountUseCase = accountUseCase
        self.userImageUseCase = userImageUseCase
        self.localVideoUseCase = localVideoUseCase
        self.audioSessionUseCase = audioSessionUseCase
        self.permissionHandler = permissionHandler
        viewState = accountUseCase.isGuest ? .guestJoin : .waitForHostToLetIn
    }
    
    func leaveButtonTapped() {
        router.showLeaveAlert { [weak self] in
            guard let self else { return }
            router.dismiss()
        }
    }
    
    func infoButtonTapped() {
        print(#function)
    }
    
    func tapJoinAction() {
        guard viewState == .guestJoin else { return }
        viewState = .guestJoining
    }
}
