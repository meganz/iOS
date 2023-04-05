import MEGADomain

extension MEGAUserVisibility {
    func toVisibilityEntity() -> UserEntity.VisibilityEntity {
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
    func toChangeTypeEntity() -> UserEntity.ChangeTypeEntity {
        UserEntity.ChangeTypeEntity(rawValue: rawValue)
    }
}

extension MEGAUser {
    func toUserEntity() -> UserEntity {
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

extension MEGAUserList {
    func toUserEntities() -> [UserEntity] {
        let count = size?.intValue ?? 0
        guard count > 0 else { return [] }
        return (0..<count).compactMap { user(at: $0)?.toUserEntity() }
    }
}

extension UserEntity {
    func toMEGAUser() -> MEGAUser? {
        MEGASdk.shared.contact(forEmail: email)
    }
}
