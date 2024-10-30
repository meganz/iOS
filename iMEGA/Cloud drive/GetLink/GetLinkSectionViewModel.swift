import Foundation
import MEGADomain

struct GetLinkSectionViewModel {
    let sectionType: GetLinkTableViewSection
    var cellViewModels: [any GetLinkCellViewModelType]
    let setIdentifier: SetIdentifier?
    
    init(sectionType: GetLinkTableViewSection,
         cellViewModels: [any GetLinkCellViewModelType],
         setIdentifier: SetIdentifier? = nil) {
        self.sectionType = sectionType
        self.cellViewModels = cellViewModels
        self.setIdentifier = setIdentifier
    }
}
