import MEGAAssets
import MEGADomain
import MEGAL10n
import SwiftUI

@MainActor
final public class AdsFreeViewModel: ObservableObject {
    private let purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol
    private let viewProPlanAction: (() -> Void)?
    
    @Published var lowestProPlan: PlanEntity = PlanEntity()
    
    public init(
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        viewProPlanAction: (() -> Void)? = nil
    ) {
        self.purchaseUseCase = purchaseUseCase
        self.viewProPlanAction = viewProPlanAction
    }
    
    func setUpLowestProPlan() async {
        lowestProPlan = await purchaseUseCase.lowestPlan()
    }
    
    func didTapViewProPlansButton() {
        viewProPlanAction?()
    }
}
