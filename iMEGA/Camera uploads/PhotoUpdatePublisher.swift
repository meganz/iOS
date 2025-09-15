import Combine
import ContentLibraries
import Foundation
import MEGASwift

@MainActor
protocol PhotoUpdatePublisherProtocol {
    func setupSubscriptions()
    func cancelSubscriptions()
    func updatePhotoLibrary()
}

@MainActor
@objc final class PhotoUpdatePublisher: NSObject, PhotoUpdatePublisherProtocol {
    private enum Constants {
        static let headerReloadInterval = 1.3
        static let photoUpdateDebounceInterval = 0.5
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
        subscribleToPhotoLibraryUpdate()
        
        photoLibraryPublisher.subscribeToSelectedPhotosChange { [weak self] in
            self?.photosVC?.selection.setSelectedNodes(Array($0.values))
            self?.photosVC?.didSelectedPhotoCountChange($0.count)
        }
        
        photoLibraryPublisher.subscribeToPhotoSelectionHidden { [weak self] isPhotoSelectionHidden in
            self?.photosVC?.viewModel.isSelectHidden = isPhotoSelectionHidden
            self?.photosVC?.setupNavigationBarButtons()
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
    private func subscribleToPhotoLibraryUpdate() {
        photoLibrarySubject
            .debounceImmediate(for: .seconds(Constants.photoUpdateDebounceInterval), scheduler: DispatchQueue.main)
            .sink { [weak self] in self?.photosVC?.reloadPhotos() }
            .store(in: &subscriptions)
    }
}
