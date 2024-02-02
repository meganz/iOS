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
            searchAssets: viewModel.searchAssets,
            emptyStateAssets: viewModel.emptyStateAssets
        )
    }
}

struct BackupListContentView: View {
    @Environment(\.colorScheme) private var colorScheme
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
                    }
                }
                .listStyle(.plain)
            }.toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    DeviceCenterMenu(viewModel: viewModel, menuIconName: "moreList", menuOptions: viewModel.actionsForDevice())
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
                    image: Image("folderEmptyState"),
                    title: Strings.Localizable.Device.Center.Current.Device.Empty.State.message,
                    font: .body,
                    titleTextColor: { _ in TokenColors.Text.primary.swiftUI },
                    actions: [
                        ContentUnavailableViewModel.ButtonAction(
                            title: Strings.Localizable.enableCameraUploadsButton,
                            backgroundColor: { _ in TokenColors.Support.success.swiftUI },
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
    let menuIconName: String
    let menuOptions: [DeviceCenterAction]

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
                                Label(option.title, image: option.icon)
                                    .tag(index)
                            }
                        }
                    } label: {
                        Label(option.title, image: option.icon)
                    }
                } else {
                    Button {
                        Task {
                            await viewModel.executeDeviceAction(type: option.type)
                        }
                    } label: {
                        Label(option.title, image: option.icon)
                    }
                }
            }
        } label: {
            if title.isEmpty {
                Image(menuIconName)
                    .scaledToFit()
                    .frame(width: 28, height: 28)
            } else {
                Label(title, image: menuIconName)
            }
        }
    }
}
