
public protocol UserAttributeRepositoryProtocol {
    func updateUserAttribute(_ attribute: UserAttributeEntity, value: String) async throws
}
