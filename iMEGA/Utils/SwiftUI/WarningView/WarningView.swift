import SwiftUI

struct WarningView: View {
    @ObservedObject var viewModel: WarningViewModel
    
    var body: some View {
        ZStack {
            Color(Colors.Banner.warningBannerBackground.name)
            HStack {
                Text(viewModel.warningType.description)
                    .font(.caption2.bold())
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(Color(Colors.Banner.warningTextColor.name))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 5))
                    .onTapGesture {
                        viewModel.tapAction()
                    }
                
                if viewModel.isShowCloseButton {
                    Spacer()
                    warningCloseButton
                }
            }
        }
        .frame(height: viewModel.isHideWarningView ? 0 : nil)
        .opacity(viewModel.isHideWarningView ? 0 : 1)
        .edgesIgnoringSafeArea(.all)
    }

    private var warningCloseButton: some View {
        Button {
            viewModel.closeAction()
        } label: {
            Image(uiImage: Asset.Images.Banner.closeCircle.image)
                .padding()
        }
    }
}
