import Combine
import MEGADomain
import MEGAL10n
import MEGAUIComponent
import Search
import SwiftUI

/// A view model that acts as a bridge
/// between the Folder Link module and `MediaDiscoveryContentView`.
///
/// - Folder Link → `MediaDiscoveryContentView`: exposes the public properties needed to create and update `MediaDiscoveryContentView`.
/// - `MediaDiscoveryContentView` → Folder Link: exposes public functions that allow `MediaDiscoveryContentView` to send actions back to the Folder Link module.
///
/// Since `MediaDiscoveryContentView` is still part of the main target
///
/// Once `MediaDiscoveryContentView` is moved into a separate Swift package, this view model can be made
/// internal to the Folder Link module.
@MainActor
public final class FolderLinkMediaDiscoveryViewModel: ObservableObject {
    package struct Dependency {
        let handle: HandleEntity
        let link: String
        let titleUseCase: any FolderLinkTitleUseCaseProtocol
        let trackingUseCase: any FolderLinkTrackingUseCaseProtocol
        let editModeUseCase: any FolderLinkEditModeUseCaseProtocol
        let bottomBarUseCase: any FolderLinkBottomBarUseCaseProtocol
        let quickActionUseCase: any FolderLinkQuickActionUseCaseProtocol

        package init(
            handle: HandleEntity,
            link: String,
            titleUseCase: some FolderLinkTitleUseCaseProtocol,
            trackingUseCase: some FolderLinkTrackingUseCaseProtocol,
            editModeUseCase: some FolderLinkEditModeUseCaseProtocol,
            bottomBarUseCase: some FolderLinkBottomBarUseCaseProtocol,
            quickActionUseCase: some FolderLinkQuickActionUseCaseProtocol
        ) {
            self.handle = handle
            self.link = link
            self.titleUseCase = titleUseCase
            self.trackingUseCase = trackingUseCase
            self.editModeUseCase = editModeUseCase
            self.bottomBarUseCase = bottomBarUseCase
            self.quickActionUseCase = quickActionUseCase
        }

        init(handle: HandleEntity, link: String) {
            self.init(
                handle: handle,
                link: link,
                titleUseCase: FolderLinkTitleUseCase(),
                trackingUseCase: FolderLinkTrackingUseCase(),
                editModeUseCase: FolderLinkEditModeUseCase(),
                bottomBarUseCase: FolderLinkBottomBarUseCase(),
                quickActionUseCase: FolderLinkQuickActionUseCase()
            )
        }
    }
    
    public var nodeHandle: HandleEntity {
        dependency.handle
    }
    
    // MARK: - To send updates to external: Folder Link → `MediaDiscoveryContentView`
    @Published public var sortOrder: MEGAUIComponent.SortOrder = SortOrder(key: .lastModified, direction: .descending)
    @Published public var editMode: EditMode = .inactive
    @Published public var selectAll: Bool = false
    
    // Properties for FolderLinkMediaDiscoveryView
    @Published package var selectedPhotos: [NodeEntity] = []
    @Published package var title: String = ""
    @Published package var subtitle: String?
    @Published package var bottomBarDisabled: Bool = true
    @Published package var shouldShowBottomBar: Bool = false
    @Published package var shouldIncludeSaveToPhotosBottomAction: Bool = false
    @Published package var quickAction: FolderLinkQuickAction?
    @Published package var bottomBarAction: FolderLinkBottomBarAction?
    @Published package var nodesAction: FolderLinkNodesAction?
    @Binding package var viewMode: SearchResultsViewMode
    package let viewModeViewModel: SearchResultsHeaderViewModeViewModel

    var shouldEnableMoreOptionsMenu: Bool {
        dependency.editModeUseCase.canEnterEditModeWhenOpeningFolder(dependency.handle)
    }

    var shouldShowQuickActionsMenu: Bool {
        dependency.quickActionUseCase.shouldEnableQuickActions(for: dependency.handle)
    }

    private var subscriptions: Set<AnyCancellable> = []
    private let dependency: Dependency
    
    package init(
        dependency: Dependency,
        viewMode: Binding<SearchResultsViewMode>
    ) {
        self.dependency = dependency
        self._viewMode = viewMode
        self.viewModeViewModel = SearchResultsHeaderViewModeViewModel(
            selectedViewMode: .mediaDiscovery,
            availableViewModes: [.list, .grid, .mediaDiscovery]
        )
        
        viewModeViewModel
            .$selectedViewMode
            .dropFirst()
            .filter { $0 != .mediaDiscovery }
            .sink { [weak self] in
                self?.viewMode = $0
            }
            .store(in: &subscriptions)
        
        $selectedPhotos
            .combineLatest($editMode)
            .map { [dependency] nodes, editMode in
                dependency.titleUseCase.title(
                    for: dependency.handle,
                    editingState: editMode.isEditing ? .active(nodes) : .inactive
                )
            }
            .sink { [weak self] type in
                switch type {
                case .askForSelecting:
                    self?.title = Strings.Localizable.selectTitle
                    self?.subtitle = nil
                case let .folderNodeName(name):
                    self?.title = name
                    self?.subtitle = Strings.Localizable.folderLink
                case let .selectedItems(count):
                    self?.title = Strings.Localizable.General.Format.itemsSelected(count)
                    self?.subtitle = nil
                case .undecryptedFolder:
                    self?.title = Strings.Localizable.SharedItems.Tab.Incoming.undecryptedFolderName
                    self?.subtitle = Strings.Localizable.folderLink
                case .generic:
                    self?.title = Strings.Localizable.folderLink
                    self?.subtitle = nil
                }
            }
            .store(in: &subscriptions)
        
        $editMode
            .map { $0.isEditing }
            .assign(to: &$shouldShowBottomBar)

        // Browsing drives the anchored buttons, which act on the folder itself, so the disabled state is
        // no longer computed for the editing state alone.
        $selectedPhotos
            .combineLatest($editMode)
            .map { photos, editMode in
                dependency.bottomBarUseCase.shouldDisableBottomBar(
                    handle: dependency.handle,
                    editingState: editMode.isEditing ? .active(photos) : .inactive
                )
            }
            .assign(to: &$bottomBarDisabled)

        $selectedPhotos
            .combineLatest($editMode)
            .map { photos, editMode in
                dependency.bottomBarUseCase.shouldIncludeSaveToPhotosAction(
                    handle: dependency.handle,
                    editingState: editMode.isEditing ? .active(Set(photos.map(\.handle))) : .inactive
                )
            }
            .assign(to: &$shouldIncludeSaveToPhotosBottomAction)

        // The more options sheet acts on the folder rather than on a selection, so unlike the bottom bar
        // actions these always carry the folder's own handle.
        $quickAction
            .compactMap { $0 }
            .map { action in
                switch action {
                case .addToCloudDrive:
                    FolderLinkNodesAction.addToCloudDrive([dependency.handle])
                case .makeAvailableOffline:
                    FolderLinkNodesAction.makeAvailableOffline([dependency.handle])
                case .sendToChat:
                    FolderLinkNodesAction.sendToChat(dependency.link)
                }
            }
            .assign(to: &$nodesAction)

        $bottomBarAction
            .compactMap { $0 }
            .compactMap { [weak self] action in
                guard let self else { return nil }
                // Browsing has no selection: the anchored buttons and the sheet act on the folder itself.
                let nodes = editMode.isEditing ? Set(selectedPhotos.map(\.handle)) : [dependency.handle]
                return switch action {
                case .addToCloudDrive:
                    FolderLinkNodesAction.addToCloudDrive(nodes)
                case .makeAvailableOffline:
                    FolderLinkNodesAction.makeAvailableOffline(nodes)
                case .downloadToFiles:
                    FolderLinkNodesAction.downloadToFiles(nodes)
                case .saveToPhotos:
                    // While browsing, this hands Save to Photos the folder itself rather than the media
                    // inside it, and `SaveMediaToPhotosUseCase` downloads whatever it is given as a file
                    // instead of walking the tree — so the sheet's Download row does nothing for a folder.
                    // The list/grid screen maps it the same way, and IOS-11735 reworks Download for
                    // folders (download the tree, then archive it on device), so this is left to that
                    // ticket rather than fixed for gallery mode alone and split from list/grid.
                    FolderLinkNodesAction.saveToPhotos(nodes)
                }
            }
            .assign(to: &$nodesAction)
        
        $nodesAction
            .compactMap { $0 }
            .sink { [weak self] _ in
                self?.editMode = .inactive
            }
            .store(in: &subscriptions)
        
        $sortOrder
            .dropFirst()
            .sink { order in
                dependency.trackingUseCase.trackSortOrderChanged(order)
            }
            .store(in: &subscriptions)
    }
    
    package func toggleSelectAll() {
        selectAll.toggle()
    }
    
    package func sortHeaderPressed() {
        dependency.trackingUseCase.trackSortHeaderPressed()
    }
    
    // MARK: To receive updates from external: `MediaDiscoveryContentView` → Folder Link
    public func updateSelectedPhotos(_ photos: [NodeEntity]) {
        self.selectedPhotos = photos
    }
}

// MARK: - FolderLinkMoreOptionsHandling

extension FolderLinkMediaDiscoveryViewModel: FolderLinkMoreOptionsHandling {}
