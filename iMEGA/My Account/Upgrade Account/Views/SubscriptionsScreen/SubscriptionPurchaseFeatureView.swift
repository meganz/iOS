import MEGADesignToken
import SwiftUI

struct SubscriptionPurchaseFeatureView: View {
    let image: Image
    let title: String
    let description: String?

    init(image: Image, title: String, description: String? = nil) {
        self.image = image
        self.title = title
        self.description = description
    }

    var body: some View {
        HStack(alignment: .center) {
            image
                .resizable()
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)

                if let description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
