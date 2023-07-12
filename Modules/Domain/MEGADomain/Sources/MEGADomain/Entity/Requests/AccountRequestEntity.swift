
public struct AccountRequestEntity {
    public var type: RequestTypeEntity
    public var file: String?
    public var userAttribute: UserAttributeEntity?
    public var email: String?
    public var accountDetails: AccountDetailsEntity?
    
    public init(type: RequestTypeEntity,
                file: String?,
                userAttribute: UserAttributeEntity?,
                email: String?,
                accountDetails: AccountDetailsEntity?) {
        self.type = type
        self.file = file
        self.userAttribute = userAttribute
        self.email = email
        self.accountDetails = accountDetails
    }
}

extension AccountRequestEntity: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
    }
}
