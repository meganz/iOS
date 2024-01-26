public struct ContactLinkEntity: Sendable {
    public let email: String?
    public let name: String?
    public let userHandle: HandleEntity?
    
    public init(email: String? = nil, name: String? = nil, userHandle: HandleEntity? = nil) {
        self.email = email
        self.name = name
        self.userHandle = userHandle
    }
}
