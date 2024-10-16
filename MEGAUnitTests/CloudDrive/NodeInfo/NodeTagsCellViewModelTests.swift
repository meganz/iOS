@testable import MEGA
import MEGADomain
import MEGADomainMock
import Testing

@Suite("NodeTagsCellViewModel Tests")
struct NodeTagsCellViewModelTests {
    @Test(
        "Check if the user is a pro user",
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
    func isProUser(
        proLevel: AccountTypeEntity,
        isExpiredAccount: Bool,
        result: Bool
    ) {
        let sut = makeSUT(
            proLevel: proLevel,
            isExpiredAccount: isExpiredAccount
        )
        #expect(sut.isPaidAccount == result)
    }

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
