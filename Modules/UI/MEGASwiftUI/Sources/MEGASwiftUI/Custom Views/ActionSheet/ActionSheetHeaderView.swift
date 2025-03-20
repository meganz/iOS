import MEGADesignToken
import SwiftUI

public struct ActionSheetHeaderView: View {
    let headerIcon: Image?
    let title: String
    let subtitleIcon: Image?
    let subtitle: String
    let subtitleColor: UIColor

    public init(headerIcon: Image? = nil, title: String, subtitleIcon: Image? = nil, subtitle: String, subtitleColor: UIColor) {
        self.headerIcon = headerIcon
        self.title = title
        self.subtitleIcon = subtitleIcon
        self.subtitle = subtitle
        self.subtitleColor = subtitleColor
    }

    public var body: some View {
        HStack {
            if let headerIcon {
                headerIcon
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .padding(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 8))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                HStack {
                    if let subtitleIcon {
                        subtitleIcon
                            .renderingMode(.template)
                            .foregroundStyle(Color(subtitleColor))
                            .frame(width: 12, height: 12)
                    }
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color(subtitleColor))
                }
            }
            Spacer()
        }
    }
}
