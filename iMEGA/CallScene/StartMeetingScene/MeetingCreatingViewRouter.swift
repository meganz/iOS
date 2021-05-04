import Foundation

class MeetingCreatingViewRouter: NSObject, MeetingCreatingViewRouting {
    private weak var baseViewController: UIViewController?
    private weak var viewControllerToPresent: UIViewController?
    
    @objc init(viewControllerToPresent: UIViewController) {
        self.viewControllerToPresent = viewControllerToPresent
    }
    
    func build() -> UIViewController {
        let vm = MeetingCreatingViewModel(router: self, meetingUseCase: MeetingCreatingUseCase(repository: MeetingCreatingRepository()))
        let vc = MeetingCreatingViewController(viewModel: vm)
        baseViewController = vc
        return vc
    }
    
    @objc func start() {
        guard let viewControllerToPresent = viewControllerToPresent else {
            return
        }
        let nav = UINavigationController(rootViewController: build())
        nav.modalPresentationStyle = .fullScreen
        viewControllerToPresent.present(nav, animated: true, completion: nil)
    }
    
    // MARK: - UI Actions
    func dismiss() {
        baseViewController?.dismiss(animated: true)
    }
    
    func goToMeetingRoom(chatRoom: ChatRoomEntity, call: CallEntity, isVideoEnabled: Bool) {
        guard let baseViewController = baseViewController else { return }
        MeetingContainerRouter(presenter: baseViewController, chatRoom: chatRoom, call: call, isVideoEnabled: isVideoEnabled).start()
    }
    
}
