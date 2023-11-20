import MEGASwiftUI
import SwiftUI

public struct ChipViewModel: Identifiable, Equatable {
    public static func == (lhs: ChipViewModel, rhs: ChipViewModel) -> Bool {
        lhs.id == rhs.id && lhs.selected == rhs.selected
    }

    public var id: String {
        chipId.description
    }
    let chipId: ChipId
    let pill: PillViewModel
    let subchipsPickerTitle: String?
    let subchips: [ChipViewModel]
    let selectionIndicatorImage: UIImage?
    let selected: Bool
    let select: () async -> Void

    init(
        chipId: ChipId,
        pill: PillViewModel,
        subchips: [ChipViewModel] = [],
        subchipsPickerTitle: String? = nil,
        selectionIndicatorImage: UIImage? = nil,
        selected: Bool = false,
        select: @escaping () async -> Void
    ) {
        self.chipId = chipId
        self.pill = pill
        self.subchipsPickerTitle = subchipsPickerTitle
        self.subchips = subchips
        self.selectionIndicatorImage = selectionIndicatorImage
        self.selected = selected
        self.select = select
    }
}
