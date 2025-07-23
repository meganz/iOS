public protocol ContactsRepositoryProtocol: RepositoryProtocol, Sendable {
    func contact(forUserHandle handle: HandleEntity) -> UserEntity?
    var isContactVerificationWarningEnabled: Bool { get }
}
