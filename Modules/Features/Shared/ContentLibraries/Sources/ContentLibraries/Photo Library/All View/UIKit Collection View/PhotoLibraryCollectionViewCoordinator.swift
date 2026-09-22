import Combine
import Foundation
import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
import MEGAUIComponent
import SwiftUI
import UIKit

enum PhotoLibrarySupplementaryElementKind: String {
    case photoDateSectionHeader = "photo-date-section-header-kind"
    case layoutHeaderEnableCameraUploads = "layout-header-enable-camera-uploads-kind"
    case layoutHeaderLimitedPermissions = "layout-header-limited-permissions-kind"
    case layoutSortHeader = "layout-sort-header"
    case globalZoomHeader = "global-zoom-header-kind"
    
    var elementKind: String { rawValue }
    static var globalHeaderHeight: CGFloat { 44 }
    
    var zPosition: CGFloat {
        switch self {
        case .layoutHeaderEnableCameraUploads, .layoutHeaderLimitedPermissions: 4
        case .globalZoomHeader: 3
        case .photoDateSectionHeader, .layoutSortHeader: 2
        }
    }
    
    static func layoutHeader(for bannerType: PhotoLibraryBannerType?) -> PhotoLibrarySupplementaryElementKind? {
        guard let bannerType else { return nil }
        switch bannerType {
        case .enableCameraUploads:
            return .layoutHeaderEnableCameraUploads
        case .limitedPermissions:
            return .layoutHeaderLimitedPermissions
        }
    }
}

@MainActor
final class PhotoLibraryCollectionViewCoordinator: NSObject {
    private var router: any PhotoLibraryContentViewRouting { representer.router }
    private let representer: PhotoLibraryCollectionViewRepresenter
    private var collectionView: UICollectionView?
    private var headerRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewCell>!
    private var enableCameraUploadsBannerRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewCell>!
    private var limitedPermissionsBannerRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewCell>!
    private var globalZoomHeaderRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewCell>!
    private var sortHeaderRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewCell>!
    private var photoCellRegistration: UICollectionView.CellRegistration<PhotoLibraryCollectionCell, NodeEntity>!
    private typealias PhotoLibraryEnableCameraUploadCollectionCell = UICollectionViewCell
    private let layoutChangesMonitor: PhotoLibraryCollectionViewLayoutChangesMonitor
    private var scrollTracker: PhotoLibraryCollectionViewScrollTracker!
    private var currentVisibleMonthTitle: String = ""
    private weak var globalHeaderView: UICollectionViewCell?
    private var visibleSectionHeaders: Set<Int> = []
    private var subscriptions = Set<AnyCancellable>()
    private weak var dragSelectionPanGesture: UIPanGestureRecognizer?
    private weak var longPressGesture: UILongPressGestureRecognizer?

    private var dragInitialIndexPath: IndexPath?
    private var dragLastIndexPath: IndexPath?
    private var dragSelectionMode: DragSelectionMode?
    private var initialSelectionHandles: Set<HandleEntity> = []
    /// The layout the running drag reads index paths against, and the handler's record of what it
    /// started from. Both live for one gesture only.
    private var dragLayoutVersion: Int?
    private var dragSelectionGestureToken: SelectionGestureToken?

    private var autoScrollDisplayLink: CADisplayLink?
    private var autoScrollVelocity: CGFloat = 0

    // Top zone is 80pt because the pinned global zoom header (44pt) overlaps the upper part,
    // leaving ~36pt of effective cell-area trigger. Bottom has no equivalent overlay and instead
    // sits above an empty inset region (contentInset.bottom + toolbar safeArea), so a narrower
    // 40pt zone keeps the perceived trigger comparable to the top.
    private static let autoScrollTopEdgeZone: CGFloat = 80
    private static let autoScrollBottomEdgeZone: CGFloat = 40
    private static let autoScrollMaxVelocity: CGFloat = 1200 // pt/s, frame-rate independent

    private enum DragSelectionMode {
        case select
        case deselect
    }

    private var photoLibraryDataSource: [PhotoDateSection] {
        layoutChangesMonitor.photoLibraryDataSource
    }
    
    private var viewModel: PhotoLibraryModeAllCollectionViewModel {
        representer.viewModel
    }

    /// Answers for placeholder cells, on the screens that have one.
    private var positionalSelectionHandler: (any PositionalSelectionHandling)? {
        viewModel.libraryViewModel.positionalSelectionHandler
    }

    /// Where an index path sits in the grid the user is looking at, version included: the same
    /// index means different photos on either side of a change.
    private func selectionPosition(at indexPath: IndexPath) -> SelectionPosition? {
        guard let flatIndex = photoLibraryDataSource.flatIndex(of: indexPath) else { return nil }
        return SelectionPosition(
            flatIndex: flatIndex, layoutVersion: layoutChangesMonitor.renderedLayoutVersion)
    }
    
    init(_ representer: PhotoLibraryCollectionViewRepresenter) {
        self.representer = representer
        layoutChangesMonitor = PhotoLibraryCollectionViewLayoutChangesMonitor(representer)
        super.init()
    }
    
    func configureDataSource(for collectionView: UICollectionView) {
        self.collectionView = collectionView
        
        headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewCell>(elementKind: PhotoLibrarySupplementaryElementKind.photoDateSectionHeader.elementKind) { [unowned self] header, _, indexPath in
            // First section is rendered as an empty placeholder only when the global header is
            // showing the date in its place. Whenever it is not (no global header at all, or a
            // sort header), the section must keep its own date label.
            let isFirstSection = representer.globalHeaderType.showsSectionDate
                && indexPath.section == 0

            // Disable interaction so pinned section headers don't intercept touches meant for the global zoom header above them.
            header.isUserInteractionEnabled = !representer.globalHeaderType.showsSectionDate
            let isAlbumRollback = representer.contentMode == .album && !AlbumLayoutGate.isMasonryLayoutEnabled
            header.contentConfiguration = UIHostingConfiguration {
                if isFirstSection {
                    EmptyView()
                } else {
                    PhotoSectionHeader(
                        section: photoLibraryDataSource[indexPath.section],
                        useLegacyStyle: isAlbumRollback
                    )
                }
            }
            .margins(.all, 0)
        }
        
        enableCameraUploadsBannerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewCell>(elementKind: PhotoLibrarySupplementaryElementKind.layoutHeaderEnableCameraUploads.elementKind) { [unowned self] header, _, _ in
            header.contentConfiguration = UIHostingConfiguration {
                EnableCameraUploadsBannerButtonView({ [weak self] in
                    guard let self else { return }
                    router.openCameraUploadSettings(viewModel: viewModel)
                }, closeButtonAction: viewModel.dismissEnableCameraUploadBanner)
                .determineViewSize { [weak self] size in
                    Task { @MainActor in
                        self?.viewModel.photoZoomControlPositionTracker.update(viewSpace: size.height)
                    }
                }
            }
            .margins(.all, 0)
        }
        
        limitedPermissionsBannerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewCell>(elementKind: PhotoLibrarySupplementaryElementKind.layoutHeaderLimitedPermissions.elementKind) { [unowned self] header, _, _ in
            header.contentConfiguration = UIHostingConfiguration {
                LimitedAccessBannerView { [weak self] in
                    self?.viewModel.dismissLimitedAccessBanner()
                }
                .determineViewSize { [weak self] size in
                    Task { @MainActor in
                        self?.viewModel.photoZoomControlPositionTracker.update(viewSpace: size.height)
                    }
                }
            }
            .margins(.all, 0)
        }
        
        globalZoomHeaderRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewCell>(elementKind: PhotoLibrarySupplementaryElementKind.globalZoomHeader.elementKind) { [unowned self] header, _, _ in
            self.globalHeaderView = header
            let title = currentVisibleMonthTitle.isEmpty ? (photoLibraryDataSource.first?.title ?? "") : currentVisibleMonthTitle
            header.contentConfiguration = createGlobalHeaderConfiguration(title: title)
        }
        
        photoCellRegistration = UICollectionView.CellRegistration { [unowned self] cell, indexPath, photo in
            let viewModel = PhotoCellViewModel(
                photo: photo,
                viewModel: viewModel,
                thumbnailLoader: ThumbnailLoaderFactory.makeThumbnailLoader(mode: representer.contentMode),
                sensitiveNodeUseCase: SensitiveNodeUseCaseFactory.makeSensitiveNodeUseCase(for: representer.contentMode),
                placeholderSelection: placeholderSelection(for: cell, configuredAt: indexPath)
            )
            cell.viewModel = viewModel
            
            cell.contentConfiguration = UIHostingConfiguration {
                PhotoCellContent(viewModel: viewModel, isSelfSizing: false)
            }
            .margins(.all, 0)
            
            cell.clipsToBounds = true
        }
        
        sortHeaderRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewCell>(
            elementKind: PhotoLibrarySupplementaryElementKind.layoutSortHeader.elementKind
        ) { [unowned self] header, _, _ in
            guard case let .sort(sortViewModel) = viewModel.libraryViewModel.sectionHeaderType else {
                header.contentConfiguration = nil
                return
            }
            header.contentConfiguration = UIHostingConfiguration {
                PhotoLibraryGlobalHeaderView {
                    SortHeaderViewWrapper(config: sortViewModel.config, sortOrder: sortViewModel.currentSortOrder(), handler: sortViewModel.onSortOrderChanged)
                }
            }
            .margins(.all, 0)
            .background(TokenColors.Background.page.swiftUI)
        }
        
        configureScrollTracker(for: collectionView)
        
        layoutChangesMonitor.configure(collectionView: collectionView)
        
        layoutChangesMonitor.onLayoutChange = { [weak self] in
            self?.refreshGlobalHeader()
        }
        
        subscribeToEditModeChanges()

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGesture.delegate = self
        dragSelectionPanGesture = panGesture
        collectionView.addGestureRecognizer(panGesture)

        // Long-press to enter selection. A UIKit recognizer (not a SwiftUI gesture in the hosting
        // cell) so it coexists with the scroll pan — moving the finger cancels the press and lets
        // the list scroll, instead of the cell swallowing the drag on iOS 17.
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture(_:)))
        longPress.delegate = self
        longPressGesture = longPress
        collectionView.addGestureRecognizer(longPress)

        collectionView.dataSource = self
        collectionView.delegate = self
    }

    @objc private func handleLongPressGesture(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let collectionView,
              !viewModel.isEditing else { return }
        let location = gesture.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: location),
              let photo = photoLibraryDataSource.photo(at: indexPath) else { return }
        // A placeholder is pressable only where a handler can answer for it; elsewhere the press
        // does nothing, as before. The cell decides what it means either way, so there is one path.
        guard !photo.isTimelinePlaceholder || positionalSelectionHandler != nil else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        (collectionView.cellForItem(at: indexPath) as? PhotoLibraryCollectionCell)?.viewModel.handleLongPress()
    }

    /// A placeholder cell's link to the handler, or nil on a screen that has none. The position
    /// comes from the cell's live index path, falling back to the one it was configured at — the
    /// right answer while the cell is still being built and has none yet.
    private func placeholderSelection(
        for cell: UICollectionViewCell, configuredAt indexPath: IndexPath
    ) -> PlaceholderCellSelection? {
        guard let handler = positionalSelectionHandler else { return nil }
        return PlaceholderCellSelection(handler: handler) { [weak self, weak cell] in
            guard let self else { return nil }
            let current = cell.flatMap { collectionView?.indexPath(for: $0) } ?? indexPath
            return selectionPosition(at: current)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        viewModel
            .photoZoomControlPositionTracker
            .trackContentOffset(scrollView.contentOffset.y)
    }
    
    private func createGlobalHeaderConfiguration(title: String) -> (any UIContentConfiguration)? {
        let globalHeaderType = representer.globalHeaderType
        guard globalHeaderType != .none else { return nil }
        
        return UIHostingConfiguration {
            switch globalHeaderType {
            case let .sortAndZoom(sortViewModel):
                PhotoLibraryGlobalHeaderView(
                    leftContent: {
                        SortHeaderViewWrapper(
                            config: sortViewModel.config,
                            sortOrder: sortViewModel.currentSortOrder(),
                            handler: sortViewModel.onSortOrderChanged
                        )
                    },
                    rightContent: {
                        ZoomMenuControlWrapper(
                            zoomState: Binding(
                                get: { self.viewModel.zoomState },
                                set: { self.viewModel.zoomState = $0 }
                            ),
                            isEditing: self.viewModel.isEditing
                        )
                        // The sort control brings its own leading inset; this matches it on the
                        // trailing side so the zoom button sits where the date header puts it.
                        .padding(.trailing, TokenSpacing._5)
                    }
                )
            case .dateAndZoom:
                PhotoLibraryGlobalHeaderView(
                    title: title,
                    zoomState: Binding(
                        get: { self.viewModel.zoomState },
                        set: { self.viewModel.zoomState = $0 }
                    ),
                    isEditing: self.viewModel.isEditing
                )
                .padding(.horizontal, TokenSpacing._5)
            case .none:
                EmptyView()
            }
        }
        .margins(.all, 0)
        .background(TokenColors.Background.page.swiftUI)
    }
    
    private func updateGlobalHeaderMonthTitle() {
        guard let globalHeaderView = globalHeaderView else {
            return
        }

        // Only the date header renders a title; a sort header has nothing to track.
        guard representer.globalHeaderType.showsSectionDate else {
            return
        }

        // For timeline mode, update the month title based on visible sections
        guard let topSection = visibleSectionHeaders.min(),
              topSection < photoLibraryDataSource.count else {
            return
        }
        
        let newMonthTitle = photoLibraryDataSource[topSection].title
        
        if currentVisibleMonthTitle != newMonthTitle {
            currentVisibleMonthTitle = newMonthTitle
            globalHeaderView.contentConfiguration = createGlobalHeaderConfiguration(title: newMonthTitle)
        }
    }
    
    /// Force refresh the global header's content configuration.
    /// This is needed when zoom state changes between non-single-column states (e.g., default ↔ compact),
    /// because the UIHostingConfiguration won't automatically re-render when the Binding value changes.
    func refreshGlobalHeader() {
        guard let globalHeaderView = globalHeaderView else { return }
        let title = currentVisibleMonthTitle.isEmpty ? (photoLibraryDataSource.first?.title ?? "") : currentVisibleMonthTitle
        globalHeaderView.contentConfiguration = createGlobalHeaderConfiguration(title: title)
    }
    
    private func subscribeToEditModeChanges() {
        viewModel.libraryViewModel.selection.$editMode
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshGlobalHeader()
            }
            .store(in: &subscriptions)
    }
    
    private func configureScrollTracker(for collectionView: UICollectionView) {
        scrollTracker = PhotoLibraryCollectionViewScrollTracker(
            libraryViewModel: viewModel.libraryViewModel,
            collectionView: collectionView,
            delegate: self
        )
        scrollTracker.startTrackingScrolls()
    }

    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard viewModel.isEditing else { return }
        
        let location = gesture.location(in: collectionView)
        
        switch gesture.state {
        case .began:
            guard let indexPath = collectionView?.indexPathForItem(at: location) else { return }
            beginDragSelection(at: indexPath)

        case .changed:
            guard extendDragSelection(to: collectionView?.indexPathForItem(at: location)) else {
                break
            }
            updateAutoScrollIfNeeded(at: location)
            
        case .ended, .cancelled, .failed:
            endDragSelection()
            
        default:
            break
        }
    }

    /// Start a drag on the cell at `indexPath`.
    ///
    /// The pan recognizer does nothing but turn a gesture into this, ``extendDragSelection(to:)``
    /// and ``endDragSelection()``, so every way a drag can advance goes through the same three
    /// places — auto-scroll included, which is how it reaches the layout check without a gesture.
    func beginDragSelection(at indexPath: IndexPath) {
        guard let photo = photoLibraryDataSource.photo(at: indexPath) else { return }

        dragInitialIndexPath = indexPath
        dragLastIndexPath = indexPath
        dragLayoutVersion = layoutChangesMonitor.renderedLayoutVersion
        let selection = viewModel.libraryViewModel.selection
        let isInitialPhotoLongPressOrigin = wasRecentlyLongPressed(photo, at: indexPath)
        // When the user keeps the finger down after a long-press and continues into a drag,
        // the initial cell is already selected by the long-press. Treat the drag as an
        // extend-selection (.select) and skip toggling the initial cell so the user keeps it selected.
        if isInitialPhotoLongPressOrigin {
            dragSelectionMode = .select
            consumeRecentLongPressMark()
        } else {
            dragSelectionMode = isSelected(photo, at: indexPath) ? .deselect : .select
            if let dragSelectionMode {
                applySelectionMode(dragSelectionMode, to: photo, at: indexPath)
            }
        }
        // Taken after the initial cell has been toggled, so shrink-back restores what the drag
        // itself produced there rather than undoing it. With a handler the record lives there and
        // there only: it is the side that can follow a slot resolving into a node mid-drag.
        dragSelectionGestureToken = positionalSelectionHandler?.beginSelectionGesture()
        initialSelectionHandles = dragSelectionGestureToken == nil ? Set(selection.photos.keys) : []
    }

    /// Extend the running drag to `indexPath`, if that is a cell it is not already on.
    ///
    /// - Returns: false when the grid has been re-laid out under the finger and the drag was ended.
    ///   Its index paths were all read against one layout, so rather than extend the band by
    ///   positions that no longer mean what they did, the gesture stops here and what was selected
    ///   stays; the user starts a new stroke when ready.
    @discardableResult
    func extendDragSelection(to indexPath: IndexPath?) -> Bool {
        guard dragLayoutVersion == layoutChangesMonitor.renderedLayoutVersion else {
            endDragSelection()
            return false
        }
        guard let indexPath, indexPath != dragLastIndexPath else { return true }
        updateSelection(at: indexPath)
        dragLastIndexPath = indexPath
        return true
    }

    /// Forget what the running drag was built on. Idempotent: an abandoned drag ends here when the
    /// layout moves, and again when the finger lifts.
    func endDragSelection() {
        stopAutoScroll()
        dragInitialIndexPath = nil
        dragLastIndexPath = nil
        dragSelectionMode = nil
        dragLayoutVersion = nil
        initialSelectionHandles.removeAll()
        if let token = dragSelectionGestureToken {
            dragSelectionGestureToken = nil
            positionalSelectionHandler?.endSelectionGesture(token)
        }
    }
    
    private func updateSelection(at currentIndexPath: IndexPath) {
        guard let initialIndexPath = dragInitialIndexPath,
              let lastIndexPath = dragLastIndexPath,
              let selectionMode = dragSelectionMode else { return }
        
        let currentRange = Set(photoLibraryDataSource.indexPaths(from: initialIndexPath, to: currentIndexPath))
        let previousRange = Set(photoLibraryDataSource.indexPaths(from: initialIndexPath, to: lastIndexPath))
        
        // Photos added to the range in this step
        let addedToRange = currentRange.subtracting(previousRange)
        for indexPath in addedToRange {
            guard let photo = photoLibraryDataSource.photo(at: indexPath) else { continue }
            applySelectionMode(selectionMode, to: photo, at: indexPath)
        }
        
        // Photos removed from the range in this step
        let removedFromRange = previousRange.subtracting(currentRange)
        for indexPath in removedFromRange {
            guard let photo = photoLibraryDataSource.photo(at: indexPath) else { continue }
            restoreSelectionAtGestureStart(of: photo, at: indexPath)
        }
    }

    /// Whether the cell at `indexPath` is marked — by handle, or by position for a placeholder.
    private func isSelected(_ photo: NodeEntity, at indexPath: IndexPath) -> Bool {
        guard photo.isTimelinePlaceholder else {
            return viewModel.libraryViewModel.selection.isPhotoSelected(photo)
        }
        guard let handler = positionalSelectionHandler,
              let position = selectionPosition(at: indexPath) else { return false }
        return handler.isSelected(at: position)
    }

    /// Apply one step of a drag to one cell.
    ///
    /// Split per cell, never per gesture: one drag runs over loaded photos and placeholders alike. A
    /// loaded photo is keyed by the handle the grid is rendering, which means the same file whatever
    /// the layout does; only a placeholder needs a position. Sending the whole band as indices would
    /// drag the half that cannot be got wrong today into the same race.
    private func applySelectionMode(
        _ mode: DragSelectionMode, to photo: NodeEntity, at indexPath: IndexPath
    ) {
        guard photo.isTimelinePlaceholder else {
            switch mode {
            case .select:
                viewModel.libraryViewModel.selection.selectPhoto(photo)
            case .deselect:
                viewModel.libraryViewModel.selection.deselectPhoto(photo)
            }
            return
        }
        guard let handler = positionalSelectionHandler,
              let position = selectionPosition(at: indexPath) else { return }
        handler.apply(mode == .select ? .dragSelect : .dragDeselect, at: position)
    }

    /// Put a cell the band has shrunk back off into the state it was in when the drag began.
    private func restoreSelectionAtGestureStart(of photo: NodeEntity, at indexPath: IndexPath) {
        guard photo.isTimelinePlaceholder else {
            let selection = viewModel.libraryViewModel.selection
            if wasSelectedAtGestureStart(photo) {
                selection.selectPhoto(photo)
            } else {
                selection.deselectPhoto(photo)
            }
            return
        }
        guard let handler = positionalSelectionHandler,
              let token = dragSelectionGestureToken,
              let position = selectionPosition(at: indexPath) else { return }
        handler.apply(
            handler.wasSelectedAtGestureStart(token, at: position) ? .dragSelect : .dragDeselect,
            at: position)
    }

    /// Whether a loaded cell was marked when the drag began. The handler answers when there is one:
    /// this cell may have been marked as a slot with no photo yet and resolved into this node since,
    /// which a record of handles taken at `.began` cannot know about.
    private func wasSelectedAtGestureStart(_ photo: NodeEntity) -> Bool {
        guard let handler = positionalSelectionHandler,
              let token = dragSelectionGestureToken else {
            return initialSelectionHandles.contains(photo.handle)
        }
        return handler.wasSelectedAtGestureStart(token, handle: photo.handle)
    }

    /// Both stores are asked, rather than the one this cell matches now.
    ///
    private func wasRecentlyLongPressed(_ photo: NodeEntity, at indexPath: IndexPath) -> Bool {
        if viewModel.libraryViewModel.selection.wasRecentlyLongPressed(photo.handle) { return true }
        guard let handler = positionalSelectionHandler,
              let position = selectionPosition(at: indexPath) else { return false }
        return handler.wasRecentlyLongPressed(at: position)
    }

    /// Cleared on both sides for the same reason the read asks both: whichever took the mark, it is
    /// spent, and the other holds nothing to clear.
    private func consumeRecentLongPressMark() {
        viewModel.libraryViewModel.selection.consumeRecentLongPressMark()
        positionalSelectionHandler?.consumeRecentLongPressMark()
    }

    private func updateAutoScrollIfNeeded(at location: CGPoint) {
        guard let collectionView else {
            stopAutoScroll()
            return
        }

        let insets = collectionView.adjustedContentInset
        let visibleTop = collectionView.bounds.minY + insets.top
        let visibleBottom = collectionView.bounds.maxY - insets.bottom
        let topZone = Self.autoScrollTopEdgeZone
        let bottomZone = Self.autoScrollBottomEdgeZone
        let maxVelocity = Self.autoScrollMaxVelocity

        let velocity: CGFloat
        if location.y < visibleTop + topZone {
            let distance = max(0, min(topZone, visibleTop + topZone - location.y))
            let ratio = distance / topZone
            velocity = -pow(ratio, 2) * maxVelocity
        } else if location.y > visibleBottom - bottomZone {
            let distance = max(0, min(bottomZone, location.y - (visibleBottom - bottomZone)))
            let ratio = distance / bottomZone
            velocity = pow(ratio, 2) * maxVelocity
        } else {
            velocity = 0
        }

        if velocity == 0 {
            stopAutoScroll()
        } else {
            autoScrollVelocity = velocity
            startAutoScrollIfNeeded()
        }
    }

    private func startAutoScrollIfNeeded() {
        guard autoScrollDisplayLink == nil else { return }
        let proxy = DisplayLinkProxy(self)
        let link = CADisplayLink(target: proxy, selector: #selector(DisplayLinkProxy.tick(_:)))
        link.add(to: .main, forMode: .common)
        autoScrollDisplayLink = link
    }

    func stopAutoScroll() {
        autoScrollDisplayLink?.invalidate()
        autoScrollDisplayLink = nil
        autoScrollVelocity = 0
    }

    fileprivate func autoScrollTick(_ link: CADisplayLink) {
        guard let collectionView,
              let gesture = dragSelectionPanGesture,
              autoScrollVelocity != 0 else {
            stopAutoScroll()
            return
        }

        let frameDuration = CGFloat(max(0, link.targetTimestamp - link.timestamp))
        let delta = autoScrollVelocity * frameDuration
        guard delta != 0 else { return }

        let insets = collectionView.adjustedContentInset
        let minOffsetY = -insets.top
        let maxOffsetY = max(
            minOffsetY,
            collectionView.contentSize.height - collectionView.bounds.height + insets.bottom
        )

        var offset = collectionView.contentOffset
        let newY = min(max(offset.y + delta, minOffsetY), maxOffsetY)
        guard newY != offset.y else {
            stopAutoScroll()
            return
        }
        offset.y = newY
        collectionView.setContentOffset(offset, animated: false)

        let location = gesture.location(in: collectionView)
        extendDragSelection(to: collectionView.indexPathForItem(at: location))
    }
}

@MainActor
private final class DisplayLinkProxy: NSObject {
    weak var target: PhotoLibraryCollectionViewCoordinator?

    init(_ target: PhotoLibraryCollectionViewCoordinator) {
        self.target = target
    }

    @objc func tick(_ link: CADisplayLink) {
        guard let target else {
            link.invalidate()
            return
        }
        target.autoScrollTick(link)
    }
}

// MARK: - UICollectionViewDataSource

extension PhotoLibraryCollectionViewCoordinator: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        photoLibraryDataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        photoLibraryDataSource[section].itemCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        collectionView.dequeueConfiguredReusableCell(
            using: photoCellRegistration,
            for: indexPath,
            item: photoLibraryDataSource.photo(at: indexPath)
        )
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch PhotoLibrarySupplementaryElementKind(rawValue: kind) {
        case .layoutHeaderEnableCameraUploads:
            collectionView.dequeueConfiguredReusableSupplementary(using: enableCameraUploadsBannerRegistration, for: indexPath)
        case .layoutHeaderLimitedPermissions:
            collectionView.dequeueConfiguredReusableSupplementary(using: limitedPermissionsBannerRegistration, for: indexPath)
        case .photoDateSectionHeader:
            collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        case .globalZoomHeader:
            collectionView.dequeueConfiguredReusableSupplementary(using: globalZoomHeaderRegistration, for: indexPath)
        case .layoutSortHeader:
            collectionView.dequeueConfiguredReusableSupplementary(using: sortHeaderRegistration, for: indexPath)
        case .none:
            fatalError("Unknown supported PhotoLibraryCollectionViewCoordinator.viewForSupplementaryElementOfKind: \(kind)")
        }
    }
}

// MARK: - UICollectionViewDelegate

extension PhotoLibraryCollectionViewCoordinator: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        updateVisiblePhotoIndexRange(including: indexPath)
    }

    /// Publish the flat index range of the currently on-screen photos so a paginated-timeline
    /// consumer can lazily hydrate that window. No-op for content modes that don't observe it.
    private func updateVisiblePhotoIndexRange(including indexPath: IndexPath? = nil) {
        guard let collectionView else { return }
        var indexPaths = collectionView.indexPathsForVisibleItems
        if let indexPath { indexPaths.append(indexPath) }
        let flatIndices = indexPaths.compactMap { photoLibraryDataSource.flatIndex(of: $0) }
        guard let lowerBound = flatIndices.min(), let upperBound = flatIndices.max() else { return }
        viewModel.libraryViewModel.visiblePhotoIndexRange.send(lowerBound..<(upperBound + 1))
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let photo = photoLibraryDataSource.photo(at: indexPath) else { return }
        guard !photo.isTimelinePlaceholder else { return }
        
        if photo.isTakenDown {
            router.showTakenDownNodeAlert()
        } else {
            viewModel.libraryViewModel.openPhoto(photo) { [weak self] in
                self?.openPhotoBrowser(for: photo)
            }
        }
    }

    private func openPhotoBrowser(for photo: NodeEntity) {
        guard let query = viewModel.libraryViewModel.mediaTimelineQuery else {
            router.openPhotoBrowser(for: photo, allPhotos: photoLibraryDataSource.hydratedPhotos)
            return
        }
        // Nil means the committed library no longer holds this photo: the grid renders a debounce
        // behind, so one the query has just excluded stays tappable for a moment. Opening it on the
        // outgoing array would show content the filter dropped, in a browser that could not page
        // for the rest of the session. The cell goes on its own.
        guard let context = paginationContext(for: photo, query: query) else { return }
        router.openPhotoBrowser(for: photo, in: context)
    }

    /// The handover for a browser opened on `photo`, or `nil` when the committed library does not
    /// hold it.
    ///
    /// The run is read from the same library the caller read `query` from, in the one turn, rather
    /// than from the grid: the grid lags a debounce behind, so just after a filter or sort change
    /// the two describe different queries, and a browser handed that pair would page from cursors
    /// its nodes never came from. The tapped photo is located in the committed library instead of
    /// by its index path for the same reason.
    ///
    /// `hydratedPhotos` could not serve as the run in any case: it drops placeholders wherever
    /// they fall, welding the stretches either side of an unloaded region into one array with
    /// nothing left to say a region was skipped. A run grows at its two ends only, so what is
    /// handed over has to be contiguous.
    ///
    /// The count is the whole projection, placeholders included: the skeleton holds one slot per
    /// item in the source, so its length is the total the title starts from.
    private func paginationContext(
        for photo: NodeEntity,
        query: MediaTimelineQuery
    ) -> PhotoBrowserPaginationContext? {
        let photos = viewModel.libraryViewModel.library.allPhotos
        guard let index = photos.firstIndex(of: photo),
              let run = photos.contiguousRealRun(
                around: index,
                radius: PhotoBrowserPaginationContext.defaultInitialRadius) else { return nil }
        return PhotoBrowserPaginationContext(
            nodes: run.nodes,
            globalStartIndex: run.startIndex,
            totalCount: photos.count,
            filter: query.filter,
            sortOrder: query.sortOrder)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        willDisplaySupplementaryView view: UICollectionReusableView,
        forElementKind elementKind: String,
        at indexPath: IndexPath
    ) {
        guard let kind = PhotoLibrarySupplementaryElementKind(rawValue: elementKind) else { return }
        
        view.layer.zPosition = kind.zPosition
        
        // Track visible section headers to update the global header with the topmost section
        if kind == .photoDateSectionHeader {
            visibleSectionHeaders.insert(indexPath.section)
            updateGlobalHeaderMonthTitle()
        }
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplayingSupplementaryView view: UICollectionReusableView,
        forElementOfKind elementKind: String,
        at indexPath: IndexPath
    ) {
        // Remove section from tracking when it's no longer visible
        if elementKind == PhotoLibrarySupplementaryElementKind.photoDateSectionHeader.elementKind {
            visibleSectionHeaders.remove(indexPath.section)
            updateGlobalHeaderMonthTitle()
        }
    }
}

// MARK: - PhotoLibraryCollectionViewScrolling

extension PhotoLibraryCollectionViewCoordinator: PhotoLibraryCollectionViewScrolling {
    func scrollTo(_ position: PhotoScrollPosition) {
        guard position != .top else {
            collectionView?.setContentOffset(.zero, animated: false)
            return
        }
        
        guard let indexPath = photoLibraryDataSource.indexPath(of: position) else { return }
        collectionView?.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
    }
    
    func position(at indexPath: IndexPath) -> PhotoScrollPosition? {
        photoLibraryDataSource.position(at: indexPath)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension PhotoLibraryCollectionViewCoordinator: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === longPressGesture {
            guard !viewModel.isEditing else { return false }
            let location = gestureRecognizer.location(in: collectionView)
            return collectionView?.indexPathForItem(at: location) != nil
        }
        
        guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer,
              gestureRecognizer === dragSelectionPanGesture,
              viewModel.isEditing else {
            return false
        }
        
        let velocity = panGesture.velocity(in: collectionView)
        
        guard abs(velocity.x) > abs(velocity.y) else {
            return false
        }
        
        let location = panGesture.location(in: collectionView)
        return collectionView?.indexPathForItem(at: location) != nil
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === dragSelectionPanGesture else {
            return false
        }

        if otherGestureRecognizer === collectionView?.panGestureRecognizer {
            return false
        }

        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // In album picker mode, the sheet dismiss gesture (an external pan
        // gesture) must wait for drag selection to fail before it can begin.
        // Drag selection fails when the pan doesn't start on a photo cell,
        // allowing the sheet to be dismissed from non-cell areas.
        if gestureRecognizer === dragSelectionPanGesture,
           representer.contentMode == .albumPicker,
           viewModel.isEditing,
           otherGestureRecognizer is UIPanGestureRecognizer,
           otherGestureRecognizer !== collectionView?.panGestureRecognizer {
            return true
        }
        return false
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        gestureRecognizer === collectionView?.panGestureRecognizer && otherGestureRecognizer === dragSelectionPanGesture
    }
}
