import Combine
import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct NotificationItemContentView: View {
    @ObservedObject var viewModel: NotificationItemViewModel
    
    @Environment(\.colorScheme) var colorScheme
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color(red: 0.820, green: 0.820, blue: 0.820) : Color(red: 0.318, green: 0.318, blue: 0.318)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.notification.title)
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : Color(UIColor.label))
                    
                    Text(viewModel.notification.description)
                        .font(.footnote)
                        .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : Color(UIColor.label))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if let icon = viewModel.icon {
                    Spacer()
                    Image(uiImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80)
                }
            }
            
            if let imageBanner = viewModel.imageBanner {
                Image(uiImage: imageBanner)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
            }
            
            if let footerText = viewModel.footerText() {
                Text(footerText)
                    .font(.caption)
                    .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.secondary.swiftUI : secondaryTextColor)
            }
        }
        .task {
            await viewModel.preloadImages()
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
