import Combine

@available(iOS 14.0, *)
final class ImageUpdatePublisher {
    private let photoLibrarySubject = PassthroughSubject<Void, Never>()
    private var subscriptions = Set<AnyCancellable>()
    private weak var photoExplorerViewController: PhotosExplorerViewController?
    
    // MARK: - Init
    init(photoExplorerViewController: PhotosExplorerViewController) {
        self.photoExplorerViewController = photoExplorerViewController
    }
    
    // MARK: Subscribe changes
    
    func setupSubscriptions() {
        subscribeSelectedModeChange()
        subscribeSelectedPhotosChange()
    }
    
    // MARK: - Subscribe selected mode change
    
    private func subscribeSelectedModeChange() {
        photoExplorerViewController?
            .photoLibraryContentViewModel
            .$selectedMode
            .sink { [weak self] in
                self?.photoExplorerViewController?.showNavigationRightBarButton($0 == .all)
            }
            .store(in: &subscriptions)
    }
    
    // MARK: - Subscribe selected photos change
    
    private func subscribeSelectedPhotosChange() {
        photoExplorerViewController?
            .photoLibraryContentViewModel
            .selection
            .$photos
            .dropFirst()
            .sink { [weak self] in
                self?.photoExplorerViewController?.selection.setSelectedNodes(Array($0.values))
                self?.photoExplorerViewController?.didSelectedPhotoCountChange($0.count)
            }
            .store(in: &subscriptions)
    }
}
