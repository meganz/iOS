import MEGASwiftUI
import SwiftUI

/// extension to make creating pill view models (which are generic)
/// from chips (which are search specific) easier
extension PillViewModel {
    init(
        title: String,
        selected: Bool,
        config: SearchConfig.ChipAssets
    ) {
        self.init(
            title: title,
            icon: selected ? Image(systemName: "checkmark") : nil,
            foreground: selected ? config.selectedForeground : config.normalForeground,
            background: selected ? config.selectedBackground : config.normalBackground
        )
    }
}
