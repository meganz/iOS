import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct ListViewContainer<Content>: View where Content: View {
    @Binding var selectedItem: DeviceCenterItemViewModel?
    @Binding var hasNetworkConnection: Bool
    let content: () -> Content
    let sheetHeaderHeight: CGFloat = 75
    let sheetButtonsHeight: CGFloat = 60
    let sheetBottomPadding: CGFloat = 30

    var body: some View {
        if hasNetworkConnection {
            content()
                .sheet(item: $selectedItem) { selectedItem in
                    if #available(iOS 16, *) {
                        sheetContent(
                            selectedItem: selectedItem
                        ).presentationDetents([
                            .height((CGFloat(selectedItem.availableActions.count) * sheetButtonsHeight) + sheetHeaderHeight + sheetBottomPadding)
                        ])
                    } else {
                        sheetContent(
                            selectedItem: selectedItem
                        )
                    }
                }
        } else {
            ContentUnavailableView_iOS16(label: {
                Image("noInternetEmptyState")
            }, description: {
                Text(Strings.Localizable.noInternetConnection)
            })
        }
    }

    @ViewBuilder
    private func sheetContent(
        selectedItem: DeviceCenterItemViewModel
    ) -> some View {
        ActionSheetContentView(
            headerView:
                ActionSheetHeaderView(
                    iconName: selectedItem.iconName ?? "",
                    title: selectedItem.name,
                    detailImageName: selectedItem.statusIconName ?? "",
                    subtitle: selectedItem.statusTitle,
                    subtitleColorName: selectedItem.statusColorName
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
}
