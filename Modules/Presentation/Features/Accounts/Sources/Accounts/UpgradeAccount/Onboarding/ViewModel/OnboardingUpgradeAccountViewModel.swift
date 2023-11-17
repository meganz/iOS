import Combine
import Foundation
import MEGAAnalyticsiOS
import MEGADomain
import MEGAL10n
import MEGAPresentation

public final class OnboardingUpgradeAccountViewModel: ObservableObject {
    private let purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol
    private let tracker: any AnalyticsTracking
    private let viewProPlanAction: () -> Void
    private var subscriptions: Set<AnyCancellable> = []
    
    @Published private(set) var shouldDismiss: Bool = false
    @Published private(set) var lowestProPlan: AccountPlanEntity = AccountPlanEntity()
    
    public init(
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        tracker: some AnalyticsTracking,
        viewProPlanAction: @escaping () -> Void
    ) {
        self.purchaseUseCase = purchaseUseCase
        self.tracker = tracker
        self.viewProPlanAction = viewProPlanAction
        
        setupSubscriptions()
    }
    
    func setupSubscriptions() {
        NotificationCenter.default
            .publisher(for: .dismissOnboardingProPlanDialog)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                shouldDismiss = true
            }
            .store(in: &subscriptions)
    }
    
    @MainActor
    public func setUpLowestProPlan() async {
        let planList = await self.purchaseUseCase.accountPlanProducts()
        
        guard let plan = planList.sorted(by: { $0.price < $1.price }).first else { return }
        lowestProPlan = plan
    }
    
    public var storageContentMessage: String {
        // Extract the memory and unit from the formatted storage string
        let storageComponents = lowestProPlan.storage.components(separatedBy: " ")
        guard storageComponents.count == 2 else { return ""}
        
        let message = Strings.Localizable.Onboarding.UpgradeAccount.Content.GenerousStorage.message
            .replacingOccurrences(of: "[A]", with: storageComponents[0]) // Storage limit
            .replacingOccurrences(of: "[B]", with: storageComponents[1]) // Storage unit
        return message
    }
    
    func showProPlanView() {
        tracker.trackAnalyticsEvent(with: OnboardingUpsellingDialogVariantAViewProPlansButtonEvent())
        
        viewProPlanAction()
    }
}
