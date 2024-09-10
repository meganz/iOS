import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct NotificationItemContentView: View {
    @ObservedObject var viewModel: NotificationItemViewModel
    @State private var iconImageHeight = CGFloat.zero
    
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
                        .foregroundStyle(TokenColors.Text.primary.swiftUI)
                    
                    Text(viewModel.notification.description)
                        .font(.footnote)
                        .foregroundStyle(TokenColors.Text.primary.swiftUI )
                    
                    if !viewModel.hasBannerImage {
                        footerText
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(in: .local)
                
                if !viewModel.hasBannerImage,
                   viewModel.hasIcon {
                    Spacer()
                    
                    VStack {
                        Image(uiImage: viewModel.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80)
                    }
                    .frame(minHeight: iconImageHeight)
                }
            }
            
            if viewModel.hasBannerImage {
                Image(uiImage: viewModel.imageBanner)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .frame(height: 115)
                
                footerText
            }
        }
        .task {
            await viewModel.preloadImages()
        }
        .fixedSize(horizontal: false, vertical: true)
        .onPreferenceChange(FramePreferenceKey.self) {
            iconImageHeight = $0.height
        }
    }
    
    @ViewBuilder
    private var footerText: some View {
        if let footerText = viewModel.footerText() {
            Text(footerText)
                .font(.caption)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
        }
    }
}
