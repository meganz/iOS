import Foundation
import MEGADomain
import MEGAFoundation

struct AchievementRepository: AchievementRepositoryProtocol {
    static var newRepo: AchievementRepository {
        AchievementRepository(sdk: MEGASdkManager.sharedMEGASdk())
    }
    
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func checkIsAchievementsEnabled() -> Bool {
        sdk.isAchievementsEnabled
    }
    
    func getAchievementStorage(by type: AchievementTypeEntity, completion: @escaping (Result<Measurement<UnitDataStorage>, AchievementErrorEntity>) -> Void) {
        getAchievementDetails {
            completion(
                $0.map { achievementDetails in
                    .bytes(of: achievementDetails.classStorage(forClassId: type.rawValue))
                }
                .mapError { _ in
                    AchievementErrorEntity.generic
                }
            )
        }
    }
    
    private func getAchievementDetails(completion: @escaping (Result<MEGAAchievementsDetails, MEGAError>) -> Void) {
        sdk.getAccountAchievements(with: MEGAGenericRequestDelegate { (request, error) in
            guard error.type == .apiOk else {
                completion(.failure(error))
                return
            }
            
            completion(.success(request.megaAchievementsDetails))
        })
    }
}
