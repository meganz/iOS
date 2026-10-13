import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

struct PDFOutlineSheet: View {
    let items: [PDFOutlineItem]
    let activeItemID: String?
    let isLoading: Bool
    @Binding var isShowingOutline: Bool
    let onSelectOutlineItem: @MainActor (PDFOutlineItem) -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    List(items) { item in
                        row(for: item)
                            .id(item.id)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .onAppear {
                        guard let activeItemID else { return }
                        proxy.scrollTo(activeItemID, anchor: .center)
                    }
                }
            }
        }
        .background(TokenColors.Background.surface1.swiftUI)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        HStack {
            Spacer()
            Text(Strings.Localizable.PdfPreview.contents)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
            Spacer()
        }
        .padding(.top, TokenSpacing._9)
        .overlay(alignment: .trailing) { closeButton }
    }

    private var closeButton: some View {
        Button {
            isShowingOutline = false
        } label: {
            Image(uiImage: MEGAAssets.UIImage.miniplayerClose)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        // `ChipsPickerView` insets its 16pt icon by 16pt; the 44pt hit area
        // already adds 14pt on each side.
        .padding(.trailing, TokenSpacing._1)
        .padding(.top, TokenSpacing._9)
        .accessibilityLabel(Strings.Localizable.close)
    }

    private func row(for item: PDFOutlineItem) -> some View {
        let isActive = item.id == activeItemID
        return Button {
            onSelectOutlineItem(item)
        } label: {
            HStack(spacing: TokenSpacing._4 + TokenSpacing._1) {
                Text(item.title)
                    .font(.headline.weight(isActive ? .medium : .regular))
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                    .multilineTextAlignment(.leading)
                Spacer()
                Text(String(item.pageIndex + 1))
                    .font(.headline.weight(isActive ? .medium : .regular))
                    .monospacedDigit()
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            }
            .padding(.leading, CGFloat(min(item.level, 5)) * TokenSpacing._5)
            .padding(.vertical, TokenSpacing._2)
            .accessibilityElement(children: .combine)
        }
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}
