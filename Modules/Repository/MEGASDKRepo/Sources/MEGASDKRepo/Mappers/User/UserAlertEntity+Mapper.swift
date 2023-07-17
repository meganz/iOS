import MEGADomain
import MEGASdk

extension MEGAUserAlertList {
    public func toUserAlertEntities() -> [UserAlertEntity] {
        guard size > 0 else { return [] }
        return (0..<size).compactMap { usertAlert(at: $0)?.toUserAlertEntity() }
    }
}

extension MEGAUserAlert {
    public func toUserAlertEntity() -> UserAlertEntity {
        UserAlertEntity(alert: self)
    }
}

fileprivate extension UserAlertEntity {
    init(alert: MEGAUserAlert) {
        self.init(
            identifier: alert.identifier,
            isSeen: alert.isSeen,
            isRelevant: alert.isRelevant,
            alertType: alert.type.toUserAlertType(),
            alertTypeString: alert.typeString,
            userHandle: alert.userHandle,
            nodeHandle: alert.nodeHandle,
            email: alert.email,
            path: alert.path,
            name: alert.name,
            heading: alert.heading,
            title: alert.title,
            isOwnChange: alert.isOwnChange
        )
    }
}
