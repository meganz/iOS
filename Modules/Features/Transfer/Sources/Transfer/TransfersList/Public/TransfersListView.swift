import MEGAAssets
import MEGADesignToken
import MEGAL10n
import Search
import SwiftUI

public struct TransfersListView: View {
    @StateObject private var viewModel: TransfersListViewModel

    public init() {
        _viewModel = StateObject(wrappedValue: TransfersListViewModel())
    }

    public init(viewModel: TransfersListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            if viewModel.hasAnyTransfers {
                tabBar
                Divider()
            }
            tabContent
        }
        .task { viewModel.seedCompletedPresence() }
        .task(id: viewModel.selectedTab) { await viewModel.observeSelectedTabItemCount() }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(TokenColors.Background.page.swiftUI)
        .navigationTitle(Strings.Localizable.transfers)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if viewModel.hasAnyTransfers {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {} label: {
                        MEGAAssets.Image.pauseMediumThinOutline
                            .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                    }
                    .disabled(true)

                    Button {} label: {
                        MEGAAssets.Image.moreVerticalMediumThinOutline
                            .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                    }
                    .disabled(true)
                }
            }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        if viewModel.selectedTab == .active, let activeContainer = viewModel.activeContainerViewModel {
            SearchResultsContainerView(viewModel: activeContainer)
        } else if viewModel.selectedTab == .completed, let completedContainer = viewModel.completedContainerViewModel {
            SearchResultsContainerView(viewModel: completedContainer)
        } else {
            emptyState
        }
    }

    private var tabBar: some View {
        HStack(spacing: TokenSpacing._7) {
            ForEach(TransfersTab.allCases) { tab in
                tabButton(tab)
            }
            Spacer()
        }
        .padding(.horizontal, TokenSpacing._5)
        .padding(.top, TokenSpacing._3)
    }

    private func tabButton(_ tab: TransfersTab) -> some View {
        let isSelected = viewModel.selectedTab == tab
        return Button {
            viewModel.selectedTab = tab
        } label: {
            VStack(spacing: 6) {
                Text(tab.title)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected
                        ? TokenColors.Button.brand.swiftUI
                        : TokenColors.Text.secondary.swiftUI)
                Rectangle()
                    .fill(isSelected ? TokenColors.Button.brand.swiftUI : Color.clear)
                    .frame(height: 2)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: TokenSpacing._5) {
            Spacer()
            MEGAAssets.Image.newTransfersEmptyState
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
            Text(viewModel.emptyStateLabel)
                .font(.body)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("No transfers") {
    NavigationView {
        TransfersListView(viewModel: TransfersListViewModel())
    }
}

#Preview("No active transfers (others have data)") {
    NavigationView {
        TransfersListView(viewModel: TransfersListViewModel(
            hasActiveTransfers: false,
            hasCompletedTransfers: true,
            hasFailedTransfers: true
        ))
    }
}

#Preview("Failed tab empty") {
    NavigationView {
        TransfersListView(viewModel: {
            let vm = TransfersListViewModel(
                hasActiveTransfers: true,
                hasCompletedTransfers: true,
                hasFailedTransfers: false
            )
            vm.selectedTab = .failed
            return vm
        }())
    }
}
