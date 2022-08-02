import Foundation

struct HomeSearchResultFileViewModel {

    let handle: HandleEntity

    let name: String

    let folder: String

    let fileType: String

    let thumbnail: ((@escaping (UIImage?) -> Void) -> Void)?

    let moreAction: (HandleEntity, UIButton) -> Void
}

extension HomeSearchResultFileViewModel {

    static func < (lhs: HomeSearchResultFileViewModel, rhs: HomeSearchResultFileViewModel) -> Bool {
        lhs.name < rhs.name
    }

    static func ==(lhs: HomeSearchResultFileViewModel, rhs: HomeSearchResultFileViewModel) -> Bool {
        return lhs.handle == rhs.handle
    }
}
