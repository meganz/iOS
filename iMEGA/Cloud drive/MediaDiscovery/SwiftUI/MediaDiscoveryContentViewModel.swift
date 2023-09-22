import Combine
import Foundation
import MEGADomain
import MEGAFoundation
import MEGAPresentation
import SwiftUI

protocol MediaDiscoveryContentDelegate: AnyObject {
    
    /// This delegate function will be triggered when a change to the currently selected media nodes for this media discovery list  occurs.
    /// When a selection change occurs, this delegate will return the current selected node entities and the a list of all the node entities.
    /// - Parameters:
    ///   - selected: returns currently selected [NodeEntities]
    ///   - allPhotos: returns list of all nodes loaded in this feature
    func selectedPhotos(selected: [NodeEntity], allPhotos: [NodeEntity])
    
    /// This delegate function will get triggered when the ability to enter edit mode/ to be able to select nodes in Media Discovery changes.
    ///  Follow this trigger, to determine the availability to enter multi-select/edit mode.
    ///  This event should be triggered if either zoomLevelChange affects its ability to select or selectedMode has changed.
    /// - Parameter isHidden: Bool value to determine if selection action should be hidden
    func isMediaDiscoverySelection(isHidden: Bool)
    
    /// This delegate function triggered only when in the Empty State of the view. And when a menu action has been triggered.
    /// This is called immediately on tapping of menu action
    /// - Parameter menuAction: The tapped menu action
    func mediaDiscoverEmptyTapped(menuAction: EmptyMediaDiscoveryContentMenuAction)
}

enum MediaDiscoveryContentViewState {
    case normal
    case empty
}

final class MediaDiscoveryContentViewModel: ObservableObject {
    
    @Published private(set) var viewState: MediaDiscoveryContentViewState = .normal
    let photoLibraryContentViewModel: PhotoLibraryContentViewModel
    let photoLibraryContentViewRouter: PhotoLibraryContentViewRouter
    
    var editMode: EditMode {
        get { photoLibraryContentViewModel.selection.editMode }
        set { photoLibraryContentViewModel.selection.editMode = newValue }
    }
        
    private let parentNode: NodeEntity
    private var sortOrder: SortOrderType
    private let analyticsUseCase: any MediaDiscoveryAnalyticsUseCaseProtocol
    private let mediaDiscoveryUseCase: any MediaDiscoveryUseCaseProtocol
    private lazy var pageStayTimeTracker = PageStayTimeTracker()
    private var subscriptions = Set<AnyCancellable>()
    private weak var delegate: (any MediaDiscoveryContentDelegate)?
    
    init(contentMode: PhotoLibraryContentMode,
         parentNode: NodeEntity,
         sortOrder: SortOrderType,
         delegate: (some MediaDiscoveryContentDelegate)?,
         analyticsUseCase: some MediaDiscoveryAnalyticsUseCaseProtocol,
         mediaDiscoveryUseCase: some MediaDiscoveryUseCaseProtocol) {
        
        photoLibraryContentViewModel = PhotoLibraryContentViewModel(library: PhotoLibrary(), contentMode: contentMode)
        photoLibraryContentViewRouter = PhotoLibraryContentViewRouter(contentMode: contentMode)
        
        self.parentNode = parentNode
        self.delegate = delegate
        self.analyticsUseCase = analyticsUseCase
        self.mediaDiscoveryUseCase = mediaDiscoveryUseCase
        self.sortOrder = sortOrder
        
        subscribeToSelectionChanges()
        subscribeToNodeChanges()
    }
    
    @MainActor
    func loadPhotos() async {
        do {
            viewState = .normal
            try Task.checkCancellation()
            let nodes = try await mediaDiscoveryUseCase.nodes(forParent: parentNode)
            try Task.checkCancellation()
            photoLibraryContentViewModel.library = await sortIntoPhotoLibrary(nodes: nodes, sortOrder: sortOrder)
            try Task.checkCancellation()
            viewState = nodes.isEmpty ? .empty : .normal
        } catch {
            MEGALogError("Error loading nodes: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func update(sortOrder updatedSortOrder: SortOrderType) async {
        guard updatedSortOrder != sortOrder else {
            return
        }
        
        self.sortOrder = updatedSortOrder
        let nodes = photoLibraryContentViewModel.library.allPhotos
        photoLibraryContentViewModel.library = await sortIntoPhotoLibrary(nodes: nodes, sortOrder: sortOrder)
    }
    
    func onViewAppear() {
        startTracking()
        analyticsUseCase.sendPageVisitedStats()
    }
    
    func onViewDisappear() {
        endTracking()
        sendPageStayStats()
    }
    
    func toggleAllSelected() {
        photoLibraryContentViewModel.toggleSelectAllPhotos()
    }
    
    func tapped(menuAction: EmptyMediaDiscoveryContentMenuAction) {
        delegate?.mediaDiscoverEmptyTapped(menuAction: menuAction)
    }
    
    private func sortIntoPhotoLibrary(nodes: [NodeEntity], sortOrder: SortOrderType) async -> PhotoLibrary {
        nodes.toPhotoLibrary(withSortType: sortOrder)
    }
    
    private func startTracking() {
        pageStayTimeTracker.start()
    }
    
    private func endTracking() {
        pageStayTimeTracker.end()
    }
    
    private func sendPageStayStats() {
        let duration = Int(pageStayTimeTracker.duration)
        analyticsUseCase.sendPageStayStats(with: duration)
    }
    
    private func subscribeToSelectionChanges() {
        
        photoLibraryContentViewModel
            .$library
            .map(\.allPhotos)
            .combineLatest(photoLibraryContentViewModel.selection.$photos)
            .receive(on: DispatchQueue.main)
            .sink { [weak delegate] allPhotos, selectedPhotos in
                delegate?.selectedPhotos(selected: selectedPhotos.map(\.value), allPhotos: allPhotos)
            }
            .store(in: &subscriptions)
        
        photoLibraryContentViewModel.$selectedMode
            .combineLatest(photoLibraryContentViewModel.selection.$isHidden)
            .map { selectedMode, selectionIsHidden -> Bool in
                selectedMode != .all || selectionIsHidden
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak delegate] in delegate?.isMediaDiscoverySelection(isHidden: $0) }
            .store(in: &subscriptions)
    }
    
    private func subscribeToNodeChanges() {
        
        mediaDiscoveryUseCase
            .nodeUpdatesPublisher
            .debounce(for: .seconds(0.35), scheduler: DispatchQueue.global())
            .sink { [weak self] updatedNodes in
                guard let self else { return }
                
                let nodes = photoLibraryContentViewModel.library.allPhotos
                
                guard mediaDiscoveryUseCase.shouldReload(parentNode: parentNode, loadedNodes: nodes, updatedNodes: updatedNodes) else {
                    return
                }
                
                Task { await self.loadPhotos() }
            }.store(in: &subscriptions)
    }
}
