import MEGADomain
import MEGASdk

public extension MEGAPricing {
    func productStorageGB(ofAccountType type: AccountTypeEntity) -> Int {
        guard products > .zero else { return 0 }
        
        for index in 0...products where proLevel(atProductIndex: index).toAccountTypeEntity() == type {
            return storageGB(atProductIndex: index)
        }
        return 0
    }
    
    /// Lists the available plans defined and returned by the SDK.
    ///
    /// - Note: There may be discrepancies between the plans defined in the SDK and the products defined in the Apple Store.
    /// Some plans may not be available for purchase from the Apple Store.
    ///
    /// - Returns: An array of `PlanEntity` representing the available SDK plans.
    /// 
    func availableSDKPlans() -> [PlanEntity] {
        (0..<products).compactMap(toPlanEntity)
    }
}
