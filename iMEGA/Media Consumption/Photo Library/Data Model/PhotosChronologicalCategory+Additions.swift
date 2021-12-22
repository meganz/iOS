import Foundation
import SwiftUI

extension PhotosChronologicalCategory {
    var overlay: Image? {
        guard let name = coverPhoto?.name else {
            return nil
        }
        
        if (name as NSString).mnz_isVideoPathExtension {
            return Image(Asset.Images.Generic.videoList.name)
        }
        
        return nil
    }
}
