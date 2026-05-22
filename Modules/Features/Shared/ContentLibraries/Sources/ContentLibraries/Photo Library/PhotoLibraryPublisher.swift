import Combine
import Foundation
import MEGADomain
import SwiftUI

@MainActor
public final class PhotoLibraryPublisher {
    private var subscriptions = Set<AnyCancellable>()
    
    let viewModel: PhotoLibraryContentViewModel
    
    public init(viewModel: PhotoLibraryContentViewModel) {
        self.viewModel = viewModel
    }
    
    public func subscribeToSelectedPhotosChange(observer: @escaping ([HandleEntity: NodeEntity]) -> Void) {
        viewModel
            .selection
            .$photos
            .dropFirst()
            .sink {
                observer($0)
            }
            .store(in: &subscriptions)
    }
    
    public func subscribeToPhotoSelectionHidden(observer: @escaping (Bool) -> Void) {
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
    
    public func subscribeToEditModeChange(observer: @escaping (EditMode) -> Void) {
        viewModel
            .selection
            .$editMode
            .dropFirst()
            .removeDuplicates(by: { $0.isEditing == $1.isEditing })
            .receive(on: DispatchQueue.main)
            .sink { observer($0) }
            .store(in: &subscriptions)
    }

    public func cancelSubscriptions() {
        subscriptions.removeAll()
    }
}
