import SwiftUI

#Preview("Button Catalog") {
    VStack {
        Text("Design token")
        PrimaryActionButtonView(title: "Primary", action: {})
        SecondaryActionButtonView(title: "Secondary", action: {})
    }
    .padding()
}
