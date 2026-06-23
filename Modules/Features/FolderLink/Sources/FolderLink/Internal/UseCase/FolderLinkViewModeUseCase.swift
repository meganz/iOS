import MEGADomain
import MEGAPreference
import Search

package protocol FolderLinkViewModeUseCaseProtocol: Sendable {
    func viewModeForOpeningFolder(_ handle: HandleEntity) -> SearchResultsViewMode
    func shouldEnableMediaDiscoveryMode(for handle: HandleEntity) -> Bool
}

package struct FolderLinkViewModeUseCase: FolderLinkViewModeUseCaseProtocol {
    private let folderLinkRepository: any FolderLinkRepositoryProtocol

    @PreferenceWrapper(key: PreferenceKeyEntity.shouldDisplayMediaDiscoveryWhenMediaOnly, defaultValue: true, useCase: PreferenceUseCase.default)
    private var autoMediaDiscoveryEnabled: Bool

    @PreferenceWrapper(key: PreferenceKeyEntity.viewModePreference, defaultValue: ViewModePreferenceEntity.perFolder.rawValue, useCase: PreferenceUseCase.default)
    private var savedViewModePreference: Int

    package init(
        folderLinkRepository: some FolderLinkRepositoryProtocol = FolderLinkRepository.newRepo,
        preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default
    ) {
        self.folderLinkRepository = folderLinkRepository
        $autoMediaDiscoveryEnabled.useCase = preferenceUseCase
        $savedViewModePreference.useCase = preferenceUseCase
    }

    package func viewModeForOpeningFolder(_ handle: HandleEntity) -> SearchResultsViewMode {
        let children = folderLinkRepository.children(of: handle)

        if autoMediaDiscoveryEnabled, !children.isEmpty, children.allSatisfy({ $0.mediaType != nil }) {
            return .mediaDiscovery
        }

        switch ViewModePreferenceEntity(rawValue: savedViewModePreference) {
        case .list: return .list
        case .thumbnail: return .grid
        default: return automaticViewMode(for: children)
        }
    }

    private func automaticViewMode(for children: [NodeEntity]) -> SearchResultsViewMode {
        let (withThumbnail, withoutThumbnail) = children.reduce(into: (withThumbnail: 0, withoutThumbnail: 0)) { counts, node in
            if node.hasThumbnail {
                counts.withThumbnail += 1
            } else {
                counts.withoutThumbnail += 1
            }
        }

        return withThumbnail > withoutThumbnail ? .grid : .list
    }

    package func shouldEnableMediaDiscoveryMode(for handle: HandleEntity) -> Bool {
        let children = folderLinkRepository.children(of: handle)
        return children.contains(where: { $0.mediaType != nil })
    }
}
