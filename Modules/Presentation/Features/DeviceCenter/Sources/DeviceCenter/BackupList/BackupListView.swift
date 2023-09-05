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
                    Menu {
                        let menuOptions = viewModel.actionsForDevice()
                        ForEach(menuOptions.indices, id: \.self) { index in
                            let contextMenuOption = menuOptions[index]
                            if contextMenuOption.type == .cameraUploads {
                                Divider()
                            }
                            Button {
                                contextMenuOption.action()
                            } label: {
                                Label(contextMenuOption.title, image: contextMenuOption.icon)
                            }
                        }
                    } label: {
                        Image("moreList")
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                    }
                 }
             }
    }
}
