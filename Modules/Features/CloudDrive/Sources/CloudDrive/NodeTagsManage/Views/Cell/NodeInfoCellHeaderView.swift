import MEGADesignToken
import SwiftUI

public struct NodeInfoCellHeaderView: View {
    @Environment(\.colorScheme) private var colorScheme

    private let title: String
    private let topPadding: CGFloat

    public init(title: String, topPadding: CGFloat = 30) {
        self.title = title
        self.topPadding = topPadding
    }

    public var body: some View {
        VStack {
            Text(title)
                .font(.footnote)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

            TokenColors.Border.strong.swiftUI
                .frame(height: 0.5)
        }
        .padding(.top, topPadding)
        .background()
    }
}
