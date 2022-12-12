import Foundation

public protocol AppFirstLaunchUseCaseProcotol {
    func isAppFirstLaunch() -> Bool
    func markAppAsLaunched()
}

public struct AppFirstLaunchUseCase<T: PreferenceUseCaseProtocol>: AppFirstLaunchUseCaseProcotol {
    @PreferenceWrapper(key: .firstRun, defaultValue: "")
    private var firstRun: String
    
    public init(preferenceUserCase: T) {
        $firstRun.useCase = preferenceUserCase
    }
    
    public func isAppFirstLaunch() -> Bool {
        firstRun != AppFirstLaunchEntity.firstLaunchPreferenceValue
    }
    
    public func markAppAsLaunched() {
        firstRun = AppFirstLaunchEntity.firstLaunchPreferenceValue
    }
}

private enum AppFirstLaunchEntity {
    static let firstLaunchPreferenceValue = "1strun"
}
