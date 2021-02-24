import Foundation

struct SectionDetail: Hashable {
    let title: String
    let link: String
    
    static let offline = SectionDetail(title: NSLocalizedString("offline", comment: "Title of the Offline section"), link: "mega://widget.quickaccess.offline")

    static let recents = SectionDetail(title: NSLocalizedString("Recents", comment: "Title for the recents section."), link: "mega://widget.quickaccess.recents")

    static let favourites = SectionDetail(title: NSLocalizedString("Favourites", comment: "Text for title for favourite nodes"), link: "mega://widget.quickaccess.favourites")

    static let availableSections = [offline, recents, favourites]
    
    static let defaultSection = SectionDetail.offline
}
