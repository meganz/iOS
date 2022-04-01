import SwiftUI

struct WarningView: View {
    @ObservedObject var viewModel: WarningViewModel
    
    private var textFont: Font {
        guard #available(iOS 14.0, *) else {
            return .caption.bold()
        }
        return .caption2.bold()
    }
    
    var body: some View {
        Text(viewModel.warningType.description)
            .font(textFont)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundColor(Color(Colors.Banner.warningTextColor.name))
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity)
            .padding(EdgeInsets(top: 10, leading: 5, bottom: 10, trailing: 5))
            .background(Color(Colors.Banner.warningBannerBackground.name))
            .onTapGesture {
                viewModel.tapAction()
            }
    }
}
