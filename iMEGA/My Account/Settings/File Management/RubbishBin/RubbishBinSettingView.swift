import MEGAConnectivity
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import MEGAUIComponent
import SwiftUI

struct RubbishBinSettingView: View {
    @StateObject var viewModel: RubbishBinSettingViewModel
    @State private var isPresented = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            if !viewModel.isPaidAccount {
                MEGABanner(
                    subtitle: Strings.Localizable.Settings.FileManagement.RubbishBin.Upgrade.Info.title(viewModel.rubbishBinAutopurgePeriod),
                    buttonText: Strings.Localizable.upgrade,
                    state: .info,
                    type: .topAlert,
                    buttonAction: {
                        viewModel.onTapUpgradeButtton()
                    }
                )
            }
            
            VStack {
                Button(action: viewModel.onTapAutoPurgeCell) {
                    MEGAList(
                        title: Strings.Localizable.Settings.FileManagement.RubbishBin.AutoPurge.title,
                        subtitle: viewModel.autoPurgePeriodDisplayName
                    )
                    .trailingChevron()
                }
                .bottomSheet(
                    isPresented: $viewModel.isBottomSheetPresented,
                    detents: [.fixed(viewModel.isPaidAccount ? 540 : 230)],
                    showDragIndicator: true,
                    cornerRadius: TokenRadius.large) {
                        autoPurgePeriodListView
                    }
                
                Button {
                    isPresented = viewModel.isLoading ? false : true
                } label: {
                    MEGAList(
                        title: Strings.Localizable.emptyRubbishBin
                    )
                    .titleColor(TokenColors.Text.error.swiftUI)
                    .replaceTrailingView {
                        spinner()
                    }
                }
                .alert(isPresented: $isPresented) {
                    Alert(
                        title: Text(Strings.Localizable.Settings.FileManagement.RubbishBin.Clean.Warning.title),
                        message: Text(Strings.Localizable.emptyRubbishBinAlertTitle),
                        primaryButton: .cancel(
                            Text(Strings.Localizable.cancel),
                            action: { }
                        ),
                        secondaryButton: .default(
                            Text(Strings.Localizable.Settings.FileManagement.RubbishBin.Clean.Warning.empty),
                            action: {
                                viewModel.onTapEmptyBinButton()
                            }
                        )
                    )
                }
            }
        }
        .noInternetViewModifier()
        .snackBar($viewModel.snackBar)
        .pageBackground()
        .task {
            await viewModel.getRubbishBinAutopurgePeriod()
        }
    }
    
    // MARK: - Customized Views Build
    
    @ViewBuilder
    private func spinner( ) -> some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(width: 22, height: 22)
        } else {
            EmptyView()
        }
    }
    
    private var autoPurgePeriodListView: some View {
        VStack(spacing: TokenSpacing._2) {
            // Title View
            Text(Strings.Localizable.Settings.FileManagement.RubbishBin.AutoPurge.title)
                .font(.headline)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .padding(.top, TokenSpacing._12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, TokenSpacing._4)
            
            // List View
            VStack(spacing: .zero) {
                ForEach(viewModel.autoPurgePeriods) { period in
                    Button(action: {
                        viewModel.onTapAutoPurgeRow(with: period)
                    }, label: {
                        autoPurgePeriodRowView(period)
                    })
                }
            }
            .padding(.top, TokenSpacing._3)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .background(
            TokenColors.Background.surface1.swiftUI,
            ignoresSafeAreaEdges: .all
        )
    }
    
    private func autoPurgePeriodRowView(
        _ period: AutoPurgePeriod
    ) -> some View {
        HStack(spacing: .zero) {
            Text(viewModel.displayName(of: period))
                .font(.body)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
            
            Spacer()
            
            if period == viewModel.selectedAutoPurgePeriod {
                Image(.check)
                    .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
                    .frame(width: 32, height: 32, alignment: .center)
            }
        }
        .frame(height: 58)
        .padding(.horizontal, TokenSpacing._5)
    }
}
