import Foundation
import SwiftUI

extension PhotoChronologicalCategory {
    var overlay: Image? {
        guard coverPhoto?.name.fileExtensionGroup.isVideo == true else { return nil }
        return Image(Asset.Images.Generic.videoList.name)
    }
}
