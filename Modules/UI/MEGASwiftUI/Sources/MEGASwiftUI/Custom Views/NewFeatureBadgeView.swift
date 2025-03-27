import MEGADesignToken
import MEGAL10n
import SwiftUI

public struct NewFeatureBadgeView: View {

    public init() {}

    public var body: some View {
        Text(Strings.Localizable.new)
            .font(.caption2)
            .bold()
            .foregroundColor(TokenColors.Text.onColor.swiftUI)
            .padding(
                EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4)
            )
            .background(TokenColors.Icon.brand.swiftUI)
            .cornerRadius(4)
    }
}
