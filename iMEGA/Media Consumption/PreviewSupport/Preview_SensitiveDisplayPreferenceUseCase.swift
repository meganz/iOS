import MEGADomain

struct Preview_SensitiveDisplayPreferenceUseCase: SensitiveDisplayPreferenceUseCaseProtocol {
    func excludeSensitives() async -> Bool {
        false
    }
}
