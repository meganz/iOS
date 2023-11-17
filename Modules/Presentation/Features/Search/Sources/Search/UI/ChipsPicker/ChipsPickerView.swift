import SwiftUI

struct ChipsPickerView: View {
    private let title: String
    private let chips: [ChipViewModel]
    private let chipSelection: (ChipViewModel) -> Void

    init(
        title: String,
        chips: [ChipViewModel],
        chipSelection: @escaping (ChipViewModel) -> Void
    ) {
        self.title = title
        self.chips = chips
        self.chipSelection = chipSelection
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)

            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: .zero) {
                    ForEach(chips) { chip in
                        Button(
                            action: { chipSelection(chip) },
                            label: {
                                HStack {
                                    Text(chip.pill.title)
                                        .font(.subheadline)
                                        .foregroundColor(Color.primary)

                                    Spacer()

                                    if let image = chip.selectionIndicatorImage {
                                        Image(uiImage: image)
                                    }
                                }
                                .padding(.vertical, 19)
                            }
                        )
                    }
                }
            }
            .padding(.top, 6)
        }
        .padding(.horizontal, 16)
        .padding(.top, 32)
    }
}

struct ChipsPickerViewPreviews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            ChipsPickerView(
                title: "Select Type",
                chips: [
                    .init(
                        chipId: ChipId(1),
                        pill: .init(
                            title: "Chips 1",
                            selected: false,
                            icon: .trailing(Image(systemName: "ellipsis")),
                            config: .example
                        ),
                        subchips: [],
                        selectionIndicatorImage: UIImage(systemName: "ellipsis"),
                        select: {}
                    )
                ],
                chipSelection: {_ in}
            )
            .frame(height: 440)
            .background(Color.gray)
        }
    }
}
