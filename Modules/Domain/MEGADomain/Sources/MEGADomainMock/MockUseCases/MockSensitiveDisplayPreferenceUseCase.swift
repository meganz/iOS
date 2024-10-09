import MEGADomain

public struct MockSensitiveDisplayPreferenceUseCase: SensitiveDisplayPreferenceUseCaseProtocol {
    private let excludeSensitives: Bool
    
    public init(excludeSensitives: Bool = false) {
        self.excludeSensitives = excludeSensitives
    }
    
    public func excludeSensitives() async -> Bool {
        excludeSensitives
    }
}
