import MEGADesignToken
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
            selectedItem: $selectedViewModel,
            hasNetworkConnection: $viewModel.hasNetworkConnection) {
            PlaceholderContainerView(
                isLoading: $viewModel.isLoadingPlaceholderVisible,
                content: content,
                placeholder: PlaceholderContentView(placeholderRow: placeholderRowView)
            )
        }
    }
    
    private var content: some View {
        List {
            if viewModel.isFiltered {
                ForEach(viewModel.filteredDevices) { deviceViewModel in
                    DeviceCenterItemView(
                        viewModel: deviceViewModel,
                        selectedViewModel: $selectedViewModel
                    )
                    .listRowInsets(EdgeInsets())
                }
            } else {
                Section(header: Text(viewModel.deviceListAssets.currentDeviceTitle)) {
                    if let currentDeviceVM = viewModel.currentDevice {
                        DeviceCenterItemView(
                            viewModel: currentDeviceVM,
                            selectedViewModel: $selectedViewModel
                        )
                        .listRowInsets(EdgeInsets())
                    }
                }
                
                if viewModel.otherDevices.isNotEmpty {
                    Section(header: Text(viewModel.deviceListAssets.otherDevicesTitle)) {
                        ForEach(viewModel.otherDevices) { deviceViewModel in
                            DeviceCenterItemView(
                                viewModel: deviceViewModel,
                                selectedViewModel: $selectedViewModel
                            )
                            .listRowInsets(EdgeInsets())
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .background(isDesignTokenEnabled ? TokenColors.Background.page.swiftUI : .clear)
        .onReceive(viewModel.refreshDevicesPublisher) { _ in
            Task {
                let userDevices = await self.viewModel.fetchUserDevices()
                self.viewModel.arrangeDevices(userDevices)
            }
        }
        .throwingTask {
            viewModel.updateInternetConnectionStatus()
            try await viewModel.startAutoRefreshUserDevices()
        }
    }
    
    private var placeholderRowView: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: 112, height: 16)

                RoundedRectangle(cornerRadius: 8)
                    .frame(width: 175, height: 16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(EdgeInsets(top: 20, leading: 12, bottom: 0, trailing: 12))
        .shimmering()
    }
}
