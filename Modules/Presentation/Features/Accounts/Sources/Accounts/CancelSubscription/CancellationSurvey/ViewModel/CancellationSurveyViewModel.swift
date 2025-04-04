import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGARepo
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
        featureFlagProvider: some FeatureFlagProviderProtocol
    ) {
        self.cancellationSurveyReasonList = cancellationSurveyReasonList
        self.subscription = subscription
        self.subscriptionsUseCase = subscriptionsUseCase
        self.accountUseCase = accountUseCase
        self.cancelAccountPlanRouter = cancelAccountPlanRouter
        self.tracker = tracker
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
    
    func shouldShowFollowUpReasons(for reason: CancellationSurveyReason) -> Bool {
        isReasonSelected(reason) && reason.followUpReasons.isNotEmpty
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
            
            guard selectedReason.followUpReasons.isNotEmpty,
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
    
    private func reasonIndexPosition(_ reason: CancellationSurveyReason) -> String? {
        guard let index = cancellationSurveyReasonList.firstIndex(of: reason) else { return nil }
        return String(index + 1)
    }
    
    private func makeMainCancelSubscriptionReasonEntity(_ reason: CancellationSurveyReason) -> CancelSubscriptionReasonEntity? {
        guard let position = reasonIndexPosition(reason) else { return nil }
        
        let formattedReason = reason.isOtherReason ? "\(reason.id.rawValue) - \(otherReasonText)" : String(reason.id.rawValue)
        return CancelSubscriptionReasonEntity(text: formattedReason, position: position)
    }
    
    private func makeFollowUpCancelSubscriptionReasonEntity(from mainReason: CancellationSurveyReason, followUpReason: CancellationSurveyFollowUpReason) -> CancelSubscriptionReasonEntity? {
        guard let mainReasonIndex = reasonIndexPosition(mainReason),
              let selectedIndex = mainReason.followUpReasons.firstIndex(where: { $0.id == followUpReason.id }) else { return nil }
        
        let ids = CancellationSurveyFollowUpReason.ID.allCases.prefix(mainReason.followUpReasons.count)
        let newID = ids[selectedIndex]
        let position = "\(mainReasonIndex).\(newID.rawValue)"
        
        return CancelSubscriptionReasonEntity(text: followUpReason.formattedID, position: position)
    }
    
    private func followUpReasonSelectionList(
        from selectedMainReasons: [CancellationSurveyReason]
    ) -> (
        selectedFollowUpReasons: [CancelSubscriptionReasonEntity],
        mainReasonIDs: [CancellationSurveyReason.ID]
    ) {
        guard selectedFollowUpReasons.isNotEmpty, selectedMainReasons.isNotEmpty else { return ([], []) }

        let reasons = selectedFollowUpReasons.compactMap { followUpReason -> (CancelSubscriptionReasonEntity, CancellationSurveyReason.ID)? in
            guard let mainReason = selectedMainReasons.first(where: { $0.id == followUpReason.mainReasonID }),
                  let followUpReasonEntity = makeFollowUpCancelSubscriptionReasonEntity(from: mainReason, followUpReason: followUpReason) else {
                return nil
            }
            return (followUpReasonEntity, mainReason.id)
        }

        return (selectedFollowUpReasons: reasons.map(\.0), mainReasonIDs: reasons.map(\.1))
    }
    
    func cancelSubscriptionReasonSelectionList() -> [CancelSubscriptionReasonEntity] {
        guard selectedReason != nil || selectedReasons.isNotEmpty else { return [] }
        
        // Get main reasons
        var selectedMainReasons: [CancellationSurveyReason] = []
        if isMultipleSelectionEnabled {
            selectedMainReasons.append(contentsOf: selectedReasons)
        } else {
            guard let selectedReason else { return [] }
            selectedMainReasons = [selectedReason]
        }
        
        // Get the selected follow up reasons
        let (selectedFollowUpReasons, mainReasonIDs) = followUpReasonSelectionList(from: selectedMainReasons)
        
        // Remove followup reason's main reason on the list. Main reason should not be included if it has followup options.
        // Convert selected main reasons to entity
        let mainReasonList = selectedMainReasons
            .filter { !mainReasonIDs.contains($0.id) }
            .compactMap { makeMainCancelSubscriptionReasonEntity($0) }
        
        return mainReasonList + selectedFollowUpReasons
    }

    private func handleSubscriptionCancellation() async {
        do {
            try await subscriptionsUseCase.cancelSubscriptions(
                reasonList: cancelSubscriptionReasonSelectionList(),
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
            MEGALogError("[Cancellation Survey] - \(error.localizedDescription)")
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
