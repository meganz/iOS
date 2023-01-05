import Combine
import SwiftUI

final class CreateAlbumCellViewModel: ObservableObject {
    @Published var orientation = UIDevice.current.orientation
    @Published var plusIconSize: CGFloat = 0
    
    private var cancellable: Cancellable?
    
    private var isLandscape: Bool {
        orientation == .landscapeLeft || orientation == .landscapeRight
    }
    
    init() {
        updatePlusIconSize()
        cancellable = NotificationCenter.default
                                        .publisher(for: UIDevice.orientationDidChangeNotification)
                                        .sink {
                                            guard let orientation = ($0.object as? UIDevice)?.orientation else { return }
                                            
                                            self.orientation = orientation
                                            self.updatePlusIconSize()
                                        }
    }
    
    deinit {
        cancellable?.cancel()
    }
    
    // MARK: - Private
    
    private func updatePlusIconSize() {
        plusIconSize = isLandscape ? UIDevice.current.iPad ? 35 : 25
        : UIDevice.current.iPad ? 25 : 20
    }
}
