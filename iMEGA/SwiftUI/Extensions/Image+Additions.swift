import SwiftUI
import UIKit

extension Image {
    @available(iOS 14.0, *)
    init(_ color: Color, _ size: CGSize = CGSize(width: 1, height: 1)) {
        let uiImage = UIColor(color).image(withSize: size)
        self.init(uiImage: uiImage)
    }
    
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
