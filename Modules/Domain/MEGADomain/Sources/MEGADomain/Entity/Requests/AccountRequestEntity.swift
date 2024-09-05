public struct AccountRequestEntity: Sendable {
    public var type: RequestTypeEntity
    public var file: String?
    public var userAttribute: UserAttributeEntity?
    public var email: String?
    
    public init(type: RequestTypeEntity,
                file: String?,
                userAttribute: UserAttributeEntity?,
                email: String?) {
        self.type = type
        self.file = file
        self.userAttribute = userAttribute
        self.email = email
    }
}

extension AccountRequestEntity: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
    }
}
