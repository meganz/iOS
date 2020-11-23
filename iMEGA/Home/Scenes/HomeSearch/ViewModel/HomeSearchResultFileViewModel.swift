import Foundation

struct HomeSearchResultFileViewModel {

    let handle: MEGAHandle

    let name: String

    let folder: String

    let fileType: String

    let thumbnail: ((@escaping (UIImage?) -> Void) -> Void)?

    let moreAction: (MEGAHandle) -> Void
}

extension HomeSearchResultFileViewModel {

    static func < (lhs: HomeSearchResultFileViewModel, rhs: HomeSearchResultFileViewModel) -> Bool {
        lhs.name < rhs.name
    }

    static func ==(lhs: HomeSearchResultFileViewModel, rhs: HomeSearchResultFileViewModel) -> Bool {
        return lhs.handle == rhs.handle
    }
}
