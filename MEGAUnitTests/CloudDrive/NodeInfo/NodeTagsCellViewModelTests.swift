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
    private func makeSUT(
        proLevel: AccountTypeEntity,
        isExpiredAccount: Bool
    ) -> NodeTagsCellViewModel {
        let accountUseCase = AccountUseCase(
            repository: MockAccountRepository(
                isExpiredAccount: isExpiredAccount,
                currentAccountDetails: .build(proLevel: proLevel),
                accountType: proLevel
            )
        )
        return NodeTagsCellViewModel(accountUseCase: accountUseCase)
    }
}
