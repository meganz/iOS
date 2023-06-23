import Combine
import MEGADomain

final public class MockAccountHallUseCase: AccountHallUseCaseProtocol {
    private let contactRequestsCount: Int
    private let unseenUserAlertsCount: UInt
    private let accountDetails: AccountDetailsEntity
    private let _requestResultPublisher: PassthroughSubject<Result<AccountRequestEntity, Error>, Never>
    private let _contactRequestPublisher: PassthroughSubject<[ContactRequestEntity], Never>
    private let _userAlertUpdatePublisher: PassthroughSubject<[UserAlertEntity], Never>
    private let _isMasterBusinessAccount: Bool
    private let _currentUserHandle: HandleEntity?
    
    public var registerMEGARequestDelegateCalled = 0
    public var deRegisterMEGARequestDelegateCalled = 0
    public var registerMEGAGlobalDelegateCalled = 0
    public var deRegisterMEGAGlobalDelegateCalled = 0
    
    public init(contactRequestsCount: Int = 0,
                unseenUserAlertsCount: UInt = 0,
                accountDetails: AccountDetailsEntity = AccountDetailsEntity(),
                isMasterBusinessAccount: Bool = false,
                currentUserHandle: HandleEntity? = nil,
                requestResultPublisher: PassthroughSubject<Result<AccountRequestEntity, Error>, Never> = PassthroughSubject<Result<AccountRequestEntity, Error>, Never>(),
                contactRequestPublisher: PassthroughSubject<[ContactRequestEntity], Never> = PassthroughSubject<[ContactRequestEntity], Never>(),
                userAlertUpdatePublisher: PassthroughSubject<[UserAlertEntity], Never> = PassthroughSubject<[UserAlertEntity], Never>()) {
        self.contactRequestsCount = contactRequestsCount
        self.unseenUserAlertsCount = unseenUserAlertsCount
        self.accountDetails = accountDetails
        _requestResultPublisher = requestResultPublisher
        _contactRequestPublisher = contactRequestPublisher
        _userAlertUpdatePublisher = userAlertUpdatePublisher
        _isMasterBusinessAccount = isMasterBusinessAccount
        _currentUserHandle = currentUserHandle
    }
    
    public func incomingContactsRequestsCount() async -> Int {
        contactRequestsCount
    }
    
    public func relevantUnseenUserAlertsCount() async -> UInt {
        unseenUserAlertsCount
    }
    
    public func accountDetails() async throws -> AccountDetailsEntity {
        accountDetails
    }
    
    public func requestResultPublisher() -> AnyPublisher<Result<AccountRequestEntity, Error>, Never> {
        _requestResultPublisher.eraseToAnyPublisher()
    }
    
    public func contactRequestPublisher() -> AnyPublisher<[ContactRequestEntity], Never> {
        _contactRequestPublisher.eraseToAnyPublisher()
    }
    
    public func userAlertUpdatePublisher() -> AnyPublisher<[UserAlertEntity], Never> {
        _userAlertUpdatePublisher.eraseToAnyPublisher()
    }
    
    public var currentUserHandle: HandleEntity? {
        _currentUserHandle
    }
    
    public var isMasterBusinessAccount: Bool {
        _isMasterBusinessAccount
    }
    
    public func registerMEGARequestDelegate() async {
        registerMEGARequestDelegateCalled += 1
    }
    
    public func deRegisterMEGARequestDelegate() {
        deRegisterMEGARequestDelegateCalled += 1
    }
    
    public func registerMEGAGlobalDelegate() async {
        registerMEGAGlobalDelegateCalled += 1
    }
    
    public func deRegisterMEGAGlobalDelegate() async {
        deRegisterMEGAGlobalDelegateCalled += 1
    }
}
