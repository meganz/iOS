import Foundation
import MEGAAssets
import SwiftUI

extension PhotoChronologicalCategory {
    var overlay: Image? {
        guard coverPhoto?.name.fileExtensionGroup.isVideo == true else { return nil }
        return MEGAAssetsImageProvider.image(named: .videoList)
    }
}
