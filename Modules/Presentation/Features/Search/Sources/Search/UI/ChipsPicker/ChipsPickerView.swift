import SwiftUI

struct ChipsPickerView: View {
    @Environment(\.colorScheme) private var colorScheme
    var viewModel: ChipsPickerViewModel

    var body: some View {
        ScrollView(.vertical) {
            header
            chips
        }
    }

    private var header: some View {
        HStack {
            Spacer()
            Text(viewModel.title)
                .font(.subheadline)
                .fontWeight(.bold)
            Spacer()
        }
        .padding(.top, 32)
        .overlay(
            closeButton,
            alignment: .trailing
        )
    }

    private var chips: some View {
        VStack(spacing: .zero) {
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
        .padding(.leading, 16)
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

    private var closeButton: some View {
        Button(action: {
            viewModel.close()
        }, label: {
            Image(uiImage: viewModel.closeIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
        })
        .padding(.trailing, 16)
        .padding(.top, 32)
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
                    closeIcon: UIImage(systemName: "ellipsis")!,
                    colorAssets: .example,
                    chipSelection: {_ in},
                    dismiss: {}
                )
            )
            .frame(height: 440)
            .background(Color.gray)
        }
    }
}
