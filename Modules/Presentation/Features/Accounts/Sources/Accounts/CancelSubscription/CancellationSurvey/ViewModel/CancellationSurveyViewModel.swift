import MEGAAnalyticsiOS
import MEGADomain
import MEGAPresentation
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
    @Published var showMinLimitOrEmptyOtherFieldError: Bool = false
    @Published var dismissKeyboard: Bool = false
    
    let otherReasonID = CancellationSurveyReason.otherReason.id
    let minimumTextRequired = 10
    let maximumTextRequired = 120
    private(set) var subscription: AccountSubscriptionEntity
    private let subscriptionsUseCase: any SubscriptionsUseCaseProtocol
    private let cancelAccountPlanRouter: any CancelAccountPlanRouting
    private let tracker: any AnalyticsTracking
    var submitSurveyTask: Task<Void, Never>?
    
    init(
        subscription: AccountSubscriptionEntity,
        subscriptionsUseCase: some SubscriptionsUseCaseProtocol,
        cancelAccountPlanRouter: some CancelAccountPlanRouting,
        tracker: some AnalyticsTracking = DIContainer.tracker
    ) {
        self.subscription = subscription
        self.subscriptionsUseCase = subscriptionsUseCase
        self.cancelAccountPlanRouter = cancelAccountPlanRouter
        self.tracker = tracker
    }
    
    deinit {
        submitSurveyTask?.cancel()
        submitSurveyTask = nil
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
    
    func trackViewOnAppear() {
        tracker.trackAnalyticsEvent(with: SubscriptionCancellationSurveyScreenEvent())
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
        tracker.trackAnalyticsEvent(with: SubscriptionCancellationSurveyCancelViewButtonEvent())
    }
    
    @MainActor
    func didTapDontCancelButton() {
        shouldDismiss = true
        cancelAccountPlanRouter.dismissCancellationFlow()
        tracker.trackAnalyticsEvent(with: SubscriptionCancellationSurveyDontCancelButtonEvent())
    }
    
    @MainActor
    func didTapCancelSubscriptionButton() {
        guard let selectedReason else {
            showNoReasonSelectedError = true
            return
        }

        if selectedReason.isOtherReason {
            guard !otherReasonText.isEmpty && 
                    otherReasonText.count >= minimumTextRequired else {
                showMinLimitOrEmptyOtherFieldError = true
                return
            }
            
            guard otherReasonText.count <= maximumTextRequired else { return }
            
            dismissKeyboard = true
        }
        
        tracker.trackAnalyticsEvent(with: SubscriptionCancellationSurveyCancelSubscriptionButtonEvent())
        
        submitSurveyTask = Task { [weak self] in
            guard let self else { return }
            
            cancelAccountPlanRouter.showAppleManageSubscriptions()
            
            try? await subscriptionsUseCase.cancelSubscriptions(
                reason: formattedReasonString,
                subscriptionId: subscription.id,
                canContact: allowToBeContacted
            )
        }
    }
}
