import Foundation

final class SlideShowOptionCellViewModel: Identifiable, ObservableObject {
    let id: String
    let title: String
    let type: OptionType
    
    @Published var detail = ""
    @Published var children:[SlideShowOptionDetailCellViewModel]
    @Published var isOn = false
    
    enum OptionType {
        case none
        case detail
        case toggle
    }
    
    init(id: String = UUID().uuidString, title: String, type: SlideShowOptionCellViewModel.OptionType, children: [SlideShowOptionDetailCellViewModel]) {
        self.id = id
        self.title = title
        self.type = type
        self.children = children
        detail = type == .detail ? (children.first(where: { $0.isSelcted })?.title ?? "") : ""
    }
    
    func didSelectChild(_ child: SlideShowOptionDetailCellViewModel) {
        if type == .detail {
            children.forEach({ $0 .isSelcted = $0.id == child.id })
            detail = child.title
        }
    }
}
