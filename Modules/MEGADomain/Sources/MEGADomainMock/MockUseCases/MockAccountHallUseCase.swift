import MEGADomain

public struct MockAccountHallUseCase: AccountHallUseCaseProtocol {
    private let contactRequestsCount: Int
    private let unseenUserAlertsCount: UInt
    private let accountDetails: AccountDetailsEntity
    
    public init(contactRequestsCount: Int = 0,
                unseenUserAlertsCount: UInt = 0,
                accountDetails: AccountDetailsEntity = AccountDetailsEntity()) {
        self.contactRequestsCount = contactRequestsCount
        self.unseenUserAlertsCount = unseenUserAlertsCount
        self.accountDetails = accountDetails
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
}
