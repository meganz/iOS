public protocol ContactsRepositoryProtocol: RepositoryProtocol {
    func contact(forUserHandle handle: HandleEntity) -> UserEntity?
}
