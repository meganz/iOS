import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

/// Shimmering skeleton shown while the folder link is being resolved.
/// It mimics the list rows that replace it once the nodes are loaded.
struct FolderLinkLoadingView: View {
    private enum Constants {
        static let rowHeight: CGFloat = 58
        static let thumbnailSide: CGFloat = 32
        static let titleWidth: CGFloat = 165
        static let titleHeight: CGFloat = 22
        static let subtitleWidth: CGFloat = 110
        static let subtitleHeight: CGFloat = 18
    }

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                ForEach(0..<rowCount(fitting: proxy.size.height), id: \.self) { _ in
                    row
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .padding(.top, TokenSpacing._3)
        .clipped()
        .shimmering()
        .allowsHitTesting(false)
        // The bones carry no meaning of their own, so collapse them into a single
        // element that announces the loading state the skeleton stands in for.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Strings.Localizable.loading)
    }

    private var row: some View {
        HStack(spacing: TokenSpacing._4) {
            bone(width: Constants.thumbnailSide, height: Constants.thumbnailSide)

            VStack(alignment: .leading, spacing: TokenSpacing._1) {
                bone(width: Constants.titleWidth, height: Constants.titleHeight)
                bone(width: Constants.subtitleWidth, height: Constants.subtitleHeight)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, TokenSpacing._4)
        .frame(height: Constants.rowHeight)
    }

    private func bone(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: TokenRadius.medium)
            .fill(TokenColors.Text.primary.swiftUI)
            .frame(width: width, height: height)
    }

    private func rowCount(fitting height: CGFloat) -> Int {
        max(1, Int(ceil(height / Constants.rowHeight)))
    }
}

#Preview {
    FolderLinkLoadingView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TokenColors.Background.page.swiftUI)
}
