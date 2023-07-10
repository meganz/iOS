import MEGAAnalyticsDomain
import MEGASdk

public final class ViewIDRepository: ViewIDRepositoryProtocol {
    
    public static var newRepo: ViewIDRepository {
        ViewIDRepository(sdk: MEGASdk.sharedSdk)
    }
    
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func generateViewId() -> ViewID? {
        sdk.generateViewId()
    }
}
