@testable import MEGA
import MEGADomain
import MEGADomainMock
import Testing

@Suite("NodeTagsCellViewModel Tests")
struct NodeTagsCellViewModelTests {
    @MainActor
    @Test(
        "Check if the Pro only tag needs to be shown",
        arguments: [
            (proLevel: AccountTypeEntity.free, isExpiredAccount: false, result: true),
            (proLevel: AccountTypeEntity.proI, isExpiredAccount: false, result: false),
            (proLevel: AccountTypeEntity.proII, isExpiredAccount: false, result: false),
            (proLevel: AccountTypeEntity.proIII, isExpiredAccount: false, result: false),
            (proLevel: AccountTypeEntity.lite, isExpiredAccount: false, result: false),
            (proLevel: AccountTypeEntity.starter, isExpiredAccount: false, result: false),
            (proLevel: AccountTypeEntity.basic, isExpiredAccount: false, result: false),
            (proLevel: AccountTypeEntity.essential, isExpiredAccount: false, result: false),
            (proLevel: AccountTypeEntity.feature, isExpiredAccount: false, result: false),
            (proLevel: AccountTypeEntity.business, isExpiredAccount: false, result: false),
            (proLevel: AccountTypeEntity.business, isExpiredAccount: true, result: false),
            (proLevel: AccountTypeEntity.proFlexi, isExpiredAccount: false, result: false),
            (proLevel: AccountTypeEntity.proFlexi, isExpiredAccount: true, result: false)
        ]
    )
    func shouldShowProTag(
        proLevel: AccountTypeEntity,
        isExpiredAccount: Bool,
        result: Bool
    ) {
        let sut = makeSUT(
            proLevel: proLevel,
            isExpiredAccount: isExpiredAccount
        )
        #expect(sut.shouldShowProTag == result)
    }

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
    @Test("Check for tags")
    func checkTags() {
        let node = NodeEntity(tags: ["tag1", "tag2", "tag3"])
        let sut = makeSUT(node: node)
        #expect(sut.tags == ["#tag1", "#tag2", "#tag3"])
    }

    @MainActor
    private func makeSUT(
        node: NodeEntity = NodeEntity(),
        proLevel: AccountTypeEntity = .free,
        isExpiredAccount: Bool = false
    ) -> NodeTagsCellViewModel {
        let accountUseCase = AccountUseCase(
            repository: MockAccountRepository(
                isExpiredAccount: isExpiredAccount,
                currentAccountDetails: .build(proLevel: proLevel),
                accountType: proLevel
            )
        )
        return NodeTagsCellViewModel(node: node, accountUseCase: accountUseCase)
    }
}
