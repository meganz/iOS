import Foundation
import Combine

@available(iOS 14.0, *)
final class PhotoAutoScrollViewModel: ObservableObject, PhotoScrollPositioning {
    private var subscriptions = Set<AnyCancellable>()
    private let viewModel: PhotoLibraryAllViewModel
    
    @Published var autoScroll = 0
    
    var position: PhotoScrollPosition? {
        viewModel.position
    }
    
    init(viewModel: PhotoLibraryAllViewModel) {
        self.viewModel = viewModel
        
        subscribeToCardScrollFinishNotification()
    }
    
    private func subscribeToCardScrollFinishNotification() {
        NotificationCenter
            .default
            .publisher(for: .didFinishPhotoCardScrollPositionCalculation)
            .filter { [weak self] _ in
                self?.viewModel.hasPositionChange() == true
            }
            .sink { [weak self] _ in
                self?.autoScroll += 1
            }
            .store(in: &subscriptions)
    }
}
