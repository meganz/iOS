import MEGASwift

public protocol MyAccountHallUseCaseProtocol: Sendable {
    var currentUserHandle: HandleEntity? { get }
    var isMasterBusinessAccount: Bool { get }
    var isAchievementsEnabled: Bool { get }
    func incomingContactsRequestsCount() async -> Int
    func relevantUnseenUserAlertsCount() async -> UInt
    
    var currentAccountDetails: AccountDetailsEntity? { get }
    func refreshCurrentAccountDetails() async throws -> AccountDetailsEntity
    
    var onAccountRequestFinish: AnyAsyncSequence<Result<AccountRequestEntity, any Error>> { get }
    var onUserAlertsUpdates: AnyAsyncSequence<[UserAlertEntity]> { get }
    var onContactRequestsUpdates: AnyAsyncSequence<[ContactRequestEntity]> { get }
}

public struct MyAccountHallUseCase<T: AccountRepositoryProtocol>: MyAccountHallUseCaseProtocol {
    private let repository: T
    
    public init(repository: T) {
        self.repository = repository
    }
    
    public var currentUserHandle: HandleEntity? {
        repository.currentUserHandle
    }
    
    public var isMasterBusinessAccount: Bool {
        repository.isMasterBusinessAccount
    }
    
    public var isAchievementsEnabled: Bool {
        repository.isAchievementsEnabled
    }
    
    public func incomingContactsRequestsCount() async -> Int {
        repository.incomingContactsRequestsCount()
    }
    
    public func relevantUnseenUserAlertsCount() async -> UInt {
        repository.relevantUnseenUserAlertsCount()
    }
    
    public var currentAccountDetails: AccountDetailsEntity? {
        repository.currentAccountDetails
    }
    
    public func refreshCurrentAccountDetails() async throws -> AccountDetailsEntity {
        try await repository.refreshCurrentAccountDetails()
    }
    
    public var onAccountRequestFinish: AnyAsyncSequence<Result<AccountRequestEntity, any Error>> {
        repository.onAccountRequestFinish
    }
    
    public var onUserAlertsUpdates: AnyAsyncSequence<[UserAlertEntity]> {
        repository.onUserAlertsUpdates
    }
    
    public var onContactRequestsUpdates: AnyAsyncSequence<[ContactRequestEntity]> {
        repository.onContactRequestsUpdates
    }
}
