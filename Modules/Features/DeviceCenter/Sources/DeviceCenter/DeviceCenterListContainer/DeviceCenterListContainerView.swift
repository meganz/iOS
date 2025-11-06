import MEGAAssets
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct ListViewContainer<Content>: View where Content: View {
    @Binding var selectedItem: DeviceCenterItemViewModel?
    @Binding var hasNetworkConnection: Bool
    let content: () -> Content
    let sheetButtonsHeight: CGFloat = 60
    let sheetBottomPadding: CGFloat = 30

    var body: some View {
        GeometryReader { geometry in
            if hasNetworkConnection {
                content()
                    .sheet(item: $selectedItem) { selectedItem in
                        let headerHeight = max(estimatedHeaderHeight(for: selectedItem, width: geometry.size.width), 60.0)
                        let actionsHeight = CGFloat(selectedItem.availableActions.count) * sheetButtonsHeight
                        let totalHeight = headerHeight + actionsHeight + sheetBottomPadding
                        
                        sheetContent(selectedItem: selectedItem)
                            .presentationDetents([
                                .height(totalHeight)
                            ])
                    }
            } else {
                ContentUnavailableView(label: {
                    MEGAAssets.Image.noInternetEmptyState
                }, description: {
                    Text(Strings.Localizable.noInternetConnection)
                })
            }
        }
    }

    @ViewBuilder
    private func sheetContent(
        selectedItem: DeviceCenterItemViewModel
    ) -> some View {
        ActionSheetContentView(
            headerView:
                ActionSheetHeaderView(
                    headerIcon: MEGAAssets.Image.image(named: selectedItem.assets.iconName),
                    title: selectedItem.name,
                    subtitleIcon: MEGAAssets.Image.image(named: selectedItem.assets.statusAssets.iconName),
                    subtitle: selectedItem.assets.statusAssets.title,
                    subtitleColor: selectedItem.assets.statusAssets.color
                ),
            actionSheetButtonViewModels: {
                selectedItem.availableActions.compactMap { action in
                    ActionSheetButtonViewModel(
                        id: action.id,
                        icon: MEGAAssets.Image.image(named: action.icon),
                        title: action.title,
                        subtitle: action.dynamicSubtitle?() ?? action.subtitle,
                        disclosureIcon: MEGAAssets.Image.standardDisclosureIndicatorDesignToken,
                        action: {
                            Task {
                                await selectedItem.executeAction(action.type)
                            }
                        }
                    )
                }
            }()
        )
    }
    
    func estimatedHeaderHeight(for item: DeviceCenterItemViewModel, width: CGFloat) -> CGFloat {
        let padding: CGFloat = 5
        let paddingBetweenElements: CGFloat = 2
        let titleHeight: CGFloat = UIFont.preferredFont(forTextStyle: .subheadline).lineHeight
        let subtitleHeight: CGFloat = item.statusSubtitle?.height(withConstrainedWidth: width - (2 * padding), font: UIFont.preferredFont(forTextStyle: .caption1)) ?? 0
        
        return titleHeight + subtitleHeight + (2 * padding) + paddingBetweenElements
    }
}
