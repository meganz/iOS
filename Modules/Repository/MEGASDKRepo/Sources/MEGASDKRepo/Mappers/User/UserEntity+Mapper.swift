import MEGADomain
import MEGASdk

extension MEGAUserVisibility {
    public func toVisibilityEntity() -> UserEntity.VisibilityEntity {
        switch self {
        case .unknown:
            return .unknown
        case .hidden:
            return .hidden
        case .visible:
            return .visible
        case .inactive:
            return.inactive
        case .blocked:
            return .blocked
        @unknown default:
            return .unknown
        }
    }
}

extension MEGAUserChangeType {
    public func toChangeTypeEntity() -> UserEntity.ChangeTypeEntity {
        UserEntity.ChangeTypeEntity(rawValue: rawValue)
    }
}

extension MEGAUser {
    public func toUserEntity() -> UserEntity {
        let changeSource: UserEntity.ChangeSource
        if isOwnChange == 0 {
            changeSource = .externalChange
        } else if isOwnChange > 0 {
            changeSource = .explicitRequest
        } else {
            changeSource = .implicitRequest
        }
        
        return UserEntity(email: email,
                          handle: handle,
                          visibility: visibility.toVisibilityEntity(),
                          changes: changes.toChangeTypeEntity(),
                          changeSource: changeSource,
                          addedDate: timestamp)
    }
}

extension [MEGAUser] {
    public func toUserEntities() -> [UserEntity] {
        map { $0.toUserEntity() }
    }
}

extension MEGAUserList {
    public func toUserEntities() -> [UserEntity] {
        guard size > 0 else { return [] }
        return (0..<size).compactMap { user(at: $0)?.toUserEntity() }
    }
}

extension UserEntity {
    public func toMEGAUser() -> MEGAUser? {
        MEGASdk.sharedSdk.contact(forEmail: email)
    }
}
