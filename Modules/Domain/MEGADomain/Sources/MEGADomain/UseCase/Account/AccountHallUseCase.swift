import Combine

public protocol AccountHallUseCaseProtocol {
    var currentUserHandle: HandleEntity? { get }
    var isMasterBusinessAccount: Bool { get }
    func incomingContactsRequestsCount() async -> Int
    func relevantUnseenUserAlertsCount() async -> UInt
    func accountDetails() async throws -> AccountDetailsEntity
    func requestResultPublisher() -> AnyPublisher<Result<AccountRequestEntity, Error>, Never>
    func contactRequestPublisher() -> AnyPublisher<[ContactRequestEntity], Never>
    func userAlertUpdatePublisher() -> AnyPublisher<[UserAlertEntity], Never>
    
    func registerMEGARequestDelegate() async
    func deRegisterMEGARequestDelegate() async
    func registerMEGAGlobalDelegate() async
    func deRegisterMEGAGlobalDelegate() async
}

public struct AccountHallUseCase<T: AccountRepositoryProtocol>: AccountHallUseCaseProtocol {
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
    
    public func incomingContactsRequestsCount() async -> Int {
        repository.incomingContactsRequestsCount()
    }
    
    public func relevantUnseenUserAlertsCount() async -> UInt {
        repository.relevantUnseenUserAlertsCount()
    }
    
    public func accountDetails() async throws -> AccountDetailsEntity {
        try await repository.refreshCurrentAccountDetails()
    }

    public func requestResultPublisher() -> AnyPublisher<Result<AccountRequestEntity, Error>, Never> {
        repository.requestResultPublisher
    }
    
    public func contactRequestPublisher() -> AnyPublisher<[ContactRequestEntity], Never> {
        repository.contactRequestPublisher
    }
    
    public func userAlertUpdatePublisher() -> AnyPublisher<[UserAlertEntity], Never> {
        repository.userAlertUpdatePublisher
    }
    
    public func registerMEGARequestDelegate() async {
        await repository.registerMEGARequestDelegate()
    }
    
    public func deRegisterMEGARequestDelegate() async {
        await repository.deRegisterMEGARequestDelegate()
    }
    
    public func registerMEGAGlobalDelegate() async {
        await repository.registerMEGAGlobalDelegate()
    }
    
    public func deRegisterMEGAGlobalDelegate() async {
        await repository.deRegisterMEGAGlobalDelegate()
    }
}
