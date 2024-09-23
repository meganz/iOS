import MEGASwiftUI
import SwiftUI

public struct ChipViewModel: Identifiable {
    public let id: String
    let pill: PillViewModel
    let subchipsPickerTitle: String?
    let subchips: [ChipViewModel]
    let selectionIndicatorImage: UIImage?
    let selected: Bool
    let select: () async -> Void

    init(
        id: String,
        pill: PillViewModel,
        subchips: [ChipViewModel] = [],
        subchipsPickerTitle: String? = nil,
        selectionIndicatorImage: UIImage? = nil,
        selected: Bool = false,
        select: @escaping () async -> Void
    ) {
        self.id = id
        self.pill = pill
        self.subchipsPickerTitle = subchipsPickerTitle
        self.subchips = subchips
        self.selectionIndicatorImage = selectionIndicatorImage
        self.selected = selected
        self.select = select
    }
}
