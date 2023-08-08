import MEGADomain
import SwiftUI

public class DeviceCenterItemViewModel: ObservableObject, Identifiable {
    enum ItemType {
        case backup(BackupEntity)
        case device(DeviceEntity)
    }
    
    private let router: (any DeviceListRouting)?
    private var itemType: ItemType
    var assets: ItemAssets
    
    @Published var name: String = ""
    @Published var iconName: String?
    @Published var statusIconName: String?
    @Published var statusTitle: String = ""
    @Published var statusColorName: String = ""
    @Published var shouldShowBackupPercentage: Bool = false
    @Published var backupPercentage: String = ""
    
    init(router: (any DeviceListRouting)? = nil,
         itemType: ItemType,
         assets: ItemAssets) {
        self.router = router
        self.itemType = itemType
        self.assets = assets
        
        self.configure()
    }
    
    func configure() {
        switch itemType {
        case .backup(let backup):
            name = backup.name
            
        case .device(let device):
            name = device.name.isNotEmpty ? device.name : assets.defaultName ?? ""
        }
        
        self.iconName = assets.iconName
        self.statusTitle = assets.backupStatus.title
        self.statusIconName = assets.backupStatus.iconName
        self.statusColorName = assets.backupStatus.colorName
        
        calculateProgress()
    }
    
    private func calculateProgress() {
        if assets.backupStatus.status == .updating {
            var progress = 0
            switch itemType {
            case .backup(let backup):
                progress = Int(backup.progress)
                
            case .device(let device):
                progress = device.backups?.first(where: {
                    $0.backupStatus == .updating
                }).flatMap {
                    Int($0.progress)
                } ?? 0
            }
            progress = min(progress, 100)
            
            backupPercentage = "\(progress) %"
            shouldShowBackupPercentage = progress > 0
        }
    }
    
    func showDetail() {
        guard let router else { return }
        if case let .device(device) = itemType {
            router.showDeviceBackups(device)
        }
    }
}
