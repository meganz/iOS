import MEGADomain
import MEGASdk

public final class ABTestRepository: ABTestRepositoryProtocol {
    public static var newRepo: ABTestRepository {
        ABTestRepository(sdk: MEGASdk.sharedSdk)
    }
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func abTestValue(for flag: ABTestFlagName) async -> Int {
        sdk.getABTestValue(flag)
    }
}
