import Foundation
import Combine

@objc final class PhotoUpdatePublisher: NSObject {
    private enum Constants {
        static let headerReloadInterval = 1.3
        static let photoUpdateThrottleInterval = 5.0
    }
    
    private var subscriptions = Set<AnyCancellable>()
    private weak var photosVC: PhotosViewController?
    
    private let photoLibrarySubject = PassthroughSubject<Void, Never>()
    
    @objc init(photosViewController: PhotosViewController) {
        photosVC = photosViewController
        super.init()
    }
    
    @objc func setupSubscriptions() {
        subscribleToCameraUploadStatsChange()
        subscribleToPhotoLibraryUpdate()
    }
    
    @objc func cancelSubscriptions() {
        subscriptions.removeAll()
    }
    
    @objc func updatePhotoLibrary() {
        photoLibrarySubject.send()
    }
    
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
}
