import DeviceCenter
import SwiftUI

public extension ItemAssets {
    init(
        iconName: String = "",
        statusAssets: StatusAssets,
        defaultName: String? = nil,
        isTesting: Bool = true
    ) {
        self.init(
            iconName: iconName,
            statusAssets: statusAssets,
            defaultName: defaultName
        )
    }
}
