import MEGAAssets
import MEGADomain
import SwiftUI

struct DuplicatedItem {
    var name: String
    var rename: String?
    var isFile: Bool
    var size: String
    var date: String
    var imagePlaceholder: Image
    var collisionFileSize: String?
    var collisionFileDate: String?
    var collisionNodeHandle: HandleEntity?
}
