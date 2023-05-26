public protocol AccountRepositoryProtocol: RepositoryProtocol {
    var currentUserHandle: HandleEntity? { get }
    func currentUser() async -> UserEntity?
    var isGuest: Bool { get }
    func isLoggedIn() -> Bool
    func contacts() -> [UserEntity]
    func totalNodesCount() -> UInt
    func getMyChatFilesFolder(completion: @escaping (Result<NodeEntity, AccountErrorEntity>) -> Void)
    func accountDetails() async throws -> AccountDetailsEntity
    func upgradeSecurity() async throws -> Bool
    func incomingContactsRequestsCount() -> Int
    func relevantUnseenUserAlertsCount() -> UInt
}
