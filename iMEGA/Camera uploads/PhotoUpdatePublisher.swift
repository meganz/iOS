import Foundation
import Combine

@objc final class PhotoUpdatePublisher: NSObject {
    private enum Constants {
        static let headerReloadInterval = 1.3
        static let photoUpdateThrottleInterval = 5.0
    }
    
    private let photoLibrarySubject = PassthroughSubject<Void, Never>()
    private var subscriptions = Set<AnyCancellable>()
    private weak var photosVC: PhotosViewController?
    private let photoLibraryPublisher: PhotoLibraryPublisher
    
    @objc init(photosViewController: PhotosViewController) {
        photosVC = photosViewController
        photoLibraryPublisher = PhotoLibraryPublisher(viewModel: photosViewController.photoLibraryContentViewModel)
        
        super.init()
    }
    
    // MARK: - Update subscriptions
    
    @objc func setupSubscriptions() {
        subscribleToCameraUploadStatsChange()
        subscribleToPhotoLibraryUpdate()
        
        photoLibraryPublisher.subscribeToSelectedPhotosChange { [weak self] in
            self?.photosVC?.selection.setSelectedNodes(Array($0.values))
            self?.photosVC?.didSelectedPhotoCountChange($0.count)
        }
        
        photoLibraryPublisher.subscribeToPhotoSelectionHidden { [weak self] isPhotoSelectionHidden in
            DispatchQueue.main.async {
                self?.photosVC?.viewModel.isSelectHidden = isPhotoSelectionHidden
                self?.photosVC?.setupNavigationBarButtons()
            }
        }
    }
    
    @objc func cancelSubscriptions() {
        subscriptions.removeAll()
        photoLibraryPublisher.cancelSubscriptions()
    }
    
    // MARK: - send message
    
    @objc func updatePhotoLibrary() {
        photoLibrarySubject.send()
    }
    
    // MARK: Private
    
    private func subscribleToCameraUploadStatsChange() {
        NotificationCenter.default
            .publisher(for: Notification.Name.MEGACameraUploadStatsChanged)
            .throttle(for: .seconds(Constants.headerReloadInterval), scheduler: DispatchQueue.main, latest: true)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.photosVC?.reloadHeader()
            }
            .store(in: &subscriptions)
    }
    
    private func subscribleToPhotoLibraryUpdate() {
        photoLibrarySubject
            .throttle(for: .seconds(Constants.photoUpdateThrottleInterval), scheduler: DispatchQueue.global(qos: .userInitiated), latest: true)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.photosVC?.reloadPhotos()
            }
            .store(in: &subscriptions)
    }
}
