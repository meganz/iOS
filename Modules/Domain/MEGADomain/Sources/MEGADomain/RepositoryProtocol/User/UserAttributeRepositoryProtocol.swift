
public protocol UserAttributeRepositoryProtocol {
    func updateUserAttribute(_ attribute: UserAttributeEntity, value: String) async throws
    func updateUserAttribute(_ attribute: UserAttributeEntity, key: String, value: String) async throws
    func userAttribute(for attribute: UserAttributeEntity) async throws -> [String: String]?
}
