import SwiftUI

public struct HorizontalImageTextLabel: View {
    let image: Image?
    let text: String
    
    public init(image: Image?, text: String) {
        self.image = image
        self.text = text
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            image
            Text(text)
                .fontWeight(.bold)
                .font(.title)
        }
    }
}
