import Foundation
import MEGADomain

public protocol PhotoSection: PhotoChronologicalCategory where Content == NodeEntity {
    var title: String { get }

    var attributedTitle: AttributedString { get }
}

extension PhotoSection {
    public var coverPhoto: NodeEntity? {
        contentList.first?.coverPhoto
    }
}

public class PhotoDateSection: PhotoSection {
    public var id: String { title }
    public let contentList: [NodeEntity]
    public let photoByDayList: [PhotoByDay]
    public let categoryDate: Date
    public let title: String
    
    init(contentList: [NodeEntity], photoByDayList: [PhotoByDay], categoryDate: Date, title: String) {
        self.contentList = contentList
        self.photoByDayList = photoByDayList
        self.categoryDate = categoryDate
        self.title = title
    }

    public var attributedTitle: AttributedString {
        AttributedString()
    }
}
