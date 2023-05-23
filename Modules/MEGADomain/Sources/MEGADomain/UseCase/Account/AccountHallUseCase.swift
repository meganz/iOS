public protocol AccountHallUseCaseProtocol {
    func incomingContactsRequestsCount() async -> Int
    func relevantUnseenUserAlertsCount() async -> UInt
    func accountDetails() async throws -> AccountDetailsEntity
}

public struct AccountHallUseCase<T: AccountRepositoryProtocol>: AccountHallUseCaseProtocol {
    private let repository: T
    
    public init(repository: T) {
        self.repository = repository
    }
    
    public func incomingContactsRequestsCount() async -> Int {
        repository.incomingContactsRequestsCount()
    }
    
    public func relevantUnseenUserAlertsCount() async -> UInt {
        repository.relevantUnseenUserAlertsCount()
    }
    
    public func accountDetails() async throws -> AccountDetailsEntity {
        try await repository.accountDetails()
    }
}
