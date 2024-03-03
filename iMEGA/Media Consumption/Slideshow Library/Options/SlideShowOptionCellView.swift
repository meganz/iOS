import MEGADesignToken
import SwiftUI

struct SlideShowOptionCellView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var cellModel: SlideShowOptionCellViewModel
    
    private var backgroundColor: Color {
        if isDesignTokenEnabled {
            TokenColors.Background.page.swiftUI
        } else {
            colorScheme == .dark ? MEGAAppColor.Black._2C2C2E.color : MEGAAppColor.White._FFFFFF.color
        }
    }
    
    private var textColor: Color {
        if isDesignTokenEnabled {
            TokenColors.Text.secondary.swiftUI
        } else {
            colorScheme == .dark ? MEGAAppColor.Gray._EBEBF5.color : MEGAAppColor.Gray._3C3C43.color.opacity(0.6)
        }
    }
    
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
                    .designTokenToggleBackground(isDesignTokenEnabled)
                    .opacity(cellModel.type == .toggle ? 1 : 0)
                    
                    HStack {
                        Text(cellModel.title)
                            .font(.body)
                        Spacer()
                        HStack {
                            Text(cellModel.detail)
                                .font(.subheadline)
                            Image(uiImage: isDesignTokenEnabled ? UIImage.standardDisclosureIndicatorDesignToken: UIImage.standardDisclosureIndicator)
                                .scaledToFit()
                                .frame(width: 12, height: 12)
                        }
                        .foregroundStyle(textColor)
                    }
                    .opacity(cellModel.type == .detail ? 1 : 0)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .background(backgroundColor)
    }
}
