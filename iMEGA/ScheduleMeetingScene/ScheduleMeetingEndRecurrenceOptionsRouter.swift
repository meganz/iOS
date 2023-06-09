import MEGADomain
import SwiftUI

final class ScheduleMeetingEndRecurrenceOptionsRouter {
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
    func start() -> ScheduleMeetingEndRecurrenceOptionsViewModel {
        let viewModel = ScheduleMeetingEndRecurrenceOptionsViewModel(router: self, startDate: startDate)
        
        viewModel
            .$rules
            .assign(to: &$rules)
        
        let view = ScheduleMeetingEndRecurrenceOptionsView(viewModel: viewModel)
        presenter.pushViewController(UIHostingController(rootView: view), animated: true)
        return viewModel
    }
}
