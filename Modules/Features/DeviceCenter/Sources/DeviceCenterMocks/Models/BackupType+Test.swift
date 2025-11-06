import DeviceCenter
import MEGADomain

public extension BackupType {
    init(type: BackupTypeEntity,
         iconName: String = "",
         isTesting: Bool = true) {
        self.init(type: type,
                  iconName: iconName)
    }
}
