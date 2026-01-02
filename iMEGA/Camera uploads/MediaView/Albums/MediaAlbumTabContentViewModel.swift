import Combine
import ContentLibraries
import MEGAAppPresentation
import MEGAAssets
import MEGADomain
import MEGAL10n
import SwiftUI

@MainActor
final class MediaAlbumTabContentViewModel: ObservableObject, MediaTabContentViewModel, MediaTabSharedResourceConsumer, MediaTabContextMenuActionHandler {
    weak var sharedResourceProvider: (any MediaTabSharedResourceProvider)? {
        didSet {
            setupParentEditModeSubscription()
        }
    }
    let editModeToggleRequested = PassthroughSubject<Void, Never>()
    let albumListViewModel: AlbumListViewModel
    let albumListViewRouter: any AlbumListViewRouting
    
    private var subscriptions = Set<AnyCancellable>()
    var toolbarCoordinator: (any MediaTabToolbarCoordinatorProtocol)?
    private var lastKnownEditMode: EditMode

    init(
        albumListViewModel: AlbumListViewModel,
        albumListViewRouter: some AlbumListViewRouting
    ) {
        self.albumListViewModel = albumListViewModel
        self.albumListViewRouter = albumListViewRouter
        self.lastKnownEditMode = albumListViewModel.selection.editMode
        subscribeToAlbumSelectionEditMode()
    }
    
    private func subscribeToAlbumSelectionEditMode() {
        albumListViewModel.selection.$editMode
            .dropFirst()
            .sink { [weak self] newMode in
                guard let self else { return }
                // Only notify parent if the mode actually changed from what we last knew
                guard newMode != self.lastKnownEditMode else { return }
                self.lastKnownEditMode = newMode
                self.editModeToggleRequested.send()
            }
            .store(in: &subscriptions)
    }

    private func setupParentEditModeSubscription() {
        guard let sharedResourceProvider else { return }

        sharedResourceProvider.editModePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mode in
                guard let self else { return }
                // Update our tracking variable before setting the value
                self.lastKnownEditMode = mode
                self.albumListViewModel.selection.editMode = mode
            }
            .store(in: &subscriptions)
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

extension MediaAlbumTabContentViewModel: MediaTabToolbarActionsProvider {
    var toolbarUpdatePublisher: AnyPublisher<Void, Never>? {
        albumListViewModel.selection.selectionTransition
            .dropFirst()
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    func toolbarConfig() -> MediaBottomToolbarConfig? {
        let selectedAlbums = albumListViewModel.selection.albums.values
        let selectedCount = selectedAlbums.count
        
        let exportedAlbums = selectedAlbums.filter {
            if case .exported(let isExported) = $0.sharedLinkStatus {
                return isExported
            }
            return false
        }
        let isAllExported = selectedCount > 0 && exportedAlbums.count == selectedCount
        
        var actions: [MediaBottomToolbarAction] = [.manageLink, .delete]
        if isAllExported {
            actions.insert(.removeLink, at: 1)
        }
        
        return MediaBottomToolbarConfig(
            actions: actions,
            selectedItemsCount: selectedCount,
            isAllExported: isAllExported
        )
    }
}

extension MediaAlbumTabContentViewModel: MediaTabToolbarActionHandler {
    func handleToolbarAction(_ action: MediaBottomToolbarAction) {
        switch action {
        case .manageLink: albumListViewModel.shareLinksTapped()
        case .removeLink: albumListViewModel.removeLinksTapped()
        case .delete: albumListViewModel.deleteAlbumsTapped()
        default: break
        }
    }
}
