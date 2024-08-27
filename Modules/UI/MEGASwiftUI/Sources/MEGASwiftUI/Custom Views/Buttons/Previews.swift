import SwiftUI

#Preview("Button Catalog") {
    VStack {
        VStack {
            Text("Design token")
            PrimaryActionButtonView(
                isDesignTokenEnabled: true,
                title: "Primary",
                action: {}
            )
            SecondaryActionButtonView(
                isDesignTokenEnabled: true,
                title: "Secondary",
                action: {}
            )

        }
        Spacer().frame(height: 40)
        VStack {
            Text("Legacy colors")
            PrimaryActionButtonView(
                isDesignTokenEnabled: false,
                title: "Primary",
                action: {}
            )
            SecondaryActionButtonView(
                isDesignTokenEnabled: false,
                title: "Secondary",
                action: {}
            )
        }
    }
    .padding()
}
