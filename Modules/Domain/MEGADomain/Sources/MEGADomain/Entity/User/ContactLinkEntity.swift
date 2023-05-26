
public struct ContactLinkEntity: Sendable {
    public let email: String?
    public let name: String?
    
    public init(email: String? = nil, name: String? = nil) {
        self.email = email
        self.name = name
    }
}
