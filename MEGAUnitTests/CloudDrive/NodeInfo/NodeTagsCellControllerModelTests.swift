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

    @MainActor
    @Test(
        "Test value of currentAccountDetails",
        arguments: [AccountDetailsEntity?.none, AccountDetailsEntity.testValue]
    ) func currentAccountDetails(_ accountDetails: AccountDetailsEntity?) async {
        let mockAccountUseCase = MockAccountUseCase(currentAccountDetails: accountDetails)
        let sut = makeSUT(accountUseCase: mockAccountUseCase)
        #expect(sut.currentAccountDetails == accountDetails)
    }

    @MainActor
    @Test("Check for tags")
    func checkTags() {
        let node = NodeEntity(tags: ["tag1", "tag2", "tag3"])
        let sut = makeSUT(node: node)
        #expect(sut.cellViewModel.tags == ["#tag1", "#tag2", "#tag3"])
    }

    @MainActor
    private func makeSUT(
        node: NodeEntity = NodeEntity(),
        proLevel: AccountTypeEntity = .free,
        isExpiredAccount: Bool = false
    ) -> NodeTagsCellControllerModel {
        let accountUseCase = AccountUseCase(
            repository: MockAccountRepository(
                isExpiredAccount: isExpiredAccount,
                currentAccountDetails: .build(proLevel: proLevel),
                accountType: proLevel
            )
        )

        return makeSUT(node: node, accountUseCase: accountUseCase)
    }

    @MainActor
    private func makeSUT(
        node: NodeEntity = NodeEntity(),
        accountUseCase: some AccountUseCaseProtocol
    ) -> NodeTagsCellControllerModel {
        NodeTagsCellControllerModel(node: node, accountUseCase: accountUseCase)
    }
}

private extension AccountDetailsEntity {
    static var testValue: Self {
        AccountDetailsEntity(storageUsed: 0, versionsStorageUsed: 0, storageMax: 0, transferUsed: 0, transferMax: 0, proLevel: .free, proExpiration: 0, subscriptionStatus: .none, subscriptionRenewTime: 0, subscriptionMethod: nil, subscriptionMethodId: .none, subscriptionCycle: .none, numberUsageItems: 0, subscriptions: [], plans: [], storageUsedForHandle: { _ in 0 })
    }
}
