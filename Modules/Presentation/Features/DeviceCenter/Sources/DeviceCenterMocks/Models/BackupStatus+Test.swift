import DeviceCenter
import MEGADomain

public extension BackupStatus {
    init(status: BackupStatusEntity,
         title: String = "",
         colorName: String = "",
         iconName: String = "",
         isTesting: Bool = true) {
        self.init(status: status,
                  title: title,
                  colorName: colorName,
                  iconName: iconName)
    }
}
