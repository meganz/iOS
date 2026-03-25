import MEGADesignToken
import MEGAInfrastructure
import SwiftUI

public struct RoundedPrimaryImageButton: View {
    private let action: @MainActor () -> Void
    private let image: Image
    
    public init(image: Image, action: @escaping @MainActor () -> Void) {
        self.image = image
        self.action = action
    }
    
    public var body: some View {
        buttonView
    }
    
    @ViewBuilder
    private var buttonView: some View {
        // on iOS 26.0 beta the Swift runtime crashes when instantiating a value of a type
        // that includes the glassEffect modifier, due to __swift_instantiateConcreteTypeFromMangledNameV2
        // failing to instantiate the concrete glassEffect type. Skip on iOS 26.0 beta and use the fallback directly.
        if #available(iOS 26.0, *), !ProcessInfo.isRunningIOS26_0Beta {
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
