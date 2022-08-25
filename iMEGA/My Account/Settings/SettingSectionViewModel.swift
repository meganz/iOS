import Foundation

struct SettingSectionViewModel {
    
    private(set) var cellViewModels: [SettingCellViewModel]
    
    init(cellViewModels: [SettingCellViewModel]) {
        self.cellViewModels = cellViewModels
    }
}
