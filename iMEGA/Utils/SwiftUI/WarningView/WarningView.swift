import SwiftUI

struct WarningView: View {
    @ObservedObject var viewModel: WarningViewModel
    
    var body: some View {
        HStack {
            Text(viewModel.warningType.description)
                .font(.caption2.bold())
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(MEGAAppColor.Banner.bannerWarningText.color)
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
        .padding(5.0)
        .opacity(viewModel.isHideWarningView ? 0 : 1)
            .background(
                GeometryReader { geometry in
                    MEGAAppColor.Banner.bannerWarningBackground.color
                        .onAppear {
                            viewModel.onHeightChange?(geometry.size.height)
                        }
                        .onChange(of: geometry.size.height) { newHeight in
                            viewModel.onHeightChange?(newHeight)
                        }
                }
            )
    }
    
    private var warningCloseButton: some View {
        Button {
            viewModel.closeAction()
        } label: {
            Image(.closeCircle)
                .padding()
        }
    }
}
