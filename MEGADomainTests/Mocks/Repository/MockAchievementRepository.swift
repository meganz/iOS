import Foundation
@testable import MEGA

struct MockAchievementRepository: AchievementRepositoryProtocol {
    var isAchievementsEnabled = true
    var storageResult: Result<Measurement<UnitDataStorage>, AchievementErrorEntity> = .failure(.generic)
    
    func checkIsAchievementsEnabled() -> Bool {
        isAchievementsEnabled
    }
    
    func getAchievementStorage(by type: AchievementTypeEntity, completion: @escaping (Result<Measurement<UnitDataStorage>, AchievementErrorEntity>) -> Void) {
        completion(storageResult)
    }
}
