import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct HomeWidgetsCustomizationView: View {
    struct Dependency {
        let defaultLaunchDestinationUseCase: any DefaultLaunchDestinationUseCaseProtocol
    }

    enum Route: Hashable {
        case chooseDefaultLaunchTab
    }

    let dependency: Dependency

    @StateObject private var viewModel = HomeWidgetsCustomizationViewModel()

    @EnvironmentObject var navigator: HomeNavigation

    var body: some View {
        VStack(spacing: 0) {
            Text(Strings.Localizable.Home.Customization.subtitle)
                .font(.footnote)
                .fontWeight(.regular)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                .padding(.top, TokenSpacing._3)
                .padding(.bottom, TokenSpacing._5)

            List {
                ForEach(viewModel.configs) { config in
                    WidgetRow(
                        config: config,
                        displayTitle: viewModel.displayTitle(for: config.type),
                        onToggle: { isOn in
                            viewModel.toggle(config.type, isOn: isOn)
                        }
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(TokenColors.Background.page.swiftUI)
                    .listRowInsets(EdgeInsets(top: TokenSpacing._3, leading: TokenSpacing._5, bottom: TokenSpacing._3, trailing: TokenSpacing._5))
                }
                .onMove { source, destination in
                    viewModel.move(from: source, to: destination)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .background(TokenColors.Background.page.swiftUI)
        .snackBar($viewModel.snackBar)
        .navigationTitle(Strings.Localizable.Home.Customization.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Section {
                        Button {
                            viewModel.resetWidgetsToDefaults()
                        } label: {
                            Label {
                                Text(Strings.Localizable.Home.Customization.MoreButton.resetToDefault)
                            } icon: {
                                EmptyView()
                            }
                        }

                        Button {
                            navigator.append(Route.chooseDefaultLaunchTab)
                        } label: {
                            Label {
                                Text(Strings.Localizable.Home.Customization.MoreButton.chooseDefaultLaunchTab)
                            } icon: {
                                EmptyView()
                            }
                        }
                    }
                } label: {
                    Label {
                        Text(Strings.Localizable.more)
                    } icon: {
                        MEGAAssets.Image.moreHorizontal
                    }
                }
            }
        }
        .navigationDestination(for: Route.self) { _ in
            DefaultLaunchDestinationView(
                dependency: .init(
                    defaultLaunchDestinationUseCase: dependency.defaultLaunchDestinationUseCase
                )
            )
        }
    }
}

// MARK: - WidgetRow

private struct WidgetRow: View {
    let config: HomeWidgetConfigEntity
    let displayTitle: String
    let onToggle: @MainActor (Bool) -> Void

    var body: some View {
        HStack {
            if config.isDraggable {
                MEGAAssets.Image.monoQueueLineMediumThinOutline
                    .foregroundStyle(TokenColors.Icon.primary.swiftUI)
            }

            Text(displayTitle)
                .font(.body)
                .fontWeight(.regular)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
            Spacer()
            Toggle("\(config.type.rawValue)Switch", isOn: Binding(
                get: { config.isEnabled },
                set: { onToggle($0) }
            ))
            .tint(TokenColors.Support.success.swiftUI)
            .labelsHidden()
        }
        .padding(.vertical, TokenSpacing._2)
        .moveDisabled(!config.isDraggable)
    }
}
