import Foundation

protocol PhotoSection: PhotoChronologicalCategory where Content == NodeEntity {
    var title: String { get }

    @available(iOS 15.0, *)
    var attributedTitle: AttributedString { get }
}

extension PhotoSection {
    var coverPhoto: NodeEntity? {
        contentList.first?.coverPhoto
    }
}

class PhotoDateSection: PhotoSection {
    var contentList: [NodeEntity]
    
    init(contentList: [NodeEntity]) {
        self.contentList = contentList
    }
    
    var photoByDayList = [PhotoByDay]()
    var categoryDate = Date()
    var title = ""

    @available(iOS 15.0, *)
    var attributedTitle: AttributedString {
        AttributedString()
    }
}
