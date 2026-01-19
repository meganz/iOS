import MEGADesignToken
import SwiftUI

public struct RoundedPrimaryImageButton: View {
    private let action: @MainActor () -> Void
    private let image: Image
    private let isLiquidGlassEnabled: Bool
    
    public init(image: Image, isLiquidGlassEnabled: Bool = false, action: @escaping @MainActor () -> Void) {
        self.image = image
        self.isLiquidGlassEnabled = isLiquidGlassEnabled
        self.action = action
    }
    
    public var body: some View {
        buttonView
    }
    
    @ViewBuilder
    private var buttonView: some View {
        if #available(iOS 26.0, *), isLiquidGlassEnabled {
            Button(action: action) {
                imageContent
            }
            .glassEffect(
                .regular
                    .tint(TokenColors.Button.primary.swiftUI.opacity(0.7))
                    .interactive(),
                in: Circle()
            )
        } else {
            Button(action: action) {
                imageContent
                    .background(TokenColors.Button.primary.swiftUI)
                    .clipShape(RoundedRectangle(cornerRadius: TokenRadius.large))
            }
        }
    }
    
    private var imageContent: some View {
        image
            .foregroundStyle(TokenColors.Icon.inverse.swiftUI)
            .frame(width: 56, height: 56)
    }
}
