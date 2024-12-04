@testable import CloudDrive
import MEGADomain
import MEGADomainMock
import MEGAL10n
import Testing

@Suite("NodeTagsCellControllerModel Tests")
struct NodeTagsCellControllerModelTests {

    @MainActor
    @Test(
        "Check if the user has a valid subscription",
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
    func hasValidSubscription(
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
    @Test(
        "Check for feature unavailable description",
        arguments: [
            (proLevel: AccountTypeEntity.business, isMasterBusinessAccount: true, isExpiredAccount: true,
             result: Strings.Localizable.CloudDrive.NodeInfo.NodeTags.FeatureUnavailable.Popup.Description.AccountType.masterBusiness),
            (proLevel: AccountTypeEntity.business, isMasterBusinessAccount: false, isExpiredAccount: true,
             result: Strings.Localizable.CloudDrive.NodeInfo.NodeTags.FeatureUnavailable.Popup.Description.AccountType.memberBusiness),
            (proLevel: AccountTypeEntity.proFlexi, isMasterBusinessAccount: false, isExpiredAccount: true,
             result: Strings.Localizable.CloudDrive.NodeInfo.NodeTags.FeatureUnavailable.Popup.Description.AccountType.proFlexi)
        ]
    )
    func test(proLevel: AccountTypeEntity, isMasterBusinessAccount: Bool, isExpiredAccount: Bool, result: String) {
        let sut = makeSUT(
            proLevel: proLevel,
            isMasterBusinessAccount: isMasterBusinessAccount,
            isExpiredAccount: isExpiredAccount
        )
        #expect(sut.featureUnavailableDescription == result)
    }

    @MainActor
    @Test("Check for tags")
    func checkTags() {
        let tags = ["tag1", "tag2", "tag3"]
        let node = NodeEntity(tags: tags)
        let sut = makeSUT(node: node)
        #expect(sut.selectedTags == Set(tags))
        #expect(sut.cellViewModel.tags == tags)
    }

    @MainActor
    private func makeSUT(
        node: NodeEntity = NodeEntity(),
        proLevel: AccountTypeEntity = .free,
        isMasterBusinessAccount: Bool = false,
        isExpiredAccount: Bool = false,
        isInGracePeriod: Bool = false
    ) -> NodeTagsCellControllerModel {
        let accountUseCase = AccountUseCase(
            repository: MockAccountRepository(
                isMasterBusinessAccount: isMasterBusinessAccount,
                isExpiredAccount: isExpiredAccount,
                isInGracePeriod: isInGracePeriod,
                currentAccountDetails: .build(proLevel: proLevel),
                accountType: proLevel
            )
        )

        return NodeTagsCellControllerModel(node: node, accountUseCase: accountUseCase)
    }
}
