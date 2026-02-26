import Favourites
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import SwiftUI

extension HomeView {
    public struct Dependency {
        let homeAddMenuActionHandler: any HomeAddMenuActionHandling
        let router: any HomeViewRouting
        let fullNameHandler: @Sendable (CurrentUserSource) -> String
        let userImageUseCase: any UserImageUseCaseProtocol
        let avatarFetcher: @Sendable () async -> Image?
        let fileSearchUseCase: any FilesSearchUseCaseProtocol
        let sensitiveDisplayPreferenceUseCase: any SensitiveDisplayPreferenceUseCaseProtocol
        let favouritesSearchResultsMapper: any FavouritesSearchResultsMapping
        let downloadedNodesListener: any DownloadedNodesListening
        let nodeUseCase: any NodeUseCaseProtocol
        let favouritesContextAction: @MainActor (HandleEntity, UIButton) -> Void
        let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
        let favouritesNodesActionHandler: any NodesActionHandling
        let onFavouritesEditingChanged: @MainActor (Bool) -> Void
        let userBannerUseCase: any UserBannerUseCaseProtocol

        public init(
            homeAddMenuActionHandler: some HomeAddMenuActionHandling,
            router: some HomeViewRouting,
            fullNameHandler: @escaping @Sendable (CurrentUserSource) -> String,
            userImageUseCase: some UserImageUseCaseProtocol,
            avatarFetcher: @escaping @Sendable () async -> Image?,
            fileSearchUseCase: some FilesSearchUseCaseProtocol,
            sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol,
            favouritesSearchResultsMapper: some FavouritesSearchResultsMapping,
            downloadedNodesListener: some DownloadedNodesListening,
            nodeUseCase: some NodeUseCaseProtocol,
            favouritesContextAction: @escaping @MainActor (HandleEntity, UIButton) -> Void,
            sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol,
            favouritesNodesActionHandler: some NodesActionHandling,
            onFavouritesEditingChanged: @escaping @MainActor (Bool) -> Void,
            userBannerUseCase: some UserBannerUseCaseProtocol
        ) {
            self.homeAddMenuActionHandler = homeAddMenuActionHandler
            self.router = router
            self.fileSearchUseCase = fileSearchUseCase
            self.sensitiveDisplayPreferenceUseCase = sensitiveDisplayPreferenceUseCase
            self.favouritesSearchResultsMapper = favouritesSearchResultsMapper
            self.downloadedNodesListener = downloadedNodesListener
            self.nodeUseCase = nodeUseCase
            self.fullNameHandler = fullNameHandler
            self.userImageUseCase = userImageUseCase
            self.avatarFetcher = avatarFetcher
            self.favouritesContextAction = favouritesContextAction
            self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
            self.favouritesNodesActionHandler = favouritesNodesActionHandler
            self.onFavouritesEditingChanged = onFavouritesEditingChanged
            self.userBannerUseCase = userBannerUseCase
        }
    }
}
