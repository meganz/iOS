import MEGADomain

public final class OnboardingUpgradeAccountViewModel {
    var lowestProPlan: AccountPlanEntity = AccountPlanEntity()
    private(set) var lowestProPlanStorage = ""
    private(set) var lowestProPlanStorageUnit = ""
    
    public func setUpLowestProPlan() {
        // Extract the memory and unit from the formatted storage string
        let storageComponents = lowestProPlan.storage.components(separatedBy: " ")
        guard storageComponents.count == 2 else { return }
        lowestProPlanStorage = storageComponents[0]
        lowestProPlanStorageUnit = storageComponents[1]
    }
}
