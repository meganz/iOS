@testable import MEGA
import MEGADomain
import MEGADomainMock
import Testing

@Suite("NodeTagsCellControllerModel Tests")
struct NodeTagsCellControllerModelTests {
    @MainActor
    @Test(
        "Check if the user has a valid subscription",
        arguments: [
            (proLevel: AccountTypeEntity.free, isExpiredAccount: true, result: false),
            (proLevel: AccountTypeEntity.proI, isExpiredAccount: true, result: true),
            (proLevel: AccountTypeEntity.proII, isExpiredAccount: true, result: true),
            (proLevel: AccountTypeEntity.proIII, isExpiredAccount: true, result: true),
            (proLevel: AccountTypeEntity.lite, isExpiredAccount: true, result: true),
            (proLevel: AccountTypeEntity.business, isExpiredAccount: false, result: true),
            (proLevel: AccountTypeEntity.business, isExpiredAccount: true, result: false),
            (proLevel: AccountTypeEntity.proFlexi, isExpiredAccount: false, result: true),
            (proLevel: AccountTypeEntity.proFlexi, isExpiredAccount: true, result: false),
            (proLevel: AccountTypeEntity.starter, isExpiredAccount: true, result: true),
            (proLevel: AccountTypeEntity.basic, isExpiredAccount: true, result: true),
            (proLevel: AccountTypeEntity.essential, isExpiredAccount: true, result: true),
            (proLevel: AccountTypeEntity.feature, isExpiredAccount: true, result: true)
        ]
    )
    func hasValidSubscription(
        proLevel: AccountTypeEntity,
        isExpiredAccount: Bool,
        result: Bool
    ) {
        let sut = makeSUT(
            proLevel: proLevel,
            isExpiredAccount: isExpiredAccount
        )
        #expect(sut.hasValidSubscription == result)
    }
    
    @Test(
        "Test value of currentAccountDetails",
        arguments: [AccountDetailsEntity?.none, AccountDetailsEntity.testValue]
    ) func currentAccountDetails(_ accountDetails: AccountDetailsEntity?) async {
        let mockAccountUsecase = MockAccountUseCase(currentAccountDetails: accountDetails)
        let sut = await NodeTagsCellControllerModel(accountUseCase: mockAccountUsecase)
        #expect(await sut.currentAccountDetails == accountDetails)
    }

    @MainActor
    private func makeSUT(
        proLevel: AccountTypeEntity,
        isExpiredAccount: Bool
    ) -> NodeTagsCellControllerModel {
        let accountUseCase = AccountUseCase(
            repository: MockAccountRepository(
                isExpiredAccount: isExpiredAccount,
                currentAccountDetails: .build(proLevel: proLevel),
                accountType: proLevel
            )
        )
        return NodeTagsCellControllerModel(accountUseCase: accountUseCase)
    }
}

private extension AccountDetailsEntity {
    static var testValue: Self {
        AccountDetailsEntity(storageUsed: 0, versionsStorageUsed: 0, storageMax: 0, transferUsed: 0, transferMax: 0, proLevel: .free, proExpiration: 0, subscriptionStatus: .none, subscriptionRenewTime: 0, subscriptionMethod: nil, subscriptionMethodId: .none, subscriptionCycle: .none, numberUsageItems: 0, subscriptions: [], plans: [], storageUsedForHandle: { _ in 0 })
    }
}
