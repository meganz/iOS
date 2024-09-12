import MEGADesignToken
import SwiftUI

struct DetailDisclosureView: View {
    @Environment(\.layoutDirection) var layoutDirection
    @Environment(\.colorScheme) private var colorScheme

    private enum Constants {
        static let disclosureOpacity: CGFloat = 0.6
        static let disclosureIndicator = "chevron.right"
    }
    
    let text: String
    let detail: String?
    let requiresPadding: Bool
    let verticalAlignment: VerticalAlignment
    let action: (() -> Void)
    
    init(
        text: String,
        detail: String? = nil,
        requiresPadding: Bool = true,
        verticalAlignment: VerticalAlignment = .center,
        action: @escaping (() -> Void)
    ) {
        self.text = text
        self.detail = detail
        self.requiresPadding = requiresPadding
        self.verticalAlignment = verticalAlignment
        self.action = action
    }

    var body: some View {
        VStack {
            if requiresPadding {
                content()
                    .padding(.horizontal)
            } else {
                content()
            }
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
    
    private func content() -> some View {
        HStack(alignment: verticalAlignment) {
            Text(text)
                .font(.body)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
            Spacer()
            if let detail {
                Text(detail)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            }
            Image(systemName: Constants.disclosureIndicator)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                .flipsForRightToLeftLayoutDirection(layoutDirection == .rightToLeft)
        }
    }
}
