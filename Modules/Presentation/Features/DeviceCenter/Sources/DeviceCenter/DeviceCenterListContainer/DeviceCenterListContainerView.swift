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
                        if #available(iOS 16, *) {
                            let headerHeight = max(estimatedHeaderHeight(for: selectedItem, width: geometry.size.width), 60.0)
                            let actionsHeight = CGFloat(selectedItem.availableActions.count) * sheetButtonsHeight
                            let totalHeight = headerHeight + actionsHeight + sheetBottomPadding

                            sheetContent(selectedItem: selectedItem)
                                .presentationDetents([
                                    .height(totalHeight)
                                ])
                        } else {
                            sheetContent(selectedItem: selectedItem)
                        }
                    }
            } else {
                ContentUnavailableView(label: {
                    Image("noInternetEmptyState")
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
                    headerIcon: Image(selectedItem.assets.iconName, bundle: .module),
                    title: selectedItem.name,
                    subtitleIcon: Image(selectedItem.assets.statusAssets.iconName, bundle: .module),
                    subtitle: selectedItem.assets.statusAssets.title,
                    subtitleColor: selectedItem.assets.statusAssets.color
                ),
            actionButtons: {
                selectedItem.availableActions.compactMap { action in
                    ActionSheetButton(
                        icon: action.icon,
                        title: action.title,
                        subtitle: action.dynamicSubtitle?() ?? action.subtitle,
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
