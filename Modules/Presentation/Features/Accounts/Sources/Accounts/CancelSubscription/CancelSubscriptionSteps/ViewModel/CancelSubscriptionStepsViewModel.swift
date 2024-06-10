import SwiftUI

final class CancelSubscriptionStepsViewModel: ObservableObject {
    private let cancelSubscriptionStepsHelper: CancelSubscriptionStepsHelperProtocol
    private let router: CancelSubscriptionStepsRouting
    
    @Published var title: String = ""
    @Published var message: String = ""
    @Published var sections: [StepSection] = []
        
    init(
        helper: CancelSubscriptionStepsHelperProtocol,
        router: CancelSubscriptionStepsRouting
    ) {
        self.cancelSubscriptionStepsHelper = helper
        self.router = router
    }
    
    @MainActor
    func setupStepList() {
        let cancellationData = cancelSubscriptionStepsHelper.loadCancellationData()
        title = cancellationData.title
        message = cancellationData.message
        sections = cancellationData.sections
    }
    
    func dismiss() {
        router.dismiss()
    }
}
