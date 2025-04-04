import MEGADomain
import MEGASdk

extension MEGAIntegerList {
    public func toNotificationIDEntities() -> [NotificationIDEntity] {
        guard size > 0 else { return [] }
        return (0..<size).compactMap { NotificationIDEntity(integer(at: $0)) }
    }
}
