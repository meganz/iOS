import Foundation
import UIKit

struct AudioPlaylistItem: Identifiable {
    let id: String

    let title: String

    let artist: String?

    let thumbnail: UIImage?

    let isCurrent: Bool
}
