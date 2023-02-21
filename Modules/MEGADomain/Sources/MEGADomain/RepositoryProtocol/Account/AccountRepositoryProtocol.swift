public protocol AccountRepositoryProtocol: RepositoryProtocol {
    var currentUser: UserEntity? { get }
    var isGuest: Bool { get }
    func isLoggedIn() -> Bool
    func contacts() -> [UserEntity]
    func totalNodesCount() -> UInt
    func getMyChatFilesFolder(completion: @escaping (Result<NodeEntity, AccountErrorEntity>) -> Void)
    func getAccountDetails(completion: @escaping (Result<AccountDetailsEntity, AccountDetailsErrorEntity>) -> Void)
    func upgradeSecurity() async throws -> Bool
}
