import MEGASwiftUI
import SwiftUI

struct DeviceListView: View {
    @ObservedObject var viewModel: DeviceListViewModel
    
    var body: some View {
        SearchableView(
            wrappedView: DeviceListContentView(viewModel: viewModel),
            searchText: $viewModel.searchText,
            isEditing: $viewModel.isSearchActive,
            isFilteredListEmpty: viewModel.isFilteredDevicesEmpty,
            searchAssets: viewModel.searchAssets,
            emptyStateAssets: viewModel.emptyStateAssets
        )
    }
}

struct DeviceListContentView: View {
    @ObservedObject var viewModel: DeviceListViewModel
    @State private var selectedViewModel: DeviceCenterItemViewModel?
    
    var body: some View {
        ListViewContainer(
            selectedItem: $selectedViewModel) {
                List {
                    if viewModel.isFiltered {
                        ForEach(viewModel.filteredDevices) { deviceViewModel in
                            DeviceCenterItemView(
                                viewModel: deviceViewModel,
                                selectedViewModel: $selectedViewModel
                            )
                        }
                    } else {
                        Section(header: Text(viewModel.deviceListAssets.currentDeviceTitle)) {
                            if let currentDeviceVM = viewModel.currentDevice {
                                DeviceCenterItemView(
                                    viewModel: currentDeviceVM,
                                    selectedViewModel: $selectedViewModel
                                )
                            }
                        }
                        
                        if viewModel.otherDevices.isNotEmpty {
                            Section(header: Text(viewModel.deviceListAssets.otherDevicesTitle)) {
                                ForEach(viewModel.otherDevices) { deviceViewModel in
                                    DeviceCenterItemView(
                                        viewModel: deviceViewModel,
                                        selectedViewModel: $selectedViewModel
                                    )
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .throwingTaskForiOS14 {
                    try await viewModel.startAutoRefreshUserDevices()
                }
            }
    }
}
