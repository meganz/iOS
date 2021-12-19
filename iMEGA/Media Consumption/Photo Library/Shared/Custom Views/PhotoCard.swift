import SwiftUI

@available(iOS 14.0, *)
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
                    .position(x: proxy.size.width / 2,
                              y: proxy.size.height / 2)
                
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
            .background(Color(colorScheme == .dark ? UIColor.systemBackground : UIColor.mnz_grayF7F7F7()))
        }
        .cornerRadius(12)
        .onAppear {
            viewModel.loadThumbnail()
        }
        .onDisappear {
            viewModel.resetThumbnail()
        }
    }
}
