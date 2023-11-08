import SwiftUI

public struct HorizontalImageTextLabel: View {
    let image: UIImage?
    let text: String
    
    public init(image: UIImage?, text: String) {
        self.image = image
        self.text = text
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            Image(uiImage: image)
            Text(text)
                .fontWeight(.bold)
                .font(.title)
        }
    }
}
