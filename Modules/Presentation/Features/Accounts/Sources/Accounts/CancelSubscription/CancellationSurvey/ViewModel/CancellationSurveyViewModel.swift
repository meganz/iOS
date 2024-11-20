import MEGAAnalyticsiOS
import MEGADomain
import MEGAPresentation
import MEGARepo
import MEGASDKRepo
import SwiftUI

@MainActor
final class CancellationSurveyViewModel: ObservableObject {
    enum SurveyFormError: Error, Equatable {
        case noSelectedReason, noSelectedFollowUpReason(CancellationSurveyReason), none
    }
    
    @Published var shouldDismiss: Bool = false
    @Published var selectedReasons: Set<CancellationSurveyReason> = []
    @Published var selectedFollowUpReasons: Set<CancellationSurveyFollowUpReason> = []
    @Published var showOtherField: Bool = false
    @Published var otherReasonText: String = ""
    @Published var isOtherFieldFocused: Bool = false
    @Published var allowToBeContacted: Bool = false
    @Published var showMinLimitOrEmptyOtherFieldError: Bool = false
    @Published var dismissKeyboard: Bool = false
    @Published var surveyFormError: SurveyFormError = .none
    
    let otherReasonID = CancellationSurveyReason.otherReasonID
    let minimumTextRequired = 10
    let maximumTextRequired = 120
    private(set) var cancellationSurveyReasonList: [CancellationSurveyReason] = []
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
        cancellationSurveyReasonList: [CancellationSurveyReason] = CancellationSurveyReason.makeList(),
        subscription: AccountSubscriptionEntity,
        subscriptionsUseCase: some SubscriptionsUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        cancelAccountPlanRouter: some CancelAccountPlanRouting,
        tracker: some AnalyticsTracking = DIContainer.tracker,
        logger: ((String) -> Void)? = nil,
        featureFlagProvider: some FeatureFlagProviderProtocol
    ) {
        self.cancellationSurveyReasonList = cancellationSurveyReasonList
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
    var isMultipleSelectionEnabled: Bool {
        featureFlagProvider.isFeatureFlagEnabled(for: .multipleOptionsForCancellationSurvey)
    }
    
    var isFollowUpOptionEnabled: Bool {
        featureFlagProvider.isFeatureFlagEnabled(for: .followUpOptionsForCancellationSurvey)
    }
    
    // MARK: - Reason selection
    func updateSelectedReason(_ reason: CancellationSurveyReason) {
        surveyFormError = .none
        
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
    
    var isOtherReasonSelected: Bool {
        guard isMultipleSelectionEnabled else {
            return selectedReason?.id == otherReasonID
        }
        
        return selectedReasons.contains { $0.isOtherReason }
    }
    
    // MARK: - Follow-up reason selection
    func updateSelectedFollowUpReason(_ reason: CancellationSurveyFollowUpReason) {
        guard selectedFollowUpReasons.notContains(reason) else { return }
        
        if let currentSelection = selectedFollowUpReasons.first(where: { $0.mainReasonID == reason.mainReasonID }) {
            selectedFollowUpReasons.remove(currentSelection)
        }
        
        selectedFollowUpReasons.insert(reason)
        surveyFormError = .none
    }
    
    func isFollowUpReasonSelected(_ reason: CancellationSurveyFollowUpReason) -> Bool {
        selectedFollowUpReasons.contains(reason)
    }
    
    func followUpReasons(_ reason: CancellationSurveyReason) -> [CancellationSurveyFollowUpReason]? {
        guard isFollowUpOptionEnabled, reason.followUpReasons.isNotEmpty else { return nil }
        return reason.followUpReasons
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
        do {
            try validateSelectedReason()
            
            surveyFormError = .none
            
            if isOtherReasonSelected {
                guard validateOtherReasonText() else { return }
                dismissKeyboard = true
            }
            
            trackCancelSubscriptionEvent()
            
            submitSurveyTask = Task { [weak self] in
                guard let self else { return }
                await handleSubscriptionCancellation()
            }
        } catch let error as SurveyFormError {
            surveyFormError = error
        } catch {
            fatalError("Unexpected error: \(error)")
        }
    }

    // MARK: - Survey form validation and action
    private func validateSelectedReason() throws {
        if isMultipleSelectionEnabled {
            guard selectedReasons.isEmpty else { return }
            throw SurveyFormError.noSelectedReason
        } else {
            guard let selectedReason else {
                throw SurveyFormError.noSelectedReason
            }
            
            guard isFollowUpOptionEnabled,
                  selectedReason.followUpReasons.isNotEmpty,
                  selectedFollowUpReasons.notContains(where: { $0.mainReasonID == selectedReason.id }) else {
                return
            }
            
            throw SurveyFormError.noSelectedFollowUpReason(selectedReason)
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
    
    // MARK: - Analytics events
    
    func trackViewOnAppear() {
        tracker.trackAnalyticsEvent(with: SubscriptionCancellationSurveyScreenEvent())
    }
    
    private func trackCancelSubscriptionEvent() {
        tracker.trackAnalyticsEvent(with: SubscriptionCancellationSurveyCancelSubscriptionButtonEvent())
    }
}
