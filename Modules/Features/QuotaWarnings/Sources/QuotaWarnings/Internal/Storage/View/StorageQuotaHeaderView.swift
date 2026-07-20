import MEGADesignToken
import SwiftUI

struct StorageQuotaHeaderView: View {
    private let header: StorageQuotaHeader

    init(header: StorageQuotaHeader) {
        self.header = header
    }

    var body: some View {
        VStack(spacing: TokenSpacing._5) {
            Image(uiImage: header.image)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
            VStack(spacing: TokenSpacing._3) {
                Text(header.title)
                    .font(.title.bold())
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                Text(header.subtitle)
                    .font(.callout.weight(.regular))
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    StorageQuotaHeaderView(header: StorageQuotaHeader(
        image: .init(),
        title: "Your storage is 90% full",
        subtitle: "Upgrade your plan before you run out of space"
    ))
    .padding()
}
