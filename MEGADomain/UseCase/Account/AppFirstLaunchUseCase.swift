import Foundation

protocol AppFirstLaunchUseCaseProcotol {
    func isAppFirstLaunch() -> Bool
    func markAppAsLaunched()
}

struct AppFirstLaunchUseCase<T: PreferenceUseCaseProtocol>: AppFirstLaunchUseCaseProcotol {
    @PreferenceWrapper(key: .firstRun, defaultValue: "", useCase: PreferenceUseCase.group)
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
