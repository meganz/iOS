import DeviceCenter
import MEGADomain
import UIKit

public extension BackupStatus {
    init(status: BackupStatusEntity,
         title: String = "",
         color: UIColor = .black,
         iconName: String = "",
         isTesting: Bool = true) {
        self.init(status: status,
                  title: title,
                  color: color,
                  iconName: iconName)
    }
}
