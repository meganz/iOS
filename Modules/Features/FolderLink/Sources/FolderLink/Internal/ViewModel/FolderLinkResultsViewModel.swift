import Combine
import MEGADomain
import MEGAL10n
import MEGAUIComponent
import MEGAUIKit
import Search
import SwiftUI

@MainActor
final class FolderLinkResultsViewModel: ObservableObject {
    struct Dependency {
        let nodeHandle: HandleEntity
        let searchResultMapper: any FolderLinkSearchResultMapperProtocol
        let titleUseCase: any FolderLinkTitleUseCaseProtocol
        let viewModeUseCase: any FolderLinkViewModeUseCaseProtocol
        let isCloudDriveRevampEnabled: Bool
    }

    @Published var searchText: String = ""
    @Published var selection: SearchResultSelection?
    
    // IOS-11084 - handle edit mode
    var title: String {
        switch dependency.titleUseCase.title(for: dependency.nodeHandle) {
        case let .named(value):
            value
        case .file:
            Strings.Localizable.SharedItems.Tab.Recents.undecryptedFileName(1)
        case .folder:
            Strings.Localizable.SharedItems.Tab.Incoming.undecryptedFolderName
        case .unknown:
            Strings.Localizable.folderLink
        }
    }
    
    var subtitle: String {
        Strings.Localizable.folderLink
    }
    
    private let dependency: FolderLinkResultsViewModel.Dependency
    
    init(dependency: FolderLinkResultsViewModel.Dependency) {
        self.dependency = dependency
    }
}

extension FolderLinkResultsViewModel {
    var searchResultsContainerViewModel: SearchResultsContainerViewModel {
        let searchBridge = SearchBridge { [weak self] selection in
            self?.selection = selection
        } context: { result, _ in
            print(result)
        } chipTapped: { chip, selected in
            print(chip, selected)
        } sortingOrder: {
            print("sortingOrder")
            return SortOrder(key: .name)
        } updateSortOrder: { sortOrder in
            print(sortOrder)
        } chipPickerShowedHandler: { searchChipEntity in
            print(searchChipEntity)
        }
        let searchResultsProvider = FolderLinkSearchResultsProvider(
            nodeHandle: dependency.nodeHandle,
            folderSearchResultMapper: dependency.searchResultMapper
        )
        
        let searchConfig = SearchConfig.folderLink(dependency.isCloudDriveRevampEnabled)
        let initialViewMode = dependency.viewModeUseCase.viewModeForOpeningFolder(dependency.nodeHandle)
        
        let searchResultsViewModel = SearchResultsViewModel(
            resultsProvider: searchResultsProvider,
            bridge: searchBridge,
            config: searchConfig,
            layout: initialViewMode == .grid ? .thumbnail : .list,
            keyboardVisibilityHandler: KeyboardVisibilityHandler(notificationCenter: .default),
            viewDisplayMode: .folderLink,
            listHeaderViewModel: nil,
            isSelectionEnabled: true,
            usesRevampedLayout: dependency.isCloudDriveRevampEnabled, 
            contentUnavailableViewModelProvider: FolderLinkContentUnavailableProvider()
        )
        
        return SearchResultsContainerViewModel(
            bridge: searchBridge,
            config: searchConfig,
            searchResultsViewModel: searchResultsViewModel,
            sortOptionsViewModel: SortOptionsViewModel.folderLink,
            headerType: .none, // should be different value, IOS-11091
            initialViewMode: initialViewMode,
            shouldShowMediaDiscoveryModeHandler: { false }, // IOS-11103
            sortHeaderViewPressedEvent: { } // IOS-11083
        )
    }
}
