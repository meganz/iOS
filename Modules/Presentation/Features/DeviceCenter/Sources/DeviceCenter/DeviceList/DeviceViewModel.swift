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
    @Published var shouldShowBackupPercentage: Bool = false
    @Published var backupPercentage: String = ""
    
    init(device: DeviceEntity, defaultName: String, assets: DeviceAssets) {
        self.device = device
        self.assets = assets
        self.name = device.name.isNotEmpty ? device.name : defaultName
        
        updateDeviceAssets()
        updateBackupProgressIfNeeded()
    }
    
    private func updateDeviceAssets() {
        iconName = assets.iconName
        statusTitle = assets.status.title
        statusIconName = assets.status.iconName
        statusColorName = assets.status.colorName
    }
    
    private func updateBackupProgressIfNeeded() {
        if device.status == .updating {
            let progress = device.backups?.first(where: {
                $0.backupStatus == .updating
            }).flatMap {
                $0.progress
            } ?? 0
            
            backupPercentage = "\(progress) %"
            shouldShowBackupPercentage = progress > 0
        }
    }
}
