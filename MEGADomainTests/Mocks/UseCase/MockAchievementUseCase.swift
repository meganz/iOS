@testable import MEGA

struct MockAchievementUseCase: AchievementUseCaseProtocol {
    var result: Result<Measurement<UnitDataStorage>, AchievementErrorEntity> = .failure(.generic)
    var isAchievementsEnabled = true
    
    func checkIsAchievementsEnabled() -> Bool { isAchievementsEnabled }
    
    func getAchievementStorage(by type: AchievementTypeEntity, completion: @escaping (Result<Measurement<UnitDataStorage>, AchievementErrorEntity>) -> Void) {
        completion(result)
    }
}
