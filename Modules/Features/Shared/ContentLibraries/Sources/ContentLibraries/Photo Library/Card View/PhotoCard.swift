import MEGADesignToken
import SwiftUI

struct PhotoCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    private let badgeTitle: String?
    private let content: Content
    
    @ObservedObject var viewModel: PhotoCardViewModel
    
    init(viewModel: PhotoCardViewModel, badgeTitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.viewModel = viewModel
        self.badgeTitle = badgeTitle
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                CardImage(container: viewModel.thumbnailContainer)
                    .position(x: proxy.size.width / CGFloat(2),
                              y: proxy.size.height / CGFloat(2))
                
                VStack {
                    content
                        .photoCardTitle()
                    
                    Spacer()
                    
                    if let title = badgeTitle {
                        NumberBadge(title: title)
                            .photoCardNumber()
                    }
                }
            }
            .background(badgeBackgroundColor)
        }
        .cornerRadius(12)
        .contentShape(Rectangle())
        .task { await viewModel.loadThumbnail() }
        .task {
            if #available(iOS 16, *) {
                await viewModel.monitorInheritedSensitivityChanges()
            } else {
                await viewModel.monitorPhotoSensitivityChanges()
            }
        }
    }
    
    private var badgeBackgroundColor: Color {
        colorScheme == .light ? TokenColors.Background.surface1.swiftUI : TokenColors.Background.surface2.swiftUI
    }
}
