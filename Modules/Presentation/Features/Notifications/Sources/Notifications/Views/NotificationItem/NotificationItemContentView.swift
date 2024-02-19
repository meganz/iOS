import MEGADesignToken
import SwiftUI

struct NotificationItemContentView: View {
    let viewModel: NotificationItemViewModel
    
    @Environment(\.colorScheme) var colorScheme
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color(red: 0.820, green: 0.820, blue: 0.820) : Color(red: 0.318, green: 0.318, blue: 0.318)
    }
    
    var body: some View {
        Group {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.notification.title)
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : Color(UIColor.label))
                    
                    Text(viewModel.notification.description)
                        .font(.footnote)
                        .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : Color(UIColor.label))
                    
                    if let bottomImageURL = viewModel.notification.bottomImageURL {
                        AsyncImage(
                            url: bottomImageURL,
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
                    
                    Text(viewModel.footerText())
                        .font(.caption)
                        .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.secondary.swiftUI : secondaryTextColor)
                }
                
                if let rightThumbnailURL = viewModel.notification.rightThumbnailURL {
                    Spacer()
                    
                    AsyncImage(
                        url: rightThumbnailURL,
                        content: { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80)
                        },
                        placeholder: {
                            ProgressView()
                        }
                    )
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
