import Foundation

struct SectionDetail: Hashable {
    let title: String
    let link: String
    
    static let offline = SectionDetail(title: Strings.Localizable.offline, link: "mega://widget.quickaccess.offline")

    static let recents = SectionDetail(title: Strings.Localizable.recents, link: "mega://widget.quickaccess.recents")

    static let favourites = SectionDetail(title: Strings.Localizable.favourites, link: "mega://widget.quickaccess.favourites")

    static let availableSections = [offline, recents, favourites]
    
    static let defaultSection = SectionDetail.offline
}
