import Foundation

class PhotoDateSection: PhotoChronologicalCategory {
    var categoryDate: Date {
        Date()
    }
    
    var coverPhoto: NodeEntity? {
        nil
    }
    
    var allPhotos: [NodeEntity] {
        []
    }
    
    var photoByDayList: [PhotoByDay] {
        return []
    }
    
    var title: String = ""

    @available(iOS 15.0, *)
    var attributedTitle: AttributedString {
        AttributedString("")
    }
}
