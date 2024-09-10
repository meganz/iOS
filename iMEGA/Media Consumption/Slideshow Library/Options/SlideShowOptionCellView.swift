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
                    .foregroundColor(colorScheme == .dark ? MEGAAppColor.Black._1C1C1E.color : MEGAAppColor.White._F7F7F7.color)
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
                            Image(uiImage: UIImage.standardDisclosureIndicatorDesignToken)
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
