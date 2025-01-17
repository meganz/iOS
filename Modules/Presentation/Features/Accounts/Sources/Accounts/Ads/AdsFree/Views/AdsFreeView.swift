import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct AdsFreeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: AdsFreeViewModel
    @State private var contentHeight: CGFloat? = .zero
    
    var body: some View {
        ZStack {
            TokenColors.Background.page.swiftUI
                .edgesIgnoringSafeArea(.all)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {
                    headerView
                        .padding(.top, 40)
                    contentsView
                    bottomButtonsView
                        .padding(.bottom, 30)
                }
                .modifier(ConditionalFrameModifier(contentHeight: $contentHeight))
            }
            .task {
                await viewModel.setUpLowestProPlan()
            }
            .onAppear {
                viewModel.onAppear()
            }
            .frame(height: contentHeight)
            .frame(maxWidth: 768)
            .padding(.horizontal)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 10) {
            Image(uiImage: MEGAAssetsImageProvider.image(named: "onboardingHeader"))
            
            Text(Strings.Localizable.Ads.AdFree.Header.title)
                .font(.title3)
                .bold()
                .multilineTextAlignment(.center)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
            
            Text(Strings.Localizable.Ads.AdFree.Header.subTitle(viewModel.lowestProPlan.formattedPrice))
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var contentsView: some View {
        VStack(spacing: 30) {
            Group {
                ProPlanFeatureView(
                    image: MEGAAssetsImageProvider.image(named: "storage"),
                    title: Strings.Localizable.Ads.AdFree.Content.GenerousStorage.title,
                    message: Strings.Localizable.Ads.AdFree.Content.GenerousStorage.message(viewModel.lowestProPlan.storage)
                )
                ProPlanFeatureView(
                    image: MEGAAssetsImageProvider.image(named: "pieChart"),
                    title: Strings.Localizable.Ads.AdFree.Content.TransferSharing.title,
                    message: Strings.Localizable.Ads.AdFree.Content.TransferSharing.message
                )
                ProPlanFeatureView(
                    image: MEGAAssetsImageProvider.image(named: "securityLock"),
                    title: Strings.Localizable.Ads.AdFree.Content.AdditionalSecurity.title,
                    message: Strings.Localizable.Ads.AdFree.Content.AdditionalSecurity.message
                )
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var bottomButtonsView: some View {
        VStack(spacing: 15) {
            PrimaryActionButtonView(title: Strings.Localizable.Ads.AdFree.Button.viewProPlans) {
                viewModel.didTapViewProPlansButton()
            }
            
            SecondaryActionButtonView(title: Strings.Localizable.Ads.AdFree.Button.skip) {
                viewModel.didTapSkipButton()
                dismiss()
            }
        }
    }
}

private struct ConditionalFrameModifier: ViewModifier {
    @Binding var contentHeight: CGFloat?
    
    @ViewBuilder
    public func body(content: Content) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            content
                .frame(in: .local)
                .onPreferenceChange(FramePreferenceKey.self) { value in
                    Task { @MainActor in
                        contentHeight = value.height
                    }
                }
        } else {
            content
                .onFirstAppear(perform: {
                    contentHeight = nil
                })
        }
    }
}
