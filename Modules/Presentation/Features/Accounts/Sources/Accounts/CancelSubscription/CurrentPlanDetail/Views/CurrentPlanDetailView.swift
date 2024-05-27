import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct CurrentPlanDetailView: View {
    @ObservedObject var viewModel: CurrentPlanDetailViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            navigationBar
                .frame(height: 60)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    headerView()
                    currentPlanDetailBodyView()
                    footerView()
                }
                .padding(.bottom, 20.0)
            }
            .padding(.horizontal, 16.0)
            Spacer()
        }
        .ignoresSafeArea(edges: [.top, .bottom])
        .background(isDesignTokenEnabled ? TokenColors.Background.surface1.swiftUI : .clear )
        .task {
            viewModel.setupFeatureList()
        }
    }
    
    @ViewBuilder
    private var navigationBar: some View {
        NavigationBarView(
            leading: {
                Button {
                    viewModel.dismiss()
                } label: {
                    Text(Strings.Localizable.cancel)
                        .font(.body)
                        .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : .primary)
                }
            },
            backgroundColor: isDesignTokenEnabled ? TokenColors.Background.surface1.swiftUI : .clear
        )
    }
    
    @ViewBuilder
    private func featureListHeaderView() -> some View {
        HStack {
            Text(Strings.Localizable.Feature.title)
                .font(.footnote)
                .bold()
                .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : .primary)
                .textCase(nil)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(Strings.Localizable.free)
                .font(.footnote)
                .bold()
                .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : .primary)
                .textCase(nil)
                .frame(maxWidth: .infinity)
           
            Text(viewModel.currentPlanName)
                .font(.footnote)
                .bold()
                .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : .primary)
                .textCase(nil)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 8.0)
        .frame(height: 40)
        .background(isDesignTokenEnabled ? TokenColors.Background.surface2.swiftUI : Color(red: 0.847, green: 0.851, blue: 0.859))
    }
    
    @ViewBuilder
    private func currentPlanDetailBodyView() -> some View {
        VStack(spacing: 10) {
            featureListHeaderView()
            
            ForEach(viewModel.features) { featureDetail in
                FeatureRow(feature: featureDetail)
                Divider()
            }
        }
        .background(isDesignTokenEnabled ? TokenColors.Background.page.swiftUI : .white)
        .cornerRadius(8.0)
    }
    
    @ViewBuilder
    private func headerView() -> some View {
        VStack(spacing: 10) {
            Text(Strings.Localizable.Cancellation.Subscription.Header.title)
                .font(.title3)
                .bold()
                .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : .primary)
                .textCase(nil)
                .padding(.top, 10)
            
            Text(Strings.Localizable.Cancellation.Subscription.Header.message(viewModel.currentPlanStorageUsed))
                .font(.subheadline)
                .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.secondary.swiftUI : .secondary)
                .textCase(nil)
                .multilineTextAlignment(.center)
                .padding(.top, 5)
                .padding(.bottom, 15)
        }
    }
    
    @ViewBuilder
    private func footerView() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            PrimaryActionButtonView(title: Strings.Localizable.Cancellation.Subscription.Keep.Pro.Plan.Button.title(viewModel.currentPlanName)) {
                viewModel.dismiss()
            }
            
            SecondaryActionButtonView(title: Strings.Localizable.Cancellation.Subscription.Continue.Cancellation.Button.title) {
                // Action for continuing with cancellation
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 30)
    }
}
