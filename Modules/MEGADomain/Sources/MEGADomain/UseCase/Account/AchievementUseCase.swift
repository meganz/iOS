import MEGAFoundation
import Foundation

// MARK: - Use case protocol -
public protocol AchievementUseCaseProtocol {
    func getAchievementStorage(by type: AchievementTypeEntity, completion: @escaping (Result<Measurement<UnitDataStorage>, AchievementErrorEntity>) -> Void)
}

public struct AchievementUseCase<T: AchievementRepositoryProtocol>: AchievementUseCaseProtocol {
    private let repo: T
    
    public init(repo: T) {
        self.repo = repo
    }
    
    public func getAchievementStorage(by type: AchievementTypeEntity, completion: @escaping (Result<Measurement<UnitDataStorage>, AchievementErrorEntity>) -> Void) {
        guard repo.checkIsAchievementsEnabled() else {
            completion(.failure(.achievementsDisabled))
            return
        }
        
        repo.getAchievementStorage(by: type, completion: completion)
    }
}
