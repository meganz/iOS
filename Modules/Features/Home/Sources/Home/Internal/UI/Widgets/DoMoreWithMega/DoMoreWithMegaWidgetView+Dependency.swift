import MEGADomain

extension DoMoreWithMegaWidgetView {
    struct Dependency {
        let actionHandler: any DoMoreWithMegaActionHandling
        let createAlbumUseCase: any CreateAlbumUseCaseProtocol

        @MainActor
        init(
            addMenuActionHandler: some HomeAddMenuActionHandling,
            router: some HomeViewRouting,
            accountStorageUseCase: some AccountStorageUseCaseProtocol,
            albumNameUseCase: some AlbumNameUseCaseProtocol,
            albumListUseCase: some AlbumListUseCaseProtocol
        ) {
            self.actionHandler = DoMoreWithMegaActionHandler(router: router, addMenuActionHandler: addMenuActionHandler)
            self.createAlbumUseCase = CreateAlbumUseCase(
                accountStorageUseCase: accountStorageUseCase,
                albumNameUseCase: albumNameUseCase,
                albumListUseCase: albumListUseCase
            )
        }
    }
}
