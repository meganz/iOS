import SwiftUI

final class ChipsPickerViewModel {
    let title: String
    let chips: [ChipViewModel]
    let closeIcon: UIImage

    private let colorAssets: SearchConfig.ColorAssets
    private let chipSelection: (ChipViewModel) -> Void
    private let dismiss: () -> Void

    init(
        title: String,
        chips: [ChipViewModel],
        closeIcon: UIImage,
        colorAssets: SearchConfig.ColorAssets,
        chipSelection: @escaping (ChipViewModel) -> Void,
        dismiss: @escaping () -> Void
    ) {
        self.title = title
        self.chips = chips
        self.closeIcon = closeIcon
        self.colorAssets = colorAssets
        self.chipSelection = chipSelection
        self.dismiss = dismiss
    }

    // We should display bottom separator for each chips except the last one
    func shouldDisplayBottomSeparator(for chip: ChipViewModel) -> Bool {
        guard let index = chips.firstIndex(where: { $0.id == chip.id }) else {
            return false
        }
        return index < chips.count - 1
    }

    func separatorColor(for colorScheme: ColorScheme) -> Color {
        colorAssets.listRowSeparator
    }

    func select(_ chip: ChipViewModel) {
        chipSelection(chip)
    }

    func close() {
        dismiss()
    }
}
