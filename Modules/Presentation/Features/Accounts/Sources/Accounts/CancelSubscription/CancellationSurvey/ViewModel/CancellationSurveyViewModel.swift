import MEGAAnalyticsiOS
import MEGADomain
import MEGAPresentation
import MEGARepo
import MEGASDKRepo
import SwiftUI

@MainActor
final class CancellationSurveyViewModel: ObservableObject {
    @Published var shouldDismiss: Bool = false
    @Published var selectedReasons: Set<CancellationSurveyReason> = []
    @Published var cancellationSurveyReasonList: [CancellationSurveyReason] = []
    @Published var showOtherField: Bool = false
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
    private let accountUseCase: any AccountUseCaseProtocol
    private let cancelAccountPlanRouter: any CancelAccountPlanRouting
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private let tracker: any AnalyticsTracking
    private let logger: ((String) -> Void)?
    var submitSurveyTask: Task<Void, Never>?
    
    // Single selection
    @Published var selectedReason: CancellationSurveyReason?
    
    init(
        subscription: AccountSubscriptionEntity,
        subscriptionsUseCase: some SubscriptionsUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        cancelAccountPlanRouter: some CancelAccountPlanRouting,
        tracker: some AnalyticsTracking = DIContainer.tracker,
        logger: ((String) -> Void)? = nil,
        featureFlagProvider: some FeatureFlagProviderProtocol
    ) {
        self.subscription = subscription
        self.subscriptionsUseCase = subscriptionsUseCase
        self.accountUseCase = accountUseCase
        self.cancelAccountPlanRouter = cancelAccountPlanRouter
        self.tracker = tracker
        self.logger = logger
        self.featureFlagProvider = featureFlagProvider
    }
    
    deinit {
        submitSurveyTask?.cancel()
        submitSurveyTask = nil
    }
    
    // MARK: - Setup
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
    
    var isMultipleSelectionEnabled: Bool {
        featureFlagProvider.isFeatureFlagEnabled(for: .multipleOptionsForCancellationSurvey)
    }
    
    // MARK: - Reason selection
    func updateSelectedReason(_ reason: CancellationSurveyReason) {
        showNoReasonSelectedError = false
        
        if isMultipleSelectionEnabled {
            if selectedReasons.contains(reason) {
                selectedReasons.remove(reason)
            } else {
                selectedReasons.insert(reason)
            }
            
            guard reason.isOtherReason else { return }
            showOtherField = selectedReasons.contains(reason)
        } else {
            selectedReason = reason
            showOtherField = reason.isOtherReason
            isOtherFieldFocused = false
        }
    }

    var formattedReasonString: String? {
        guard !isMultipleSelectionEnabled else { return "" }
        
        guard let selectedReason else { return nil }
        return selectedReason.isOtherReason ? otherReasonText : "\(selectedReason.id) - \(selectedReason.title)"
    }
    
    func isReasonSelected(_ reason: CancellationSurveyReason) -> Bool {
        guard isMultipleSelectionEnabled else {
            return selectedReason?.id == reason.id
        }
        
        return selectedReasons.contains(reason)
    }
    
    // MARK: - Button action
    func setAllowToBeContacted(_ isAllowed: Bool ) {
        allowToBeContacted = isAllowed
    }
    
    func didTapCancelButton() {
        shouldDismiss = true
        tracker.trackAnalyticsEvent(with: SubscriptionCancellationSurveyCancelViewButtonEvent())
    }
    
    func didTapDontCancelButton() {
        shouldDismiss = true
        cancelAccountPlanRouter.dismissCancellationFlow()
        tracker.trackAnalyticsEvent(with: SubscriptionCancellationSurveyDontCancelButtonEvent())
    }
    
    func didTapCancelSubscriptionButton() {
        guard validateSelectedReason() else { return }
        
        if isReasonSelected(CancellationSurveyReason.otherReason) {
            guard validateOtherReasonText() else { return }
            dismissKeyboard = true
        }
        
        trackCancelSubscriptionEvent()
        
        submitSurveyTask = Task { [weak self] in
            guard let self else { return }
            await handleSubscriptionCancellation()
        }
    }

    private func validateSelectedReason() -> Bool {
        if isMultipleSelectionEnabled {
            let selectedReasonsNotEmpty = selectedReasons.isNotEmpty
            showNoReasonSelectedError = !selectedReasonsNotEmpty
            return selectedReasonsNotEmpty
        } else {
            guard selectedReason != nil else {
                showNoReasonSelectedError = true
                return false
            }
            return true
        }
    }

    private func validateOtherReasonText() -> Bool {
        guard !otherReasonText.isEmpty && otherReasonText.count >= minimumTextRequired else {
            showMinLimitOrEmptyOtherFieldError = true
            return false
        }
        
        guard otherReasonText.count <= maximumTextRequired else {
            return false
        }
        
        return true
    }

    private func trackCancelSubscriptionEvent() {
        tracker.trackAnalyticsEvent(with: SubscriptionCancellationSurveyCancelSubscriptionButtonEvent())
    }

    private func handleSubscriptionCancellation() async {
        do {
            try await subscriptionsUseCase.cancelSubscriptions(
                reason: formattedReasonString,
                subscriptionId: subscription.id,
                canContact: allowToBeContacted
            )
            
            switch subscription.paymentMethodId {
            case .itunes:
                cancelAccountPlanRouter.showAppleManageSubscriptions()
            default:
                guard let currentPlanExpirationDate = accountUseCase.currentProPlan?.expirationTime else { return }
                cancelAccountPlanRouter.showAlert(.success(Date(timeIntervalSince1970: TimeInterval(currentPlanExpirationDate))))
            }
        } catch {
            logger?("[Cancellation Survey] Error - \(error.localizedDescription)")
            cancelAccountPlanRouter.showAlert(.failure(error))
        }
    }
}
