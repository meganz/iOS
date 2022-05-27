@testable import MEGA

final class MockPreferenceUseCase: PreferenceUseCaseProtocol {
    var dict: [PreferenceKeyEntity: Any]
    
    init(dict: [PreferenceKeyEntity: Any] = [:]) {
        self.dict = dict
    }
    
    subscript<T>(key: PreferenceKeyEntity) -> T? {
        get {
            dict[key] as? T
        }
        set(newValue) {
            dict[key] = newValue
        }
    }
}
