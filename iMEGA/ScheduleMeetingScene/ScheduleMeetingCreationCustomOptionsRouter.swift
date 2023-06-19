import SwiftUI
import MEGADomain
import Combine

final class ScheduleMeetingCreationCustomOptionsRouter: ScheduleMeetingCreationCustomOptionsRouting {
    private let presenter: UINavigationController
    @Published
    var rules: ScheduledMeetingRulesEntity
    private let startDate: Date

    init(presenter: UINavigationController, rules: ScheduledMeetingRulesEntity, startDate: Date) {
        self.presenter = presenter
        self.rules = rules
        self.startDate = startDate
    }
    
    func start() {
        let viewModel = ScheduleMeetingCreationCustomOptionsViewModel(router: self, rules: rules, startDate: startDate)
        let view = ScheduleMeetingCreationCustomOptionsView(viewModel: viewModel)
        presenter.navigationBar.topItem?.backButtonDisplayMode = .minimal
        presenter.pushViewController(UIHostingController(rootView: view), animated: true)
        
        viewModel
            .$rules
            .assign(to: &$rules)
    }
}
