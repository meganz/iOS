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
    @Test("Check for tags")
    func checkTags() {
        let tags = ["tag1", "tag2", "tag3"]
        let node = NodeEntity(tags: tags)
        let sut = makeSUT(node: node)
        #expect(sut.cellViewModel.tags == tags)
    }

    @MainActor
    @Test("Check for tags managemenet permission",
          arguments: [
            (accessLevel: NodeAccessTypeEntity.unknown, hasTagsManagementPermission: false),
            (accessLevel: NodeAccessTypeEntity.read, hasTagsManagementPermission: false),
            (accessLevel: NodeAccessTypeEntity.readWrite, hasTagsManagementPermission: false),
            (accessLevel: NodeAccessTypeEntity.owner, hasTagsManagementPermission: true),
            (accessLevel: NodeAccessTypeEntity.full, hasTagsManagementPermission: true)
            ]
    )
    func checkTasgManagementPermission(accessLevel: NodeAccessTypeEntity, hasTagsManagementPermission: Bool) {
        let sut = makeSUT(nodeAccessLevel: accessLevel)
        #expect(sut.hasTagsManagementPermission == hasTagsManagementPermission)
    }

    @MainActor
    private func makeSUT(
        node: NodeEntity = NodeEntity(),
        proLevel: AccountTypeEntity = .free,
        isMasterBusinessAccount: Bool = false,
        isExpiredAccount: Bool = false,
        isInGracePeriod: Bool = false,
        nodeAccessLevel: NodeAccessTypeEntity = .unknown
    ) -> NodeTagsCellControllerModel {
        let nodeUseCase = MockNodeUseCase(nodeAccessLevel: { nodeAccessLevel })
        let accountUseCase = AccountUseCase(
            repository: MockAccountRepository(
                isMasterBusinessAccount: isMasterBusinessAccount,
                isExpiredAccount: isExpiredAccount,
                isInGracePeriod: isInGracePeriod,
                currentAccountDetails: .build(proLevel: proLevel),
                accountType: proLevel
            )
        )

        return NodeTagsCellControllerModel(
            node: node,
            accountUseCase: accountUseCase,
            nodeUseCase: nodeUseCase
        )
    }
}
