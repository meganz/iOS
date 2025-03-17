import MEGADesignToken
import SwiftUI

public struct DisclosureView: View {
    private enum Constants {
        static let disclosureOpacity: CGFloat = 0.6
    }
    
    let image: Image
    let text: String
    let action: (() -> Void)
    @Environment(\.layoutDirection) var layoutDirection

    private let disclosureIndicator = "chevron.right"

    public init(
        image: Image,
        text: String,
        action: @escaping () -> Void
    ) {
        self.image = image
        self.text = text
        self.action = action
    }
    
    public var body: some View {
        VStack {
            Divider()
            HStack {
                image
                Text(text)
                    .font(.body)
                Spacer()
                Image(systemName: disclosureIndicator)
                    .foregroundColor(TokenColors.Icon.secondary.swiftUI.opacity(Constants.disclosureOpacity))
                    .flipsForRightToLeftLayoutDirection(layoutDirection == .rightToLeft)
            }
            .padding(.horizontal)
            Divider()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
}
