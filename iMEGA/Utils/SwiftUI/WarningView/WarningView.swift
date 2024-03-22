import MEGADesignToken
import SwiftUI

struct WarningView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: WarningViewModel
    
    private var bannerTextColor: Color {
        Color(UIColor.isDesignTokenEnabled() ? TokenColors.Text.primary : UIColor.bannerWarningText)
    }
    private var bannerBgColor: Color {
        Color(UIColor.isDesignTokenEnabled() ? TokenColors.Notifications.notificationWarning : UIColor.bannerWarningBackground)
    }
    
    var body: some View {
        HStack {
            Text(viewModel.warningType.description)
                .font(.caption2.bold())
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(bannerTextColor)
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
                    bannerBgColor
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
