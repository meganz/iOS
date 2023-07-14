import MEGADomain
import SwiftUI

public final class DeviceViewModel: ObservableObject, Identifiable {
    private var device: DeviceEntity
    private var assets: DeviceAssets
    
    @Published var name: String = ""
    @Published var iconName: String?
    @Published var statusIconName: String?
    @Published var statusTitle: String = ""
    @Published var statusColorName: String = ""
    
    init(device: DeviceEntity, assets: DeviceAssets) {
        self.device = device
        self.assets = assets
        self.name = device.name
        
        updateDeviceAssets()
    }
    
    private func updateDeviceAssets() {
        iconName = assets.iconName
        statusTitle = assets.status.title
        statusIconName = assets.status.iconName
        statusColorName = assets.status.colorName
    }
}
