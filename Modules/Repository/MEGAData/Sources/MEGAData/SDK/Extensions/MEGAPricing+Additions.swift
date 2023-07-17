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
}
