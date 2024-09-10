import MEGADesignToken
import SwiftUI

struct FeatureRow: View {
    let feature: FeatureDetails

    var body: some View {
        HStack(spacing: 0) {
            Text(feature.title)
                .font(.footnote)
                .bold()
                .multilineTextAlignment(.leading)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(2.0)

            if let icon = feature.freeIconName {
                Image(icon)
                    .resizable()
                    .frame(width: 28, height: 28)
                    .frame(maxWidth: .infinity)
            } else {
                Text(feature.freeText ?? "")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                    .frame(maxWidth: .infinity)
                    .padding(2.0)
            }

            if let icon = feature.proIconName {
                Image(icon)
                    .resizable()
                    .frame(width: 28, height: 28)
                    .frame(maxWidth: .infinity)
            } else {
                Text(feature.proText ?? "")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                    .frame(maxWidth: .infinity)
                    .padding(2.0)
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 8.0)
    }
}
