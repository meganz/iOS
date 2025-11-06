import AsyncAlgorithms
@testable import CloudDrive
@preconcurrency import Combine
import Foundation
import MEGADomain
import MEGADomainMock
import Testing

@Suite("NodeTagsCellViewModel Tests")
struct NodeTagsCellViewModelTests {
    @MainActor
    @Test("Check for tags")
    func checkTags() {
        let tags = ["tag1", "tag2", "tag3"]
        let node = NodeEntity(tags: tags)
        let sut = makeSUT(node: node)
        #expect(sut.tags == tags)
    }

    @MainActor
    @Test(
        "Check if the user has a expired business or pro flexi account",
        arguments: [
            (proLevel: AccountTypeEntity.free, isExpiredAccount: false, isInGracePeriod: false, result: false),
            (proLevel: AccountTypeEntity.free, isExpiredAccount: false, isInGracePeriod: true, result: false),
            (proLevel: AccountTypeEntity.free, isExpiredAccount: true, isInGracePeriod: false, result: false),
            (proLevel: AccountTypeEntity.proI, isExpiredAccount: false, isInGracePeriod: false, result: false),
            (proLevel: AccountTypeEntity.proI, isExpiredAccount: false, isInGracePeriod: true, result: false),
            (proLevel: AccountTypeEntity.proI, isExpiredAccount: true, isInGracePeriod: false, result: false),
            (proLevel: AccountTypeEntity.proII, isExpiredAccount: false, isInGracePeriod: false, result: false),
            (proLevel: AccountTypeEntity.proII, isExpiredAccount: false, isInGracePeriod: true, result: false),
            (proLevel: AccountTypeEntity.proII, isExpiredAccount: true, isInGracePeriod: false, result: false),
            (proLevel: AccountTypeEntity.proIII, isExpiredAccount: false, isInGracePeriod: false, result: false),
            (proLevel: AccountTypeEntity.proIII, isExpiredAccount: false, isInGracePeriod: true, result: false),
            (proLevel: AccountTypeEntity.proIII, isExpiredAccount: true, isInGracePeriod: false, result: false),
            (proLevel: AccountTypeEntity.lite, isExpiredAccount: false, isInGracePeriod: false, result: false),
            (proLevel: AccountTypeEntity.lite, isExpiredAccount: false, isInGracePeriod: true, result: false),
            (proLevel: AccountTypeEntity.lite, isExpiredAccount: true, isInGracePeriod: false, result: false),
            (proLevel: AccountTypeEntity.business, isExpiredAccount: false, isInGracePeriod: false, result: false),
            (proLevel: AccountTypeEntity.business, isExpiredAccount: false, isInGracePeriod: true, result: false),
            (proLevel: AccountTypeEntity.business, isExpiredAccount: true, isInGracePeriod: false, result: true),
            (proLevel: AccountTypeEntity.proFlexi, isExpiredAccount: false, isInGracePeriod: false, result: false),
            (proLevel: AccountTypeEntity.proFlexi, isExpiredAccount: false, isInGracePeriod: true, result: false),
            (proLevel: AccountTypeEntity.proFlexi, isExpiredAccount: true, isInGracePeriod: false, result: true),
            (proLevel: AccountTypeEntity.starter, isExpiredAccount: false, isInGracePeriod: false, result: false),
            (proLevel: AccountTypeEntity.starter, isExpiredAccount: false, isInGracePeriod: true, result: false),
            (proLevel: AccountTypeEntity.starter, isExpiredAccount: true, isInGracePeriod: false, result: false),
            (proLevel: AccountTypeEntity.basic, isExpiredAccount: false, isInGracePeriod: false, result: false),
            (proLevel: AccountTypeEntity.basic, isExpiredAccount: false, isInGracePeriod: true, result: false),
            (proLevel: AccountTypeEntity.basic, isExpiredAccount: true, isInGracePeriod: false, result: false),
            (proLevel: AccountTypeEntity.essential, isExpiredAccount: false, isInGracePeriod: false, result: false),
            (proLevel: AccountTypeEntity.essential, isExpiredAccount: false, isInGracePeriod: true, result: false),
            (proLevel: AccountTypeEntity.essential, isExpiredAccount: true, isInGracePeriod: false, result: false),
            (proLevel: AccountTypeEntity.feature, isExpiredAccount: false, isInGracePeriod: false, result: false),
            (proLevel: AccountTypeEntity.feature, isExpiredAccount: false, isInGracePeriod: true, result: false),
            (proLevel: AccountTypeEntity.feature, isExpiredAccount: true, isInGracePeriod: false, result: false)
        ]
    )
    func verifyIsExpiredBusinessOrProFlexiAccount(
        proLevel: AccountTypeEntity,
        isExpiredAccount: Bool,
        isInGracePeriod: Bool,
        result: Bool
    ) {
        let sut = makeSUT(
            proLevel: proLevel,
            isExpiredAccount: isExpiredAccount,
            isInGracePeriod: isInGracePeriod
        )
        #expect(sut.isExpiredBusinessOrProFlexiAccount == result)
    }

    @MainActor
    private func makeSUT(
        proLevel: AccountTypeEntity = .proI,
        isExpiredAccount: Bool = false,
        isInGracePeriod: Bool = false,
        node: NodeEntity = NodeEntity()
    ) -> NodeTagsCellViewModel {
        let accountUseCase = AccountUseCase(
            repository: MockAccountRepository(
                isExpiredAccount: isExpiredAccount,
                isInGracePeriod: isInGracePeriod,
                currentAccountDetails: .build(proLevel: proLevel),
                accountType: proLevel
            )
        )

        return NodeTagsCellViewModel(node: node, accountUseCase: accountUseCase, userInteractionEnabled: false)
    }
}
