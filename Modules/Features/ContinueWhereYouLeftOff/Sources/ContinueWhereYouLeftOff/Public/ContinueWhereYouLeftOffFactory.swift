import MEGADomain

public enum ContinueWhereYouLeftOffFactory {
    private static let sharedStore: any LeftOffItemsStoreProtocol = LeftOffItemsStore()

    public static func makeLeftOffItemsUseCase(
        nodeUseCase: some NodeUseCaseProtocol,
        sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol
    ) -> any LeftOffItemsUseCaseProtocol {
        LeftOffItemsUseCase(
            repository: LeftOffItemsRepository(store: sharedStore),
            nodeUseCase: nodeUseCase,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
            sensitiveNodeUseCase: sensitiveNodeUseCase
        )
    }
}
