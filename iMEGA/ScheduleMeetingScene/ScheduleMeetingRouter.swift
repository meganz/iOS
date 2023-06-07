import MEGADomain
import SwiftUI
import Combine

final class ScheduleMeetingRouter {
    private(set) var presenter: UINavigationController
    private(set) var baseViewController: UINavigationController?

    init(presenter: UINavigationController) {
        self.presenter = presenter
    }
    
    func build() -> UINavigationController {
        let viewModel = ScheduleMeetingViewModel(
            router: self,
            rules: ScheduledMeetingRulesEntity(frequency: .invalid),
            scheduledMeetingUseCase: ScheduledMeetingUseCase(repository: ScheduledMeetingRepository(chatSDK: MEGAChatSdk.shared)),
            chatLinkUseCase: ChatLinkUseCase(chatLinkRepository: ChatLinkRepository.newRepo),
            chatRoomUseCase: ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.sharedRepo)
        )

        let viewController = ScheduleMeetingViewController(viewModel: viewModel)
        let navigation = MEGANavigationController(rootViewController: viewController)
        
        baseViewController = navigation
        
        return navigation
    }
    
    func start() {
        presenter.present(build(), animated: true)
    }
}
    
extension ScheduleMeetingRouter: ScheduleMeetingRouting {
    func showSpinner() {
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show()
    }
    
    func hideSpinner() {
        SVProgressHUD.dismiss()
    }

    func discardChanges() {
        presenter.dismissView()
    }
    
    func showAddParticipants(alreadySelectedUsers: [UserEntity], newSelectedUsers: @escaping (([UserEntity]?) -> Void)) {
        let storyboard = UIStoryboard(name: "Contacts", bundle: nil)
        let contactsNavigationController = storyboard.instantiateViewController(withIdentifier: "ContactsNavigationControllerID") as! UINavigationController
        let contactController = contactsNavigationController.viewControllers.first as! ContactsViewController
        contactController.contactsMode = .scheduleMeeting
        contactController.chatOptionType = .meeting
        contactController.userSelected = { users in
            newSelectedUsers(users?.compactMap { $0.toUserEntity() })
        }
        
        baseViewController?.present(contactsNavigationController, animated: true) {
            contactController.selectUsers(alreadySelectedUsers.compactMap { $0.toMEGAUser() })
        }
    }
    
    func showMeetingInfo(for scheduledMeeting: ScheduledMeetingEntity) {
        SVProgressHUD.dismiss()
        presenter.dismiss(animated: true) {
            MeetingInfoRouter(presenter: self.presenter, scheduledMeeting: scheduledMeeting).start()
            SVProgressHUD.showSuccess(withStatus: Strings.Localizable.Meetings.ScheduleMeeting.meetingCreated)
        }
    }
    
    @MainActor
    func showRecurrenceOptionsView(rules: ScheduledMeetingRulesEntity, startDate: Date) -> AnyPublisher<ScheduledMeetingRulesEntity, Never>? {
        guard let baseViewController else { return nil }
        let router = ScheduleMeetingCreationRecurrenceOptionsRouter(presenter: baseViewController, rules: rules, startDate: startDate)
        router.start()
        return router.$rules.eraseToAnyPublisher()
    }
    
    @MainActor
    func showEndRecurrenceOptionsView(rules: ScheduledMeetingRulesEntity) -> AnyPublisher<ScheduledMeetingRulesEntity, Never>? {
        guard let baseViewController else { return nil }
        let router = ScheduleMeetingEndRecurrenceOptionsRouter(presenter: baseViewController, rules: rules)
        router.start()
        return router.$rules.eraseToAnyPublisher()
    }
}
 
