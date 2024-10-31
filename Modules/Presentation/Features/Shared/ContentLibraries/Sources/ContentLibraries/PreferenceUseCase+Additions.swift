import MEGADomain
import MEGARepo

extension PreferenceUseCase where T == PreferenceRepository {
    public static var `default`: PreferenceUseCase {
        PreferenceUseCase(repository: PreferenceRepository.newRepo)
    }
}
