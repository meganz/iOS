import DeviceCenter
import SwiftUI

public extension ItemAssets {
    init(
        iconName: String = "",
        status: BackupStatus,
        defaultName: String? = nil,
        isTesting: Bool = true
    ) {
        self.init(
            iconName: iconName,
            status: status,
            defaultName: defaultName
        )
    }
}
