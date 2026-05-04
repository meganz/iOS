import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import MEGAUIComponent
import SwiftUI

struct TransfersSettingsView: View {
    @StateObject private var viewModel: TransfersSettingsViewModel

    init(viewModel: @autoclosure @escaping () -> TransfersSettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        ScrollView {
            connectionsSection
        }
        .scrollIndicators(.hidden)
        .pageBackground()
        .navigationTitle(Strings.Localizable.transfers)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.trackScreenView()
        }
        .task {
            await viewModel.loadConnections()
        }
        .snackBar($viewModel.snackBar)
        .sheet(item: $viewModel.presentedSheet) { type in
            ConnectionOptionsView(
                title: type.title,
                options: viewModel.options,
                selection: viewModel.value(for: type),
                suffix: { viewModel.optionSuffix(for: $0, type: type) },
                onSelect: { value in
                    Task { await viewModel.select(value, for: type) }
                }
            )
        }
    }

    private var connectionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Strings.Localizable.Settings.Transfers.Connections.title)
                .font(.headline)
                .padding(.horizontal, TokenSpacing._5)
                .padding(.top, TokenSpacing._5)
                .padding(.bottom, TokenSpacing._3)

            Text(Strings.Localizable.Settings.Transfers.Connections.description)
                .font(.footnote)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                .padding(.horizontal, TokenSpacing._5)
                .padding(.bottom, TokenSpacing._5)

            connectionRow(for: .download)
            connectionRow(for: .upload)
        }
    }

    private func connectionRow(for type: TransfersSettingsViewModel.ConnectionType) -> some View {
        Button {
            viewModel.onTap(type)
        } label: {
            MEGAList(
                title: type.title,
                subtitle: viewModel.subtitle(for: type)
            )
            .trailingChevron()
        }
    }
}
