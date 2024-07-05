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
                .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : .primary)
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
                    .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.secondary.swiftUI : .secondary)
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
                    .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.secondary.swiftUI: .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(2.0)
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 8.0)
    }
}
