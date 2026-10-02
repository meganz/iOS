import ContinueWhereYouLeftOff
import Foundation
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAFoundation

final class LeftOffItemsRecorder: Sendable {
    static let shared = LeftOffItemsRecorder()

    private let useCase: any LeftOffItemsUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    // Whether the record should record the left off items or not
    // LeftOffItemsRecorder is used as a shared instance therefore it should determined its
    // `isEnabled` at run time (e.g: When user logged out, it should not record items,
    // but when user has logged in it can record items.
    private let isEnabled: @Sendable () -> Bool

    init(
        useCase: some LeftOffItemsUseCaseProtocol = LeftOffItemsRecorder.defaultUseCase(),
        nodeUseCase: some NodeUseCaseProtocol = LeftOffItemsRecorder.defaultNodeUseCase(),
        isEnabled: @escaping @Sendable () -> Bool = LeftOffItemsRecorder.defaultIsEnabled()
    ) {
        self.useCase = useCase
        self.nodeUseCase = nodeUseCase
        self.isEnabled = isEnabled
    }

    func record(handle: HandleEntity, name: String) async {
        guard isEnabled(), !name.isEmpty else { return }
        // A recorded node can be a file link, therefore we need to check whether the recorded node
        // belongs to the current user or not using `nodeForHandle`
        guard await nodeUseCase.nodeForHandle(handle) != nil else { return }

        let item = LeftOffItemEntity(handle: handle, name: name, lastAccessed: .now)
        do {
            try await useCase.record(item)
        } catch {
            MEGALog.log(level: .error, message: "Could not record file with handle: \(handle). Error: \(error.localizedDescription)")
        }
    }

    private static func defaultUseCase() -> some LeftOffItemsUseCaseProtocol {
        let sensitiveNodeUseCase = SensitiveNodeUseCase(
            nodeRepository: NodeRepository.newRepo,
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)
        )

        return ContinueWhereYouLeftOffFactory.makeLeftOffItemsUseCase(
            nodeUseCase: defaultNodeUseCase(),
            sensitiveDisplayPreferenceUseCase: SensitiveDisplayPreferenceUseCase(
                sensitiveNodeUseCase: sensitiveNodeUseCase,
                contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(
                    repo: UserAttributeRepository.newRepo
                )
            ),
            sensitiveNodeUseCase: sensitiveNodeUseCase
        )
    }

    private static func defaultNodeUseCase() -> some NodeUseCaseProtocol {
        NodeUseCase(
            nodeDataRepository: NodeDataRepository.newRepo,
            nodeValidationRepository: NodeValidationRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
        )
    }

    private static func defaultIsEnabled() -> @Sendable () -> Bool {
        let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
        return {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .iosHomeRevampPhaseTwo)
                && accountUseCase.isLoggedIn()
        }
    }
}
