import MEGADomain
import MEGASDKRepo
import SwiftUI

final class CancellationSurveyViewModel: ObservableObject {
    @Published var shouldDismiss: Bool = false
    @Published var selectedReason: CancellationSurveyReason?
    @Published var cancellationSurveyReasonList: [CancellationSurveyReason] = []
    @Published var otherReasonText: String = ""
    @Published var isOtherFieldFocused: Bool = false
    @Published var allowToBeContacted: Bool = false
    @Published var showNoReasonSelectedError: Bool = false
    
    let otherReasonID = CancellationSurveyReason.otherReason.id
    let minimumTextRequired = 10
    let maximumTextRequired = 120
    private(set) var subscription: AccountSubscriptionEntity
    private let subscriptionsUsecase: any SubscriptionsUsecaseProtocol
    private let cancelAccountPlanRouter: any CancelAccountPlanRouting
    var submitReasonTask: Task<Void, Never>?
    
    init(
        subscription: AccountSubscriptionEntity,
        subscriptionsUsecase: some SubscriptionsUsecaseProtocol,
        cancelAccountPlanRouter: some CancelAccountPlanRouting
    ) {
        self.subscription = subscription
        self.subscriptionsUsecase = subscriptionsUsecase
        self.cancelAccountPlanRouter = cancelAccountPlanRouter
    }
    
    deinit {
        submitReasonTask?.cancel()
        submitReasonTask = nil
    }
    
    // MARK: - Setup
    @MainActor
    func setupRandomizedReasonList() {
        let otherReasonItem = CancellationSurveyReason.eight
        let cancellationReasons = CancellationSurveyReason.allCases.filter({ $0 != otherReasonItem })
        
        var randomizedList = cancellationReasons.shuffled()
        randomizedList.append(otherReasonItem)
        
        cancellationSurveyReasonList = randomizedList
    }
    
    // MARK: - Reason selection
    @MainActor
    func selectReason(_ reason: CancellationSurveyReason) {
        selectedReason = reason
        isOtherFieldFocused = false
        showNoReasonSelectedError = false
    }
    
    var formattedReasonString: String? {
        guard let selectedReason else { return nil }
        return selectedReason.isOtherReason ? otherReasonText : "\(selectedReason.id) - \(selectedReason.title)"
    }
    
    func isReasonSelected(_ reason: CancellationSurveyReason) -> Bool {
        selectedReason?.id == reason.id
    }
    
    // MARK: - Button action
    @MainActor
    func didTapCancelButton() {
        shouldDismiss = true
    }
    
    @MainActor
    func didTapDontCancelButton() {
        shouldDismiss = true
        cancelAccountPlanRouter.dismissCancellationFlow()
    }
    
    @MainActor
    func didTapCancelSubscriptionButton() {
        guard let selectedReason else {
            showNoReasonSelectedError = true
            return
        }

        if selectedReason.isOtherReason,
           otherReasonText.isEmpty {
            isOtherFieldFocused = true
            return
        }

        isOtherFieldFocused = false
        
        submitReasonTask = Task { [weak self] in
            guard let self else { return }
            try? await subscriptionsUsecase.cancelSubscriptions(
                reason: formattedReasonString,
                subscriptionId: subscription.id,
                canContact: allowToBeContacted
            )
            cancelAccountPlanRouter.showAppleManageSubscriptions()
        }
    }
}
