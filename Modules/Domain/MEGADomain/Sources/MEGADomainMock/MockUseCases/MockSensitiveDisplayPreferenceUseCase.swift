import MEGADomain
import MEGASwift

public struct MockSensitiveDisplayPreferenceUseCase: SensitiveDisplayPreferenceUseCaseProtocol {
    @Atomic public var excludeSensitives: Bool = false
    
    public init(excludeSensitives: Bool = false) {
        $excludeSensitives.mutate { $0 = excludeSensitives }
    }
    
    public func excludeSensitives() async -> Bool {
        excludeSensitives
    }
}
