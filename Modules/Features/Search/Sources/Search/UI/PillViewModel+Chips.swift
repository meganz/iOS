import MEGASwiftUI
import SwiftUI

/// extension to make creating pill view models (which are generic)
/// from chips (which are search specific) easier
extension PillViewModel {
    init(
        title: String,
        selected: Bool,
        icon: PillView.Icon,
        config: SearchConfig.ChipAssets
    ) {
        self.init(
            title: title,
            icon: icon,
            foreground: selected ? config.selectedForeground : config.normalForeground,
            background: selected ? config.selectedBackground : config.normalBackground
        )
    }
}
