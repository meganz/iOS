import Foundation

final class SlideShowOptionViewModel: ObservableObject {
    let navigationTitle = Strings.Localizable.Slideshow.PreferenceSetting.slideshowOptions
    let footerNote = Strings.Localizable.Slideshow.PreferenceSetting.mediaInSubFolders
    let doneButtonTitle = Strings.Localizable.done
    let cellViewModels: [SlideShowOptionCellViewModel]
    private(set) var selectedCell: SlideShowOptionCellViewModel!
    
    @Published var shouldShowDetail = false
    
    init(cellViewModels: [SlideShowOptionCellViewModel]) {
        self.cellViewModels = cellViewModels
    }
    
    func didSelectCell(_ model: SlideShowOptionCellViewModel) {
        if model.type == .detail {
            selectedCell = model
            shouldShowDetail.toggle()
        }
    }
}

extension SlideShowOptionViewModel {
    convenience init(@SlideShowOptionBuilder _ makeCells: () -> [SlideShowOptionCellViewModel]) {
        self.init(cellViewModels: makeCells())
    }
}
