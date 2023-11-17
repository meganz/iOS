import MEGASwiftUI
import SwiftUI

public struct ChipViewModel: Identifiable {

    public var id: String {
        chipId.description
    }
    let chipId: ChipId
    let pill: PillViewModel
    let subchipsPickerTitle: String?
    let subchips: [ChipViewModel]
    let selectionIndicatorImage: UIImage?
    let select: () async -> Void

    init(
        chipId: ChipId,
        pill: PillViewModel,
        subchips: [ChipViewModel] = [],
        subchipsPickerTitle: String? = nil,
        selectionIndicatorImage: UIImage? = nil,
        select: @escaping () async -> Void
    ) {
        self.chipId = chipId
        self.pill = pill
        self.subchipsPickerTitle = subchipsPickerTitle
        self.subchips = subchips
        self.selectionIndicatorImage = selectionIndicatorImage
        self.select = select
    }
}
