import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADomain
import MEGAL10n
import SwiftUI

@MainActor
final public class AdsFreeViewModel: ObservableObject {
    private let purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol
    private let viewProPlanAction: (() -> Void)?
    private let tracker: any AnalyticsTracking
    
    @Published var lowestProPlan: PlanEntity = PlanEntity()
    
    public init(
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        tracker: some AnalyticsTracking = DIContainer.tracker,
        viewProPlanAction: (() -> Void)? = nil
    ) {
        self.purchaseUseCase = purchaseUseCase
        self.tracker = tracker
        self.viewProPlanAction = viewProPlanAction
    }
    
    func setUpLowestProPlan() async {
        lowestProPlan = await purchaseUseCase.lowestPlan()
    }
    
    func onAppear() {
        tracker.trackAnalyticsEvent(with: AdFreeDialogScreenEvent())
    }
    
    func didTapViewProPlansButton() {
        viewProPlanAction?()
        
        tracker.trackAnalyticsEvent(with: AdFreeDialogScreenViewProPlansButtonPressedEvent())
    }
    
    func didTapSkipButton() {
        tracker.trackAnalyticsEvent(with: AdFreeDialogScreenSkipButtonPressedEvent())
    }
}
