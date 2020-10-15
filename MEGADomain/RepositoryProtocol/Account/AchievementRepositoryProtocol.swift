import Foundation

protocol AchievementRepositoryProtocol {
    func checkIsAchievementsEnabled() -> Bool
    func getAchievementStorage(by type: AchievementTypeEntity, completion: @escaping (Result<Measurement<UnitDataStorage>, AchievementErrorEntity>) -> Void)
}
