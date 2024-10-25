import Foundation

struct DownloadLinkDetails: Decodable {
    let link: String

    enum CodingKeys: String, CodingKey {
        case link = "self"
    }
}
