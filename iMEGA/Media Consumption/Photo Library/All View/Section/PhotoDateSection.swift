import Foundation
import MEGADomain

protocol PhotoSection: PhotoChronologicalCategory where Content == NodeEntity {
    var title: String { get }

    var attributedTitle: AttributedString { get }
}

extension PhotoSection {
    var coverPhoto: NodeEntity? {
        contentList.first?.coverPhoto
    }
}

class PhotoDateSection: PhotoSection {
    var id: String { title }
    let contentList: [NodeEntity]
    let photoByDayList: [PhotoByDay]
    let categoryDate: Date
    let title: String
    
    init(contentList: [NodeEntity], photoByDayList: [PhotoByDay], categoryDate: Date, title: String) {
        self.contentList = contentList
        self.photoByDayList = photoByDayList
        self.categoryDate = categoryDate
        self.title = title
    }

    var attributedTitle: AttributedString {
        AttributedString()
    }
}
