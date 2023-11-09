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
                ContentUnavailableView_iOS16ViewModel(
                    image: Image("folderEmptyState"),
                    title: Strings.Localizable.Device.Center.Current.Device.Empty.State.message,
                    font: .body,
                    color: colorScheme == .dark ? .white : .black,
                    actions: [
                        ContentUnavailableView_iOS16ViewModel.Action(
                            title: Strings.Localizable.enableCameraUploadsButton,
                            handler: viewModel.showCameraUploadsSettingsFlow,
                            color: colorScheme == .dark ? Color("00C29A") : Color("00A886")
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
                    DeviceCenterMenu(viewModel: viewModel, title: option.title, menuIconName: option.icon, menuOptions: subActions)
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
