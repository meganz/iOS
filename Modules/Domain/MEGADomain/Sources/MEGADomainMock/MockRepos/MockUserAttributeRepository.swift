import Foundation
import MEGADomain

public final class MockUserAttributeRepository: UserAttributeRepositoryProtocol, @unchecked Sendable {
    
    public var userAttributes: [UserAttributeEntity: String]
    public var userAttributesContainer: [UserAttributeEntity: [String: String]]
    public var mergeUserAttributes: [UserAttributeEntity: any Encodable] = [:]
    
    private let jsonDecoder = JSONDecoder()
    private let jsonEncoder = JSONEncoder()

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
    
    public func mergeUserAttribute<T: Encodable>(_ attribute: UserAttributeEntity, key: String, object: T) async throws {
        let jsonData = try jsonEncoder.encode(object)
        
        userAttributesContainer[attribute] = [key: String(decoding: jsonData, as: UTF8.self).base64Encoded ?? "Failed to encode to base64 string"]
        mergeUserAttributes[attribute] = object
    }
    
    public func userAttribute<T>(for attribute: UserAttributeEntity, key: String) async throws -> T where T: Decodable {
        let appsPreference = try await userAttribute(for: attribute)
        guard
            let encodedString = appsPreference?[key],
            let jsonData = encodedString.base64DecodedData,
            let decodedObject = try? jsonDecoder.decode(T.self, from: jsonData)
        else {
            throw JSONCodingErrorEntity.decoding
        }
        return decodedObject
    }
    
    public func getUserAttribute(for attribute: UserAttributeEntity) async throws -> String? {
        nil
    }
}
