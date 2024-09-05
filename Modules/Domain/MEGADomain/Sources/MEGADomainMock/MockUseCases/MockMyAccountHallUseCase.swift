import MEGADomain
import MEGASwift

final public class MockMyAccountHallUseCase: MyAccountHallUseCaseProtocol {
    private let contactRequestsCount: Int
    private let unseenUserAlertsCount: UInt
    private let _currentAccountDetails: AccountDetailsEntity
    private let _isMasterBusinessAccount: Bool
    private let _isAchievementsEnabled: Bool
    private let _currentUserHandle: HandleEntity?
    
    public let onAccountRequestFinish: AnyAsyncSequence<Result<AccountRequestEntity, any Error>>
    public let onUserAlertsUpdates: AnyAsyncSequence<[UserAlertEntity]>
    public let onContactRequestsUpdates: AnyAsyncSequence<[ContactRequestEntity]>
    
    public init(
        contactRequestsCount: Int = 0,
        unseenUserAlertsCount: UInt = 0,
        currentAccountDetails: AccountDetailsEntity = AccountDetailsEntity.build(),
        isMasterBusinessAccount: Bool = false,
        isAchievementsEnabled: Bool = false,
        currentUserHandle: HandleEntity? = nil,
        onAccountRequestFinish: AnyAsyncSequence<Result<AccountRequestEntity, any Error>> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        onUserAlertsUpdates: AnyAsyncSequence<[UserAlertEntity]> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        onContactRequestsUpdates: AnyAsyncSequence<[ContactRequestEntity]> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    ) {
        self.contactRequestsCount = contactRequestsCount
        self.unseenUserAlertsCount = unseenUserAlertsCount
        _currentAccountDetails = currentAccountDetails
        _isMasterBusinessAccount = isMasterBusinessAccount
        _isAchievementsEnabled = isAchievementsEnabled
        _currentUserHandle = currentUserHandle
        self.onAccountRequestFinish = onAccountRequestFinish
        self.onUserAlertsUpdates = onUserAlertsUpdates
        self.onContactRequestsUpdates = onContactRequestsUpdates
    }
    
    public func incomingContactsRequestsCount() async -> Int {
        contactRequestsCount
    }
    
    public func relevantUnseenUserAlertsCount() async -> UInt {
        unseenUserAlertsCount
    }
    
    public var currentAccountDetails: AccountDetailsEntity? {
        _currentAccountDetails
    }
    
    public func refreshCurrentAccountDetails() async throws -> AccountDetailsEntity {
        _currentAccountDetails
    }
    
    public var currentUserHandle: HandleEntity? {
        _currentUserHandle
    }
    
    public var isMasterBusinessAccount: Bool {
        _isMasterBusinessAccount
    }
    
    public var isAchievementsEnabled: Bool {
        _isAchievementsEnabled
    }
}
