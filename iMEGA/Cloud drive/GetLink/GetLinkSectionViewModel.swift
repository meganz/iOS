import Foundation
import MEGADomain

struct GetLinkSectionViewModel {
    let sectionType: GetLinkTableViewSection
    var cellViewModels: [any GetLinkCellViewModelType]
    let itemHandle: HandleEntity?
    
    init(sectionType: GetLinkTableViewSection,
         cellViewModels: [any GetLinkCellViewModelType],
         itemHandle: HandleEntity? = nil) {
        self.sectionType = sectionType
        self.cellViewModels = cellViewModels
        self.itemHandle = itemHandle
    }
}
