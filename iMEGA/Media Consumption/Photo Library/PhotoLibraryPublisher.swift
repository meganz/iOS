import Combine
import Foundation
import MEGADomain

@MainActor
final class PhotoLibraryPublisher {
    private var subscriptions = Set<AnyCancellable>()
    
    let viewModel: PhotoLibraryContentViewModel
    
    init(viewModel: PhotoLibraryContentViewModel) {
        self.viewModel = viewModel
    }
    
    func subscribeToSelectedPhotosChange(observer: @escaping ([HandleEntity: NodeEntity]) -> Void) {
        viewModel
            .selection
            .$photos
            .dropFirst()
            .sink {
                observer($0)
            }
            .store(in: &subscriptions)
    }
    
    func subscribeToPhotoSelectionHidden(observer: @escaping (Bool) -> Void) {
        viewModel.$selectedMode
            .combineLatest(viewModel.selection.$isHidden)
            .map {
                if $0.0 != .all {
                    return true
                }
                return $0.1
            }
            .removeDuplicates()
            .sink {
                observer($0)
            }
            .store(in: &subscriptions)
    }
    
    func cancelSubscriptions() {
        subscriptions.removeAll()
    }
}
