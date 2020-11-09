@testable import MEGA

final class MockPreferenceUseCase: PreferenceUseCaseProtocol {
    var dict = [PreferenceKeyEntity: Any?]()
    
    subscript<T>(key: PreferenceKeyEntity) -> T? {
        get {
            dict[key] as? T
        }
        set(newValue) {
            dict[key] = newValue
        }
    }
}
