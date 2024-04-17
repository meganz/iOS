import MEGADesignToken
import SwiftUI

public struct IconButton: View {
    let image: Image
    let title: String
    let tintColor: Color
    let action: () -> Void
    
    public init(
        image: Image,
        title: String,
        tintColor: Color,
        action: @escaping () -> Void
    ) {
        self.image = image
        self.title = title
        self.tintColor = tintColor
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: TokenSpacing._2) {
                image
                    .renderingMode(.template)
                Text(title)
            }
            .font(.subheadline)
            .foregroundStyle(tintColor)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    Group {
        IconButton(
            image: Image(systemName: "plus"),
            title: "Plain",
            tintColor: Color.green,
            action: {}
        )
    }
}
