public protocol UserAttributeRepositoryProtocol: Sendable {
    func updateUserAttribute(_ attribute: UserAttributeEntity, value: String) async throws
    /// Merges the value for the associated attribute and key assigned to that attribute, with the provided Encodable object.
    /// The object will be encoded into a json format to be saved as a String attribute on the users attributes.
    /// This function attempts to merge provided object with the current existing object stored, by replacing only the fields at the 1st level of the root object.
    /// This is to ensure that we do not overwrite any nested objects that we do not support in our Encodable object.
    ///
    /// This function should be used primarily to store encodable object under a UserAttributeEntity.

    /// - Parameters:
    ///   - attribute: UserAttributeEntity location of where the value will be set in userAttribute
    ///   - key: String key of where the value will be stored in the dictionary, that is stored on the attribute
    ///   - object: Encodable object to be stored as a JSON string.
    func mergeUserAttribute<T: Encodable>(_ attribute: UserAttributeEntity, key: String, object: T) async throws
    func updateUserAttribute(_ attribute: UserAttributeEntity, key: String, value: String) async throws
    
    ///  Fetches dictionary structure under the given attribute. If the attribute does not exist or was never set before, it will throw an error. If a optional value has been set previously it will return the value stored under the attribute.
    /// - Parameter attribute: UserAttributeEntity location of where the value will be fetched from .
    /// - Returns: Optional [String: String] dictionary stored at the attribute, if attribute was never set previously it will throw.
    ///
    /// - Throws: UserAttributeErrorEntity.attributeNotFound if the attribute has never set before.
    func userAttribute(for attribute: UserAttributeEntity) async throws -> [String: String]?
    
    /// Retrieve the decodable object from the associated user attribute for the given key. If the object for the attribute and key does not exist it will throw an error.
    /// If the stored structure cannot be decoded into the desired object it will throw an error
    /// - Parameters:
    ///   - attribute: UserAttributeEntity location of where the value will be set in userAttribute
    ///   - key: String key of where the value will be stored in the dictionary, that is stored on the attribute
    ///
    /// - Returns: Decodable object stored at the attribute and key
    func userAttribute<T: Decodable>(for attribute: UserAttributeEntity, key: String) async throws -> T
}
