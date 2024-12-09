import Combine
import MEGADomain

@MainActor
public final class AddToCollectionViewModel: ObservableObject {
    @Published public var isAddButtonDisabled: Bool = true
    
    let addToAlbumsViewModel: AddToAlbumsViewModel
    
    private let selectedPhotos: [NodeEntity]
    
    public init(
        selectedPhotos: [NodeEntity],
        addToAlbumsViewModel: AddToAlbumsViewModel
    ) {
        self.selectedPhotos = selectedPhotos
        self.addToAlbumsViewModel = addToAlbumsViewModel
        
        addToAlbumsViewModel.isAddButtonDisabled
            .assign(to: &$isAddButtonDisabled)
    }
    
    public func addToCollectionTapped() {
        addToAlbumsViewModel.addItems(selectedPhotos)
    }
}
