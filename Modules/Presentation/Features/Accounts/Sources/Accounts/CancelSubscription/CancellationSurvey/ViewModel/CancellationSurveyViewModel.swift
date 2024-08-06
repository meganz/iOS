import SwiftUI

final class CancellationSurveyViewModel: ObservableObject {
    @Published var shouldDismiss: Bool = false
    @Published var selectedReason: CancellationSurveyReason?
    @Published var cancellationSurveyReasonList: [CancellationSurveyReason] = []
    @Published var otherReasonText: String = ""
    @Published var focusedReason: CancellationSurveyReason?
    @Published var isOtherFieldFocused: Bool = false
    @Published var allowToBeContacted: Bool = false
    @Published var showNoReasonSelectedError: Bool = false
    
    let otherReasonID = CancellationSurveyReason.otherReason.id
    private var router: any CancellationSurveyRouting
    
    init(router: some CancellationSurveyRouting) {
        self.router = router
    }
    
    @MainActor
    func setupRandomizedReasonList() {
        let otherReasonItem = CancellationSurveyReason.eight
        let cancellationReasons = CancellationSurveyReason.allCases.filter({ $0 != otherReasonItem })
        
        var randomizedList = cancellationReasons.shuffled()
        randomizedList.append(otherReasonItem)
        
        cancellationSurveyReasonList = randomizedList
    }
    
    @MainActor
    func handleFieldFocusChange(reason: CancellationSurveyReason, isFocused: Bool) {
        focusedReason = isFocused ? reason : nil
    }
    
    @MainActor
    func selectReason(_ reason: CancellationSurveyReason) {
        selectedReason = reason
        
        guard showNoReasonSelectedError else { return }
        showNoReasonSelectedError = false
    }
    
    func isReasonSelected(_ reason: CancellationSurveyReason) -> Bool {
        selectedReason?.id == reason.id
    }
    
    func didTapCancelButton() {
        dismissView()
    }
    
    func didTapDontCancelButton() {
        dismissView()
    }
    
    func didTapCancelSubscriptionButton() {
        guard selectedReason != nil else {
            showNoReasonSelectedError = true
            return
        }

        router.showAppleManageSubscriptions()
    }
    
    private func dismissView() {
        Task { @MainActor in
            shouldDismiss = true
        }
    }
}
