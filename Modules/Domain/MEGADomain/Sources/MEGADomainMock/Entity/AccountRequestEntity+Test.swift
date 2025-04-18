import MEGADomain

public extension AccountRequestEntity {
    init(
        type: RequestTypeEntity = .accountDetails,
        file: String? = nil,
        userAttribute: UserAttributeEntity? = nil,
        email: String? = nil,
        isTesting: Bool = true
    ) {
        self.init(
            type: type,
            file: file,
            userAttribute: userAttribute,
            email: email)
    }
}
