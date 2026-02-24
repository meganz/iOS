import AsyncAlgorithms
import Foundation
import MEGAAppPresentation
import MEGADomain
import MEGASwift
import Search

struct FavouriteSearchResultsProvider: SearchResultsProviding {
    struct Dependency {
        let fileSearchUseCase: any FilesSearchUseCaseProtocol
        let sensitiveDisplayPreferenceUseCase: any SensitiveDisplayPreferenceUseCaseProtocol
        let searchResultsMapper: any FavouritesSearchResultsMapping
        let downloadedNodesListener: any DownloadedNodesListening
        let nodeUseCase: any NodeUseCaseProtocol
        let availableChips: [SearchChipEntity]

        init(
            fileSearchUseCase: some FilesSearchUseCaseProtocol,
            sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol,
            searchResultsMapper: some FavouritesSearchResultsMapping,
            downloadedNodesListener: some DownloadedNodesListening,
            nodeUseCase: some NodeUseCaseProtocol,
            availableChips: [SearchChipEntity] = SearchChipEntity.allChips(
                currentDate: { .now },
                calendar: .current
            )
        ) {
            self.fileSearchUseCase = fileSearchUseCase
            self.sensitiveDisplayPreferenceUseCase = sensitiveDisplayPreferenceUseCase
            self.searchResultsMapper = searchResultsMapper
            self.downloadedNodesListener = downloadedNodesListener
            self.nodeUseCase = nodeUseCase
            self.availableChips = availableChips
        }
    }

    private let dependency: Dependency
    @Atomic private var nodes: [NodeEntity]?

    init(dependency: Dependency) {
        self.dependency = dependency
    }

    func refreshedSearchResults(queryRequest: SearchQuery) async throws -> SearchResultsEntity? {
        await results(for: queryRequest)
    }

    func search(queryRequest: SearchQuery, lastItemIndex: Int?) async -> SearchResultsEntity? {
        guard lastItemIndex == nil else { return nil }
        return await results(for: queryRequest)
    }

    func currentResultIds() -> [ResultId] {
        guard let nodes else { return [] }
        return nodes.map(\.id)
    }

    func searchResultUpdateSignalSequence() -> AnyAsyncSequence<SearchResultUpdateSignal> {
        merge(specificNodeUpdateSequence(), genericNodeUpdateSequence())
            .eraseToAnyAsyncSequence()
    }

    // MARK: - Private methods

    private func results(for queryRequest: SearchQuery) async -> SearchResultsEntity? {
        let nodes: [NodeEntity]? = try? await dependency.fileSearchUseCase.search(
            filter: .recursive(
                searchText: queryRequest.query,
                searchDescription: queryRequest.query,
                searchTag: queryRequest.query.removingFirstLeadingHash(),
                searchTargetLocation: .folderTarget(.rootNode),
                supportCancel: true,
                sortOrderType: queryRequest.sorting.toDomainSortOrderEntity(),
                formatType: queryRequest.selectedNodeFormat?.toNodeFormatEntity() ?? .unknown,
                sensitiveFilterOption: await dependency.sensitiveDisplayPreferenceUseCase.excludeSensitives() ? .nonSensitiveOnly : .disabled,
                favouriteFilterOption: .onlyFavourites,
                nodeTypeEntity: queryRequest.selectedNodeType?.toNodeTypeEntity() ?? .unknown,
                modificationTimeFrame: queryRequest.selectedModificationTimeFrame?.toSearchFilterTimeFrame(),
                useAndForTextQuery: false
            ),
            cancelPreviousSearchIfNeeded: true
        )

        guard let nodes else {
            return .init(results: [], availableChips: dependency.availableChips, appliedChips: [])
        }

        self.$nodes.mutate { $0 = nodes }
        let results = nodes.map { dependency.searchResultsMapper.map(node: $0) }
        return .init(results: results, availableChips: dependency.availableChips, appliedChips: queryRequest.chips)
    }

    private func specificNodeUpdateSequence() -> AnyAsyncSequence<SearchResultUpdateSignal> {
        dependency.downloadedNodesListener.downloadedNodes
            .map {
                SearchResultUpdateSignal.specific(result: dependency.searchResultsMapper.map(node: $0))
            }.eraseToAnyAsyncSequence()
    }

    private func genericNodeUpdateSequence() -> AnyAsyncSequence<SearchResultUpdateSignal> {
        dependency
            .nodeUseCase
            .nodeUpdates
            .compactMap { updatedNodes -> SearchResultUpdateSignal? in
                guard nodeUpdateContainsCurrentSearchResultValue(nodeUpdates: updatedNodes) else { return nil }
                return SearchResultUpdateSignal.generic
            }
            .eraseToAnyAsyncSequence()
    }

    private func nodeUpdateContainsCurrentSearchResultValue(nodeUpdates: [NodeEntity]) -> Bool {
        let currentResultIds = currentResultIds()
        return nodeUpdates.contains(where: { currentResultIds.contains($0.id) })
    }
}

private extension SearchChipEntity.NodeType {
    func toNodeTypeEntity() -> NodeTypeEntity {
        switch self {
        case .unknown:  .unknown
        case .file:     .file
        case .folder:   .folder
        case .root:     .root
        case .incoming: .incoming
        case .rubbish:  .rubbish
        }
    }
}

extension SearchChipEntity.NodeFormat {
    func toNodeFormatEntity() -> NodeFormatEntity {
        switch self {
        case .unknown:      .unknown
        case .photo:        .photo
        case .audio:        .audio
        case .video:        .video
        case .document:     .document
        case .pdf:          .pdf
        case .presentation: .presentation
        case .archive:      .archive
        case .program:      .program
        case .misc:         .misc
        case .spreadsheet:  .spreadsheet
        case .allDocs:      .allDocs
        }
    }
}

extension SearchChipEntity.TimeFrame {
    func toSearchFilterTimeFrame() -> SearchFilterEntity.TimeFrame {
        SearchFilterEntity.TimeFrame(startDate: startDate, endDate: endDate)
    }
}
