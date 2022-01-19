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
    
    @objc init(photosViewController: PhotosViewController) {
        photosVC = photosViewController
        
        super.init()
    }
    
    // MARK: - Update subscriptions
    
    @objc func setupSubscriptions() {
        subscribleToCameraUploadStatsChange()
        subscribleToPhotoLibraryUpdate()
        subscribeSelectedModeChange()
        subscribeSelectedPhotosChange()
    }
    
    @objc func cancelSubscriptions() {
        subscriptions.removeAll()
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
            .sink { [weak self] _ in
                self?.photosVC?.reloadHeader()
            }
            .store(in: &subscriptions)
    }
    
    private func subscribleToPhotoLibraryUpdate() {
        photoLibrarySubject
            .throttle(for: .seconds(Constants.photoUpdateThrottleInterval), scheduler: DispatchQueue.global(qos: .userInitiated), latest: true)
            .sink { [weak self] in
                self?.photosVC?.reloadPhotos()
            }
            .store(in: &subscriptions)
    }
    
    private func subscribeSelectedModeChange() {
        photosVC?
            .photoLibraryContentViewModel
            .$selectedMode
            .sink { [weak self] in
                self?.photosVC?.showToolbar($0 == .all)
            }
            .store(in: &subscriptions)
    }
    
    private func subscribeSelectedPhotosChange() {
        photosVC?
            .photoLibraryContentViewModel
            .selection
            .$photos
            .dropFirst()
            .sink { [weak self] in
                self?.photosVC?.selection.setSelectedNodes(Array($0.values))
                self?.photosVC?.didSelectedPhotoCountChange($0.count)
            }
            .store(in: &subscriptions)
    }
}
