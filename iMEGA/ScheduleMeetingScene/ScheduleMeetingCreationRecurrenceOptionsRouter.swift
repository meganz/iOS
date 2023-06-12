import MEGADomain
import SwiftUI
import Combine

final class ScheduleMeetingCreationRecurrenceOptionsRouter: ScheduleMeetingCreationRecurrenceOptionsRouting {
    private let presenter: UINavigationController

    @Published
    var rules: ScheduledMeetingRulesEntity
    
    let startDate: Date

    init(presenter: UINavigationController, rules: ScheduledMeetingRulesEntity, startDate: Date) {
        self.presenter = presenter
        self.rules = rules
        self.startDate = startDate
    }
    
    @discardableResult
    func start() -> ScheduleMeetingCreationRecurrenceOptionsViewModel {
        let viewModel = ScheduleMeetingCreationRecurrenceOptionsViewModel(router: self)
        
        viewModel
            .$rules
            .assign(to: &$rules)
        
        let view = ScheduleMeetingCreationRecurrenceOptionsView(viewModel: viewModel)
        presenter.pushViewController(UIHostingController(rootView: view), animated: true)
        return viewModel
    }
    
    func navigateToCustomOptionsScreen() {
        let scheduleMeetingCreationCustomOptionsRouter = ScheduleMeetingCreationCustomOptionsRouter(
            presenter: presenter,
            rules: rules,
            startDate: startDate
        )
        scheduleMeetingCreationCustomOptionsRouter
            .$rules
            .assign(to: &$rules)
        scheduleMeetingCreationCustomOptionsRouter.start()
    }
    
    func dismiss() {
        presenter.popViewController(animated: true)
    }
}
