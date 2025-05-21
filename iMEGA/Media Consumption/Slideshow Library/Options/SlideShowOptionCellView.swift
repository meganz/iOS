import MEGAAssets
import MEGADesignToken
import SwiftUI

struct SlideShowOptionCellView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var cellModel: SlideShowOptionCellViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            if cellModel.type == .none {
                Rectangle()
                    .frame(height: 24)
                    .foregroundStyle(TokenColors.Background.surface1.swiftUI)
            } else {
                ZStack {
                    Toggle(isOn: $cellModel.isOn) {
                        Text(cellModel.title)
                            .font(.body)
                    }
                    .toggleBackground()
                    .opacity(cellModel.type == .toggle ? 1 : 0)
                    
                    HStack {
                        Text(cellModel.title)
                            .font(.body)
                        Spacer()
                        HStack {
                            Text(cellModel.detail)
                                .font(.subheadline)
                            MEGAAssets.Image.standardDisclosureIndicatorDesignToken
                                .scaledToFit()
                                .frame(width: 12, height: 12)
                        }
                        .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                    }
                    .opacity(cellModel.type == .detail ? 1 : 0)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .background(TokenColors.Background.page.swiftUI)
    }
}
