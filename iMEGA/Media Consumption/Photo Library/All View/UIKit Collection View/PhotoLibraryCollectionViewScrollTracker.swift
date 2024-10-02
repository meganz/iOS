import Combine

@MainActor
protocol PhotoLibraryCollectionViewScrolling: AnyObject {
    func scrollTo(_ position: PhotoScrollPosition)
    func position(at indexPath: IndexPath) -> PhotoScrollPosition?
}

@MainActor
final class PhotoLibraryCollectionViewScrollTracker {
    private var subscriptions = Set<AnyCancellable>()
    private let libraryViewModel: PhotoLibraryContentViewModel
    private let collectionView: UICollectionView
    private let timeZone: TimeZone?
    private weak var delegate: (any PhotoLibraryCollectionViewScrolling)?
    
    init(libraryViewModel: PhotoLibraryContentViewModel,
         collectionView: UICollectionView,
         delegate: some PhotoLibraryCollectionViewScrolling,
         in timeZone: TimeZone? = nil) {
        self.libraryViewModel = libraryViewModel
        self.collectionView = collectionView
        self.delegate = delegate
        self.timeZone = timeZone
    }
    
    func startTrackingScrolls() {
        subscribeToCardScrollFinishNotification()
        subscribeToSelectedModeChange()
    }
    
    // MARK: Auto Scroll to the calculated position
    private func subscribeToCardScrollFinishNotification() {
        NotificationCenter
            .default
            .publisher(for: .didFinishPhotoCardScrollPositionCalculation)
            .sink { [weak self] _ in
                self?.scroll()
            }
            .store(in: &subscriptions)
    }
    
    private func scroll() {
        switch (libraryViewModel.cardScrollPosition, libraryViewModel.photoScrollPosition) {
        case (let position?, .none), (.none, let position?):
            delegate?.scrollTo(position)
        case let (cardPosition?, photoPosition?):
            if cardPosition.date.removeTimestamp(timeZone: timeZone) != photoPosition.date.removeTimestamp(timeZone: timeZone) {
                delegate?.scrollTo(cardPosition)
            }
        case (.none, .none):
            delegate?.scrollTo(.top)
        }
    }
    
    // MARK: Calculate the last scroll position
    private func subscribeToSelectedModeChange() {
        libraryViewModel
            .$selectedMode
            .dropFirst()
            .combinePrevious(.all)
            .filter {
                $0.previous == .all
            }
            .sink { [weak self] _ in
                self?.calculateLastScrollPosition()
            }
            .store(in: &subscriptions)
    }
    
    private func calculateLastScrollPosition() {
        libraryViewModel.cardScrollPosition = nil
        
        guard collectionView.contentOffset.y > 64 else {
            libraryViewModel.photoScrollPosition = nil
            return
        }
        
        let visibleIndexPaths = collectionView.indexPathsForVisibleItems.sorted()
        guard visibleIndexPaths.isNotEmpty else { return }
        let anchorIndexPath = visibleIndexPaths[(visibleIndexPaths.count - 1) / 2]
        libraryViewModel.photoScrollPosition = delegate?.position(at: anchorIndexPath)
    }
}
