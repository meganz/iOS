import Combine
import UIKit

final class PhotosBrowserCollectionViewLayoutChangesMonitor {
    private weak var collectionView: UICollectionView?
    private let representer: PhotosBrowserCollectionViewRepresenter
    private var subscriptions = Set<AnyCancellable>()
    
    weak var coordinator: PhotosBrowserCollectionViewCoordinator?
    
    init(_ representer: PhotosBrowserCollectionViewRepresenter) {
        self.representer = representer
    }
    
    func configure(collectionView: UICollectionView, coordinator: PhotosBrowserCollectionViewCoordinator) {
        self.collectionView = collectionView
        self.coordinator = coordinator
        
        subscribeToLayoutChanges()
    }
    
    private func subscribeToLayoutChanges() {
        NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, let collectionView = self.collectionView, let coordinator = self.coordinator else { return }
                
                let newLayout = PhotosBrowserCollectionViewLayout()
                collectionView.setCollectionViewLayout(newLayout, animated: true)
                collectionView.collectionViewLayout.invalidateLayout()
                
                Task { @MainActor in
                    coordinator.updateLayout(newLayout, scrollToCurrentIndex: true)
                }
            }
            .store(in: &subscriptions)
    }
}
