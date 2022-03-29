import SwiftUI

struct PhotosBannerView: View {
    @ObservedObject var viewModel: PhotosBannerViewModel
    var router: PhotosBannerViewRouter
    
    private var textFont: Font {
        guard #available(iOS 14.0, *) else {
            return .caption.bold()
        }
        return .caption2.bold()
    }
    
    var body: some View {
        Text(viewModel.message)
            .font(textFont)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundColor(Color(Colors.Banner.warningTextColor.name))
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity)
            .padding(EdgeInsets(top: 10, leading: 5, bottom: 10, trailing: 5))
            .background(Color(Colors.Banner.warningBannerBackground.name))
            .onTapGesture {
                router.goToSettings()
            }
    }
}
