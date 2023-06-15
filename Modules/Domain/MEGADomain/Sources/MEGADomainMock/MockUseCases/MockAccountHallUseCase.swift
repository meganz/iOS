import Combine
import MEGADomain

final public class MockAccountHallUseCase: AccountHallUseCaseProtocol {
    private let contactRequestsCount: Int
    private let unseenUserAlertsCount: UInt
    private let accountDetails: AccountDetailsEntity
    private let requestFinishPublisher: PassthroughSubject<Result<AccountRequestEntity, Error>, Never>
    private let _isMasterBusinessAccount: Bool
    private let _currentUserHandle: HandleEntity?
    
    public var registerMEGARequestDelegateCalled = 0
    public var deRegisterMEGARequestDelegateCalled = 0
    
    public init(contactRequestsCount: Int = 0,
                unseenUserAlertsCount: UInt = 0,
                accountDetails: AccountDetailsEntity = AccountDetailsEntity(),
                isMasterBusinessAccount: Bool = false,
                currentUserHandle: HandleEntity? = nil,
                requestResultPublisher: PassthroughSubject<Result<AccountRequestEntity, Error>, Never> = PassthroughSubject<Result<AccountRequestEntity, Error>, Never>()) {
        self.contactRequestsCount = contactRequestsCount
        self.unseenUserAlertsCount = unseenUserAlertsCount
        self.accountDetails = accountDetails
        self.requestFinishPublisher = requestResultPublisher
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
        requestFinishPublisher.eraseToAnyPublisher()
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
}
