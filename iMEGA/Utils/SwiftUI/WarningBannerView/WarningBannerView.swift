import MEGADesignToken
import SwiftUI

struct WarningBannerView: View {
    @ObservedObject var viewModel: WarningBannerViewModel
    
    private var bannerBgColor: Color {
        switch viewModel.warningType.severity {
        case .critical: Color(TokenColors.Notifications.notificationError)
        case .warning: Color(TokenColors.Notifications.notificationWarning)
        }
    }
    private let bannerTextColor = Color(TokenColors.Text.primary)
    
    var body: some View {
        if viewModel.applyNewDesign {
            bannerView(newBannerContent)
        } else {
            bannerView(bannerDescriptionContent)
        }
    }
    
    private var warningCloseButton: some View {
        Button {
            viewModel.onCloseButtonTapped()
        } label: {
            Image(viewModel.applyNewDesign ? .closeBannerButton : .closeCircle)
                .padding(10)
        }
    }
    
    private func bannerView<Content: View>(_ content: @escaping () -> Content) -> some View {
        HStack(alignment: .top) {
            content()
            
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
                    .onAppear { viewModel.onHeightChange?(geometry.size.height) }
                    .onChange(of: geometry.size.height) { newHeight in
                        viewModel.onHeightChange?(newHeight)
                    }
            }
        )
    }
    
    private func bannerDescriptionContent() -> some View {
        HStack {
            Text(viewModel.warningType.description)
                .font(viewModel.applyNewDesign ? .subheadline : .caption2.bold())
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(bannerTextColor)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(viewModel.applyNewDesign ? EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5) : EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 5))
                .onTapGesture {
                    viewModel.onBannerTapped()
                }
        }
    }
    
    private func newBannerContent() -> some View {
        HStack(alignment: .top) {
            if let iconName = viewModel.warningType.iconName {
                Image(iconName)
                    .padding(.leading, 5)
            }
            
            VStack(alignment: .leading) {
                if let title = viewModel.warningType.title {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(bannerTextColor)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(EdgeInsets(top: 2, leading: 5, bottom: 2, trailing: 5))
                }
                
                bannerDescriptionContent()
                
                if let buttonTitle = viewModel.warningType.actionText {
                    Button {
                        viewModel.onActionButtonTapped()
                    } label: {
                        Text(buttonTitle)
                            .font(.callout)
                            .underline()
                            .foregroundStyle(TokenColors.Link.primary.swiftUI)
                            .padding(EdgeInsets(top: 2, leading: 5, bottom: 2, trailing: 5))
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack {
        let warningData: [(WarningBannerType, Bool)] = [
            (.noInternetConnection, false),
            (.limitedPhotoAccess, false),
            (.contactsNotVerified, false),
            (.contactNotVerifiedSharedFolder("Folder 1"), false),
            (.backupStatusError("Folder in MEGA can’t be located as it’s been moved or deleted, or you might not have access."), false),
            (.fullStorageOverQuota, false),
            (.almostFullStorageOverQuota, true)
        ]
       
        ForEach(0..<warningData.count, id: \.self) { index in
            let (warningType, showCloseButton) = warningData[index]
            WarningBannerView(
                viewModel:
                    WarningBannerViewModel(
                    warningType: warningType,
                    isShowCloseButton: showCloseButton
                )
            )
        }
        Spacer()
    }
}
