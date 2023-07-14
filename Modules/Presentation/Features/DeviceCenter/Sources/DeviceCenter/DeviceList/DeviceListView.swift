import SwiftUI

struct DeviceListView: View {
    @ObservedObject var viewModel: DeviceListViewModel
    
    var body: some View {
        List {
            Section(header: Text(viewModel.deviceListAssets.currentDeviceTitle)) {
                if let currentDeviceVM = viewModel.currentDevice {
                    DeviceView(viewModel: currentDeviceVM)
                }
            }
            
            if viewModel.otherDevices.isNotEmpty {
                Section(header: Text(viewModel.deviceListAssets.otherDevicesTitle)) {
                    ForEach(viewModel.otherDevices) { deviceViewModel in
                        DeviceView(viewModel: deviceViewModel)
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}
