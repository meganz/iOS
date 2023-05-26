import MEGADomain

public final class MockAppFirstLaunchUseCase: AppFirstLaunchUseCaseProcotol {
    var isFirstLaunch = true
    
    public init(isFirstLaunch: Bool = true) {
        self.isFirstLaunch = isFirstLaunch
    }
    
    public func isAppFirstLaunch() -> Bool {
        isFirstLaunch
    }
    
    public func markAppAsLaunched() {
        isFirstLaunch = false
    }
}
