import Foundation
import MEGADomain

protocol AppFirstLaunchUseCaseProcotol {
    func isAppFirstLaunch() -> Bool
    func markAppAsLaunched()
}

struct AppFirstLaunchUseCase<T: PreferenceUseCaseProtocol>: AppFirstLaunchUseCaseProcotol {
    @PreferenceWrapper(key: .firstRun, defaultValue: "")
    private var firstRun: String
    
    init(preferenceUserCase: T) {
        $firstRun.useCase = preferenceUserCase
    }
    
    func isAppFirstLaunch() -> Bool {
        firstRun != MEGAFirstRunValue
    }
    
    func markAppAsLaunched() {
        firstRun = MEGAFirstRunValue
    }
}
