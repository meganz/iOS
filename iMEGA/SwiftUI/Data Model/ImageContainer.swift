import Foundation
import SwiftUI

struct ImageContainer {
    let image: Image
    var isPlaceholder = false
}

extension ImageContainer {
    init?(image: Image?, isPlaceholder: Bool = false) {
        guard let image = image else {
            return nil
        }
        
        self.init(image: image, isPlaceholder: isPlaceholder)
    }
}
