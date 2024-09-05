import Foundation
import MEGAFoundation

public protocol AchievementRepositoryProtocol: RepositoryProtocol, Sendable {
    func checkIsAchievementsEnabled() -> Bool
    func getAchievementStorage(by type: AchievementTypeEntity) async throws -> Measurement<UnitDataStorage>
    func baseStorage() async throws -> Int64
    func getAchievementDetails() async throws -> AchievementDetailsEntity
}
