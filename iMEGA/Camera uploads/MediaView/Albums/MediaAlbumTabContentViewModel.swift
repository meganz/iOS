import Combine
import ContentLibraries
import MEGAAssets
import MEGADomain
import MEGAL10n
import SwiftUI

@MainActor
final class MediaAlbumTabContentViewModel: ObservableObject, MediaTabContentViewModel, MediaTabSharedResourceConsumer, MediaTabContextMenuActionHandler {
    weak var sharedResourceProvider: (any MediaTabSharedResourceProvider)?
    let editModeToggleRequested = PassthroughSubject<Void, Never>()
    let albumListViewModel: AlbumListViewModel
    let albumListViewRouter: any AlbumListViewRouting
    
    init(
        albumListViewModel: AlbumListViewModel,
        albumListViewRouter: some AlbumListViewRouting
    ) {
        self.albumListViewModel = albumListViewModel
        self.albumListViewRouter = albumListViewRouter
    }
}

extension MediaAlbumTabContentViewModel: MediaTabNavigationBarItemProvider {
    var navigationBarUpdatePublisher: AnyPublisher<Void, Never>? {
        albumListViewModel.$albums
            .map { $0.contains(where: { $0.type == .user }) }
            .removeDuplicates()
            .dropFirst()
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    func navigationBarItems(for editMode: EditMode) -> [NavigationBarItemViewModel] {
        var items: [NavigationBarItemViewModel] = []
        
        if editMode == .active {
            items.append(MediaNavigationBarItemFactory.cancelButton(action: toggleEditMode))
        } else {
            if let cameraUploadStatusButtonViewModel = sharedResourceProvider?.cameraUploadStatusButtonViewModel {
                items.append(MediaNavigationBarItemFactory.cameraUploadStatusButton(
                    viewModel: cameraUploadStatusButtonViewModel
                ))
            }
            items.append(MediaNavigationBarItemFactory.searchButton {
                
            })
            if albumListViewModel.albums.contains(where: { $0.type == .user }) {
                items.append(.init(
                    id: "select",
                    placement: .trailing,
                    type: .imageButton(image: MEGAAssets.UIImage.selectAllItems, action: toggleEditMode))
                )
            }
        }
        
        return items
    }
    
    private func toggleEditMode() {
        albumListViewModel.selection.toggleEditMode()
        editModeToggleRequested.send()
    }
}

extension MediaAlbumTabContentViewModel: MediaTabNavigationTitleProvider {
    var titleUpdatePublisher: AnyPublisher<String, Never> {
        let inactiveEditModeTitle = Strings.Localizable.Photos.SearchResults.Media.Section.title
        guard let sharedResourceProvider else {
            return Just(inactiveEditModeTitle).eraseToAnyPublisher()
        }
        
        return sharedResourceProvider.selectionTitlePublisher(
            selectionCountPublisher: albumListViewModel.selection.selectionCount,
            inactiveEditModeTitle: inactiveEditModeTitle)
    }
}
