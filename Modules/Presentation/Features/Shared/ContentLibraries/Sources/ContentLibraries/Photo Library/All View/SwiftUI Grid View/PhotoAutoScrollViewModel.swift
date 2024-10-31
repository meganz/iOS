import Combine
import Foundation

@MainActor
final class PhotoAutoScrollViewModel: ObservableObject {
    private var subscriptions = Set<AnyCancellable>()
    private let viewModel: PhotoLibraryModeAllGridViewModel
    
    @Published var autoScrollWithAnimation = 0
    @Published var autoScrollWithoutAnimation = 0
    
    var position: PhotoScrollPosition? {
        viewModel.position
    }
    
    init(viewModel: PhotoLibraryModeAllGridViewModel) {
        self.viewModel = viewModel
        
        subscribeToCardScrollFinishNotification()
        subscribeToZoomState()
    }
    
    private func subscribeToCardScrollFinishNotification() {
        NotificationCenter
            .default
            .publisher(for: .didFinishPhotoCardScrollPositionCalculation)
            .filter { [weak self] _ in
                self?.viewModel.hasPositionChange() == true
            }
            .sink { [weak self] _ in
                self?.autoScrollWithAnimation += 1
            }
            .store(in: &subscriptions)
    }
    
    private func subscribeToZoomState() {
        viewModel
            .$zoomState
            .dropFirst()
            .sink { [weak self] _ in
                self?.autoScrollWithoutAnimation += 1
            }
            .store(in: &subscriptions)
    }
}
