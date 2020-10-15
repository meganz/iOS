import Foundation

// MARK: - Use case protocol -
protocol AchievementUseCaseProtocol {
    func getAchievementStorage(by type: AchievementTypeEntity, completion: @escaping (Result<Measurement<UnitDataStorage>, AchievementErrorEntity>) -> Void)
}

struct AchievementUseCase: AchievementUseCaseProtocol {
    private let repo: AchievementRepositoryProtocol
    
    init(repo: AchievementRepositoryProtocol) {
        self.repo = repo
    }
    
    func getAchievementStorage(by type: AchievementTypeEntity, completion: @escaping (Result<Measurement<UnitDataStorage>, AchievementErrorEntity>) -> Void) {
        guard repo.checkIsAchievementsEnabled() else {
            completion(.failure(.achievementsDisabled))
            return
        }
        
        repo.getAchievementStorage(by: type, completion: completion)
    }
}
