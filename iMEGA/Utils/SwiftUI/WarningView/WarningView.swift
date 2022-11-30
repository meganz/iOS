import SwiftUI

struct WarningView: View {
    @ObservedObject var viewModel: WarningViewModel
    
    var body: some View {
        Text(viewModel.warningType.description)
            .font(.caption2.bold())
            .fixedSize(horizontal: false, vertical: true)
            .foregroundColor(Color(Colors.Banner.warningTextColor.name))
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity)
            .padding(EdgeInsets(top: 10, leading: 5, bottom: 10, trailing: 5))
            .background(Color(Colors.Banner.warningBannerBackground.name))
            .onTapGesture {
                viewModel.tapAction()
            }
            .edgesIgnoringSafeArea(.all)
    }
}
