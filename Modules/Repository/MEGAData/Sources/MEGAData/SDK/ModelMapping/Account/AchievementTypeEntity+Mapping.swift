import MEGADomain
import MEGASdk

extension AchievementTypeEntity {
    private var identifier: Int {
        switch self {
        case .welcome: return 1
        case .invite: return 3
        case .desktopInstall: return 4
        case .mobileInstall: return 5
        case .addPhone: return 9
        }
    }
    
    public func toAchievementDetails(classStorage transform: (Int) -> Int64) -> AchievementDetailsClassStorage {
        .init(achievementType: self, storage: transform(identifier))
    }
    
    public func toAchievementDetails(classTransfer transform: (Int) -> Int64) -> AchievementDetailsClassTransfer {
        .init(achievementType: self, transfer: transform(identifier))
    }
    
    public func toAchievementDetails(classExpire transform: (Int) -> Int) -> AchievementDetailsClassExpire {
        .init(achievementType: self, expire: transform(identifier))
    }
}
