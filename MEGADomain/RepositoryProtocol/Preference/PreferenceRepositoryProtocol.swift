import Foundation

protocol PreferenceRepositoryProtocol {
    subscript<T>(key: String) -> T? { get set }
}
