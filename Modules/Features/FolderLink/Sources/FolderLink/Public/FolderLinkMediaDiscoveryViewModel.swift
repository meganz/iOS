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
        let titleUseCase: any FolderLinkTitleUseCaseProtocol
        let trackingUseCase: any FolderLinkTrackingUseCaseProtocol
        
        package init(
            handle: HandleEntity,
            titleUseCase: some FolderLinkTitleUseCaseProtocol,
            trackingUseCase: some FolderLinkTrackingUseCaseProtocol
        ) {
            self.handle = handle
            self.titleUseCase = titleUseCase
            self.trackingUseCase = trackingUseCase
        }
        
        init(handle: HandleEntity) {
            self.init(
                handle: handle,
                titleUseCase: FolderLinkTitleUseCase(),
                trackingUseCase: FolderLinkTrackingUseCase()
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
    @Published package var bottomBarDisabled: Bool = false
    @Published package var shouldShowBottomBar: Bool = false
    @Published var shouldEnableMoreOptionsMenu: Bool = true
    @Published package var bottomBarAction: FolderLinkBottomBarAction?
    @Published package var nodesAction: FolderLinkNodesAction?
    @Binding package var viewMode: SearchResultsViewMode
    package let viewModeViewModel: SearchResultsHeaderViewModeViewModel
    
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
        
        $shouldShowBottomBar
            .filter { $0 }
            .combineLatest($selectedPhotos)
            .map { _, photos in
                photos.isEmpty
            }
            .assign(to: &$bottomBarDisabled)
        
        $bottomBarAction
            .compactMap { $0 }
            .compactMap { [weak self] action in
                guard let self else { return nil }
                let nodes = Set(selectedPhotos.map(\.handle))
                return switch action {
                case .addToCloudDrive:
                    FolderLinkNodesAction.addToCloudDrive(nodes)
                case .makeAvailableOffline:
                    FolderLinkNodesAction.makeAvailableOffline(nodes)
                case .saveToPhotos:
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
