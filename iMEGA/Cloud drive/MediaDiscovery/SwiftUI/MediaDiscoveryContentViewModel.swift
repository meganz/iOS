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

@MainActor
final class MediaDiscoveryContentViewModel: ObservableObject {
    @Published var showAutoMediaDiscoveryBanner = false
    @Published private(set) var viewState: MediaDiscoveryContentViewState = .normal
    let photoLibraryContentViewModel: PhotoLibraryContentViewModel
    let photoLibraryContentViewRouter: PhotoLibraryContentViewRouter
    
    var editMode: EditMode {
        get { photoLibraryContentViewModel.selection.editMode }
        set { photoLibraryContentViewModel.selection.editMode = newValue }
    }
    
    @PreferenceWrapper(key: .autoMediaDiscoveryBannerDismissed, defaultValue: false)
    var autoMediaDiscoveryBannerDismissed: Bool
    
    private let parentNodeProvider: () -> NodeEntity?
    private var sortOrder: SortOrderType
    private let analyticsUseCase: any MediaDiscoveryAnalyticsUseCaseProtocol
    private let mediaDiscoveryUseCase: any MediaDiscoveryUseCaseProtocol
    private let contentConsumptionUserAttributeUseCase: any ContentConsumptionUserAttributeUseCaseProtocol
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private lazy var pageStayTimeTracker = PageStayTimeTracker()
    private var subscriptions = Set<AnyCancellable>()
    private weak var delegate: (any MediaDiscoveryContentDelegate)?
    @PreferenceWrapper(key: .mediaDiscoveryShouldIncludeSubfolderMedia, defaultValue: true)
    private var shouldIncludeSubfolderMedia: Bool
    
    init(contentMode: PhotoLibraryContentMode,
         parentNodeProvider: @escaping () -> NodeEntity?,
         sortOrder: SortOrderType,
         isAutomaticallyShown: Bool,
         delegate: (some MediaDiscoveryContentDelegate)?,
         analyticsUseCase: some MediaDiscoveryAnalyticsUseCaseProtocol,
         mediaDiscoveryUseCase: some MediaDiscoveryUseCaseProtocol,
         contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol,
         preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider) {
        
        photoLibraryContentViewModel = PhotoLibraryContentViewModel(library: PhotoLibrary(), contentMode: contentMode)
        photoLibraryContentViewRouter = PhotoLibraryContentViewRouter(contentMode: contentMode)
        
        self.parentNodeProvider = parentNodeProvider
        self.delegate = delegate
        self.analyticsUseCase = analyticsUseCase
        self.mediaDiscoveryUseCase = mediaDiscoveryUseCase
        self.contentConsumptionUserAttributeUseCase = contentConsumptionUserAttributeUseCase
        self.sortOrder = sortOrder
        self.featureFlagProvider = featureFlagProvider
        $shouldIncludeSubfolderMedia.useCase = preferenceUseCase
        $autoMediaDiscoveryBannerDismissed.useCase = preferenceUseCase
        
        if isAutomaticallyShown {
            showAutoMediaDiscoveryBanner = !autoMediaDiscoveryBannerDismissed
        }
    }
    
    @MainActor
    func loadPhotos() async {
        guard let parentNode = parentNodeProvider() else {
            viewState = .empty
            return
        }
        do {
            viewState = .normal
            try Task.checkCancellation()
            let shouldExcludeSensitiveItems = await shouldExcludeSensitiveItems()
            MEGALogDebug("[Search] load photos and videos in parent: \(parentNode.base64Handle), recursive: \(shouldIncludeSubfolderMedia), exclude sensitive \(shouldExcludeSensitiveItems)")
            let nodes = try await mediaDiscoveryUseCase.nodes(
                forParent: parentNode,
                recursive: shouldIncludeSubfolderMedia,
                excludeSensitive: shouldExcludeSensitiveItems)
            try Task.checkCancellation()
            MEGALogDebug("[Search] nodes loaded \(nodes.count)")
            photoLibraryContentViewModel.library = await sortIntoPhotoLibrary(nodes: nodes, sortOrder: sortOrder)
            try Task.checkCancellation()
            viewState = nodes.isEmpty ? .empty : .normal
        } catch {
            MEGALogError("[Search] Error loading nodes: \(error.localizedDescription)")
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
        subscribeToSelectionChanges()
        subscribeToNodeChanges()
        startTracking()
        analyticsUseCase.sendPageVisitedStats()
    }
    
    func onViewDisappear() {
        // AnyCancellable are cancelled on dealloc so need to do it here
        subscriptions.removeAll()
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
                
                guard
                    let parentNode = parentNodeProvider(),
                    mediaDiscoveryUseCase.shouldReload(
                        parentNode: parentNode,
                        loadedNodes: nodes,
                        updatedNodes: updatedNodes
                    )
                else {
                    return
                }
                
                Task { await self.loadPhotos() }
            }.store(in: &subscriptions)
    }
    
    private func shouldExcludeSensitiveItems() async -> Bool {
        if featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes), 
            [.mediaDiscovery].contains(photoLibraryContentViewModel.contentMode) {
            await contentConsumptionUserAttributeUseCase.fetchSensitiveAttribute().showHiddenNodes == false
        } else {
            false
        }
    }
}
