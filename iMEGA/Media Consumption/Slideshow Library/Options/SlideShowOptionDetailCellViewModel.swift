import Foundation

final class SlideShowOptionDetailCellViewModel: Identifiable, ObservableObject {
    let id: String
    let name: SlideShowOptionName
    let image: ImageAsset?
    let title: String
    
    @Published var isSelcted: Bool
    
    init(id: String = UUID().uuidString, name: SlideShowOptionName, image: ImageAsset? = nil, title: String, isSelcted: Bool) {
        self.id = id
        self.name = name
        self.image = image
        self.title = title
        self.isSelcted = isSelcted
    }
}
