import Foundation

final class SlideShowOptionDetailCellViewModel: Identifiable, ObservableObject {
    let id: String
    let image: ImageAsset?
    let title: String
    
    @Published var isSelcted: Bool
    
    init(id: String = UUID().uuidString, image: ImageAsset? = nil, title: String, isSelcted: Bool) {
        self.id = id
        self.image = image
        self.title = title
        self.isSelcted = isSelcted
    }
}
