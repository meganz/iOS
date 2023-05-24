import Foundation
import MEGADomain

struct GetLinkSectionViewModel {
    let sectionType: GetLinkTableViewSection
    var cellViewModels: [any GetLinkCellViewModelType]
    let itemHandle: HandleEntity?
}
