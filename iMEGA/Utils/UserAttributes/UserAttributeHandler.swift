import MEGADomain

struct UserAttributeHandler: Sendable {
    private let store: MEGAStore
    
    init(store: MEGAStore = MEGAStore.shareInstance()) {
        self.store = store
    }
    
    func handleUserAttribute(
        user: UserEntity?,
        email: String?,
        attributeType: UserAttributeEntity?,
        newValue: String
    ) {
        guard let attributeType else { return }
        
        if let user {
            let moUser = store.fetchUser(withUserHandle: user.handle)
            
            if let moUser {
                updateUser(
                    user.handle,
                    attributeType: attributeType,
                    newValue: newValue,
                    oldValue: oldValue(
                        for: moUser,
                        attributeType: attributeType
                    )
                )
            } else {
                insertUser(
                    user.handle,
                    attributeType: attributeType,
                    newValue: newValue
                )
            }
            
        } else if let email, !email.isEmpty {
            let moUser = store.fetchUser(withEmail: email)
            
            if let moUser {
                updateUser(
                    email: email,
                    attributeType: attributeType,
                    newValue: newValue,
                    oldValue: oldValue(
                        for: moUser,
                        attributeType: attributeType
                    )
                )
            } else {
                let userHandle = MEGASdk.handle(forBase64UserHandle: email)
                let moUser = store.fetchUser(withUserHandle: userHandle)
                
                if let moUser {
                    updateUser(
                        userHandle,
                        attributeType: attributeType,
                        newValue: newValue,
                        oldValue: oldValue(
                            for: moUser,
                            attributeType: attributeType
                        )
                    )
                } else {
                    insertUser(
                        userHandle,
                        attributeType: attributeType,
                        newValue: newValue
                    )
                }
            }
        } else if attributeType == .alias, let userHandle = user?.handle {
            store.updateUser(
                withUserHandle: userHandle,
                nickname: newValue
            )
        }
    }
    
    // MARK: - Private
    
    private func oldValue(
        for user: MOUser,
        attributeType: UserAttributeEntity
    ) -> String? {
        switch attributeType {
        case .firstName: user.firstname
        case .lastName: user.lastname
        default: nil
        }
    }
    
    private func updateUser(
        _ handle: HandleEntity,
        attributeType: UserAttributeEntity,
        newValue: String,
        oldValue: String?
    ) {
        switch attributeType {
        case .firstName where oldValue != newValue:
            store.updateUser(withUserHandle: handle, firstname: newValue)
        case .lastName where oldValue != newValue:
            store.updateUser(withUserHandle: handle, lastname: newValue)
        case .alias where oldValue != newValue:
            store.updateUser(withUserHandle: handle, nickname: newValue)
        default: break
        }
    }
    
    private func updateUser(
        email: String,
        attributeType: UserAttributeEntity,
        newValue: String,
        oldValue: String?
    ) {
        switch attributeType {
        case .firstName where oldValue != newValue:
            store.updateUser(withEmail: email, firstname: newValue)
        case .lastName where oldValue != newValue:
            store.updateUser(withEmail: email, lastname: newValue)
        case .alias where oldValue != newValue:
            store.updateUser(withEmail: email, nickname: newValue)
        default: break
        }
    }
    
    private func insertUser(
        _ handle: HandleEntity,
        attributeType: UserAttributeEntity,
        newValue: String
    ) {
        switch attributeType {
        case .firstName:
            store.insertUser(userHandle: handle, firstname: newValue)
        case .lastName:
            store.insertUser(userHandle: handle, lastname: newValue)
        case .alias:
            store.insertUser(userHandle: handle, nickname: newValue)
        default: break
        }
    }
}
