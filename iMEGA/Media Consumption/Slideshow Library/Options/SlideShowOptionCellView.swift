import SwiftUI

struct SlideShowOptionCellView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var cellModel: SlideShowOptionCellViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            if cellModel.type == .none {
                Rectangle()
                    .frame(height: 24)
                    .foregroundColor(Color(colorScheme == .dark ? UIColor.mnz_black1C1C1E() : UIColor.mnz_grayF7F7F7()))
            } else {
                ZStack {
                    Toggle(isOn: $cellModel.isOn) {
                        Text(cellModel.title)
                            .font(.body)
                    }
                    .opacity(cellModel.type == .toggle ? 1 : 0)
                    
                    HStack {
                        Text(cellModel.title)
                            .font(.body)
                        Spacer()
                        HStack {
                            Text(cellModel.detail)
                                .font(.subheadline)
                            Image(uiImage: Asset.Images.Generic.standardDisclosureIndicator.image)
                                .scaledToFit()
                                .frame(width: 12, height: 12)
                        }
                        .foregroundColor(Color(colorScheme == .dark ? UIColor.mnz_grayEBEBF5() : UIColor.mnz_gray3C3C43()).opacity(0.6))
                    }
                    .opacity(cellModel.type == .detail ? 1 : 0)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            Divider().padding(.leading, 16)
        }
        .background(
            Color(colorScheme == .dark ? UIColor.mnz_black2C2C2E() : UIColor.white)
        )
    }
}
