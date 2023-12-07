import SwiftUI

struct ChipsPickerView: View {
    @Environment(\.colorScheme) private var colorScheme
    var viewModel: ChipsPickerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack {
                Spacer()
                Text(viewModel.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Spacer()
            }

            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: .zero) {
                    ForEach(viewModel.chips) { chip in
                        if viewModel.shouldDisplayBottomSeparator(for: chip) {
                            chipRow(for: chip)
                                .overlay(
                                    separator,
                                    alignment: .bottom
                                )
                        } else {
                            chipRow(for: chip)
                        }
                    }
                }
            }
            .padding(.top, 6)
        }
        .padding(.horizontal, 16)
        .padding(.top, 32)
    }

    private func chipRow(for chip: ChipViewModel) -> some View {
        Button(
            action: { viewModel.select(chip) },
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

    private var separator: some View {
        viewModel.separatorColor(for: colorScheme).frame(height: 1)
    }
}

struct ChipsPickerViewPreviews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            ChipsPickerView(
                viewModel: .init(
                    title: "Select Type",
                    chips: [
                        .init(
                            id: "Chips 1",
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
                    colorAssets: .example,
                    chipSelection: {_ in}
                )
            )
            .frame(height: 440)
            .background(Color.gray)
        }
    }
}
