import MEGADesignToken
import SwiftUI

public struct RoundedPrimaryImageButton: View {

    private let action: @MainActor () -> Void
    private let image: Image

    public init(image: Image, action: @escaping @MainActor () -> Void) {
        self.image = image
        self.action = action
    }

    public var body: some View {
        Button(action: action, label: {
            image
                .foregroundStyle(TokenColors.Icon.inverse.swiftUI)
                .frame(width: 56, height: 56)
                .background(TokenColors.Button.primary.swiftUI)
                .clipShape(RoundedRectangle(cornerRadius: TokenRadius.large))
        })
    }
}
