import Combine
import MEGADomain
import MEGAL10n
import MEGAPresentation

public final class OnboardingUpgradeAccountViewModel: ObservableObject {
    private let purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol
    private let viewProPlanAction: () -> Void
    
    @Published private(set) var lowestProPlan: AccountPlanEntity = AccountPlanEntity()
    
    public init(
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        viewProPlanAction: @escaping () -> Void
    ) {
        self.purchaseUseCase = purchaseUseCase
        self.viewProPlanAction = viewProPlanAction
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
        viewProPlanAction()
    }
}
