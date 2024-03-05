import MEGADesignToken
import SwiftUI

struct NotificationItemContentView: View {
    let viewModel: NotificationItemViewModel
    
    @Environment(\.colorScheme) var colorScheme
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color(red: 0.820, green: 0.820, blue: 0.820) : Color(red: 0.318, green: 0.318, blue: 0.318)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.notification.title)
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : Color(UIColor.label))
                
                Text(viewModel.notification.description)
                    .font(.footnote)
                    .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : Color(UIColor.label))
                
                if let bannerImageURL = viewModel.notification.bannerImageURL {
                    AsyncImage(
                        url: bannerImageURL,
                        content: { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                        },
                        placeholder: {
                            ProgressView()
                        }
                    )
                }
                
                if let footerText = viewModel.footerText() {
                    Text(footerText)
                        .font(.caption)
                        .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.secondary.swiftUI : secondaryTextColor)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
