import Combine
import UIKit

final class PhotosBrowserCollectionViewLayoutChangesMonitor {
    private weak var collectionView: UICollectionView?
    private let representer: PhotosBrowserCollectionViewRepresenter
    private var subscriptions = Set<AnyCancellable>()
    
    init(_ representer: PhotosBrowserCollectionViewRepresenter) {
        self.representer = representer
    }
    
    func configure(collectionView: UICollectionView) {
        self.collectionView = collectionView
        
        subscribeToLayoutChanges()
    }
    
    private func subscribeToLayoutChanges() {
        NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                
                collectionView?.setCollectionViewLayout(PhotosBrowserCollectionViewLayout(), animated: true)
                collectionView?.collectionViewLayout.invalidateLayout()
            }
            .store(in: &subscriptions)
    }
}
