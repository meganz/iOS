import Foundation
import SwiftUI

struct ImageContainer {
    let image: Image
    var isPlaceholder = false
    var overlay: Image? = nil
}

extension ImageContainer {
    init?(image: Image?, isPlaceholder: Bool = false, overlay: Image? = nil) {
        guard let image = image else {
            return nil
        }
        
        self.init(image: image, isPlaceholder: isPlaceholder, overlay: overlay)
    }
}
