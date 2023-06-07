import MEGADomain
import SwiftUI

final class ScheduleMeetingEndRecurrenceOptionsRouter {
    private let presenter: UINavigationController

    @Published
    var rules: ScheduledMeetingRulesEntity

    init(presenter: UINavigationController, rules: ScheduledMeetingRulesEntity) {
        self.presenter = presenter
        self.rules = rules
    }
    
    @discardableResult
    func start() -> ScheduleMeetingEndRecurrenceOptionsViewModel {
        let viewModel = ScheduleMeetingEndRecurrenceOptionsViewModel(router: self)
        
        viewModel
            .$rules
            .assign(to: &$rules)
        
        let view = ScheduleMeetingEndRecurrenceOptionsView(viewModel: viewModel)
        presenter.pushViewController(UIHostingController(rootView: view), animated: true)
        return viewModel
    }
}
