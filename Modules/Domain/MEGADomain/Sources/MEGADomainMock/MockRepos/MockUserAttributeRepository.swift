import MEGADomain

public final class MockUserAttributeRepository: UserAttributeRepositoryProtocol {
    public var userAttributes: [UserAttributeEntity: String]
    public var userAttributesContainer: [UserAttributeEntity: [String: String]]
    
    public init(attributes: [UserAttributeEntity: String] = [:],
                userAttributesContainer: [UserAttributeEntity: [String: String]] = [:]) {
        self.userAttributes = attributes
        self.userAttributesContainer = userAttributesContainer
    }
    
    public func updateUserAttribute(_ attribute: UserAttributeEntity, value: String) async throws {
        userAttributes[attribute] = value
    }
    
    public func updateUserAttribute(_ attribute: UserAttributeEntity, key: String, value: String) async throws {
        if userAttributesContainer[attribute] != nil {
            userAttributesContainer[attribute]?[key] = value
        } else {
            userAttributesContainer[attribute] = [key: value]
        }
    }
    
    public func userAttribute(for attribute: UserAttributeEntity) async throws -> [String: String]? {
        userAttributesContainer[attribute]
    }
}
