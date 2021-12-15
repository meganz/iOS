import SwiftUI
import UIKit

extension Image {
    @available(iOS 14.0, *)
    init(_ color: Color, _ size: CGSize = CGSize(width: 1, height: 1)) {
        let uiImage = UIColor(color).image(withSize: size)
        self.init(uiImage: uiImage)
    }
}
