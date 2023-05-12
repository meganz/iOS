import MEGADomain
import SwiftUI
import Combine

final class ScheduleMeetingCreationRecurrenceOptionsRouter {
    private let presenter: UINavigationController

    @Published
    var rules: ScheduledMeetingRulesEntity
    
    init(presenter: UINavigationController, rules: ScheduledMeetingRulesEntity) {
        self.presenter = presenter
        self.rules = rules
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
    
    func dismiss() {
        presenter.popViewController(animated: true)
    }
}
