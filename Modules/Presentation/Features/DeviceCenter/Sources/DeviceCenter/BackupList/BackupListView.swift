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
    @ObservedObject var viewModel: BackupListViewModel
    @State private var selectedBackupViewModel: DeviceCenterItemViewModel?
    
    var body: some View {
        ListViewContainer(
            selectedItem: $selectedBackupViewModel) {
                List {
                    ForEach(viewModel.displayedBackups) { backupViewModel in
                        DeviceCenterItemView(
                            viewModel: backupViewModel,
                            selectedViewModel: $selectedBackupViewModel
                        )
                    }
                }
                .listStyle(.plain)
                .throwingTaskForiOS14 {
                    try await viewModel.updateDeviceStatusesAndNotify()
                }
            }.toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    DeviceCenterMenu(menuIconName: "moreList", menuOptions: viewModel.actionsForDevice())
                }
            }
    }
}

struct DeviceCenterMenu: View {
    var title: String = ""
    let menuIconName: String
    let menuOptions: [DeviceCenterAction]

    var body: some View {
        Menu {
            ForEach(menuOptions.indices, id: \.self) { index in
                let contextMenuOption = menuOptions[index]
                
                if contextMenuOption.type == .cameraUploads ||
                    contextMenuOption.type == .sort {
                    Divider()
                }

                if let subActions = contextMenuOption.subActions {
                    DeviceCenterMenu(title: contextMenuOption.title, menuIconName: contextMenuOption.icon, menuOptions: subActions)
                } else {
                    Button {
                        contextMenuOption.action()
                    } label: {
                        Label(contextMenuOption.title, image: contextMenuOption.icon)
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
