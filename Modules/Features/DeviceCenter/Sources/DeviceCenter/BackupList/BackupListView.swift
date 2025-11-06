import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct BackupListView: View {
    @ObservedObject var viewModel: BackupListViewModel
    
    var body: some View {
        SearchableView(
            wrappedView: BackupListContentView(viewModel: viewModel),
            searchText: $viewModel.searchText,
            isEditing: $viewModel.isSearchActive,
            isFilteredListEmpty: viewModel.isFilteredBackupsEmpty,
            hasNetworkConnection: $viewModel.hasNetworkConnection
        )
    }
}

struct BackupListContentView: View {
    @ObservedObject var viewModel: BackupListViewModel
    @State private var selectedBackupViewModel: DeviceCenterItemViewModel?
    
    var body: some View {
        if viewModel.showEmptyStateView {
            contentEmptyState
        } else {
            content
        }
    }
    
    var content: some View {
        ListViewContainer(
            selectedItem: $selectedBackupViewModel,
            hasNetworkConnection: $viewModel.hasNetworkConnection) {
                List {
                    ForEach(viewModel.displayedBackups) { backupViewModel in
                        DeviceCenterItemView(
                            viewModel: backupViewModel,
                            selectedViewModel: $selectedBackupViewModel
                        )
                        .listRowInsets(EdgeInsets())
                    }
                }
                .listStyle(.plain)
                .background()
            }.toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    DeviceCenterMenu(
                        viewModel: viewModel,
                        menuIconImage: MEGAAssets.Image.moreList,
                        menuOptions: viewModel.availableActionsForCurrentDevice()
                    )
                }
            }
            .throwingTask {
                viewModel.updateInternetConnectionStatus()
                try await viewModel.updateDeviceStatusesAndNotify()
            }
    }
    
    var contentEmptyState: some View {
        content
            .emptyState(
                ContentUnavailableViewModel(
                    image: MEGAAssets.Image.folderEmptyState,
                    title: Strings.Localizable.Device.Center.Current.Device.Empty.State.message,
                    font: .body,
                    titleTextColor: TokenColors.Text.primary.swiftUI,
                    actions: [
                        ContentUnavailableViewModel.ButtonAction(
                            title: Strings.Localizable.enableCameraUploadsButton,
                            titleTextColor: TokenColors.Text.inverseAccent.swiftUI,
                            backgroundColor: TokenColors.Button.primary.swiftUI,
                            image: nil,
                            handler: viewModel.showCameraUploadsSettingsFlow
                        )
                    ]
                )
            )
    }
}

struct DeviceCenterMenu: View {
    @ObservedObject var viewModel: BackupListViewModel
    var title: String = ""
    let menuIconImage: Image
    let menuOptions: [ContextAction]

    var body: some View {
        Menu {
            ForEach(menuOptions.indices, id: \.self) { index in
                let option = menuOptions[index]
                
                if option.type == .cameraUploads ||
                    option.type == .sort {
                    Divider()
                }

                if let subActions = option.subActions {
                    Menu {
                        Picker(selection: $viewModel.sortIndexSelected, label: Text(option.title)) {
                            ForEach(Array(subActions.enumerated()), id: \.element) { index, option in
                                Label(title: { Text(option.title) }, icon: { MEGAAssets.Image.image(named: option.icon) })
                                    .tag(index)
                            }
                        }
                    } label: {
                        Label(title: { Text(option.title) }, icon: { MEGAAssets.Image.image(named: option.icon) })
                    }
                } else {
                    Button {
                        Task {
                            await viewModel.executeDeviceAction(type: option.type)
                        }
                    } label: {
                        Label(title: { Text(option.title) }, icon: { MEGAAssets.Image.image(named: option.icon) })
                    }
                }
            }
        } label: {
            if title.isEmpty {
                menuIconImage
                    .renderingMode(.template)
                    .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
                    .scaledToFit()
                    .frame(width: 28, height: 28)
            } else {
                Label(title: { Text(title) }, icon: { menuIconImage })
            }
        }
    }
}
