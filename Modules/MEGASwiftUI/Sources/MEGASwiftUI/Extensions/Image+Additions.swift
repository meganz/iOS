import SwiftUI
import UIKit

public extension Image {
    init?(uiImage: UIImage?) {
        guard let image = uiImage else {
            return nil
        }
        
        self.init(uiImage: image)
    }
    
    init?(contentsOfFile path: String?) {
        guard let path = path else {
            return nil
        }
        
        self.init(uiImage: UIImage(contentsOfFile: path))
    }
}
