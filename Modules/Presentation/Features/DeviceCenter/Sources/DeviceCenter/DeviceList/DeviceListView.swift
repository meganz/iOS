import SwiftUI

struct DeviceListView: View {
    @ObservedObject var viewModel: DeviceListViewModel
    
    var body: some View {
        List {
            Section(header: Text(viewModel.deviceListAssets.currentDeviceTitle)) {
                if let currentDeviceVM = viewModel.currentDevice {
                    DeviceCenterItemView(viewModel: currentDeviceVM)
                }
            }
            
            if viewModel.otherDevices.isNotEmpty {
                Section(header: Text(viewModel.deviceListAssets.otherDevicesTitle)) {
                    ForEach(viewModel.otherDevices) { deviceViewModel in
                        DeviceCenterItemView(viewModel: deviceViewModel)
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}
