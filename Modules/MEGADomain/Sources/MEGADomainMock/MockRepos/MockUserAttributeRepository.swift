import MEGADomain

public final class MockUserAttributeRepository: UserAttributeRepositoryProtocol {
    public var userAttributes: [UserAttributeEntity: String]
    
    public init(attributes: [UserAttributeEntity: String] = [:]) {
        self.userAttributes = attributes
    }
    
    public func updateUserAttribute(_ attribute: UserAttributeEntity, value: String) async throws {
        userAttributes[attribute] = value
    }
}
