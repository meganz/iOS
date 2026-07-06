import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import SwiftUI

public struct DefaultLaunchDestinationView: View {
    public struct Dependency {
        let defaultLaunchDestinationUseCase: any DefaultLaunchDestinationUseCaseProtocol
    }
    @StateObject private var viewModel: DefaultLaunchDestinationViewModel

    public init(dependency: Dependency) {
        _viewModel = StateObject(wrappedValue: DefaultLaunchDestinationViewModel(useCase: dependency.defaultLaunchDestinationUseCase))
    }

    public var body: some View {
        List {
            ForEach(viewModel.rows) { row in
                Button {
                    viewModel.select(row.destination)
                } label: {
                    DefaultLaunchDestinationRow(
                        title: row.title,
                        icon: row.icon,
                        isSelected: row.destination == viewModel.selectedDestination
                    )
                }
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)
                .listRowBackground(TokenColors.Background.page.swiftUI)
                .listRowInsets(EdgeInsets(top: TokenSpacing._3, leading: TokenSpacing._5, bottom: TokenSpacing._3, trailing: TokenSpacing._5))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(TokenColors.Background.page.swiftUI)
        .navigationTitle(Strings.Localizable.Home.Customization.DefaultLaunchTab.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton()
            }
        }
    }
}

private struct DefaultLaunchDestinationRow: View {
    let title: String
    let icon: Image
    let isSelected: Bool

    var body: some View {
        HStack(spacing: TokenSpacing._3) {
            icon
                .renderingMode(.template)
                .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                .frame(width: 32, height: 32)
            Text(title)
                .font(.body)
                .fontWeight(.regular)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
            Spacer()
            if isSelected {
                MEGAAssets.Image.turquoiseCheckmark
            }
        }
        .padding(.vertical, TokenSpacing._2)
        .contentShape(Rectangle())
    }
}
