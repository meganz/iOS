import MEGADesignToken
import SwiftUI

public struct CheckBoxWithTextButton: View {
    @Binding var isChecked: Bool
    let text: String
    let textColor: Color
    let font: Font
    let checkIconColor: Color
    let checkedBackgroundColor: Color
    let unCheckedBorderColor: Color
    let checkboxSize: CGFloat
    
    public init(
        isChecked: Binding<Bool>,
        text: String,
        textColor: Color = TokenColors.Text.primary.swiftUI,
        font: Font = .subheadline.bold(),
        checkIconColor: Color = TokenColors.Icon.inverse.swiftUI,
        checkedBackgroundColor: Color = TokenColors.Button.primary.swiftUI,
        unCheckedBorderColor: Color = TokenColors.Border.strong.swiftUI,
        checkboxSize: CGFloat = 20
    ) {
        _isChecked = isChecked
        self.text = text
        self.textColor = textColor
        self.font = font
        self.checkIconColor = checkIconColor
        self.checkedBackgroundColor = checkedBackgroundColor
        self.unCheckedBorderColor = unCheckedBorderColor
        self.checkboxSize = checkboxSize
    }
    
    public var body: some View {
        Button {
            isChecked.toggle()
        } label: {
            HStack(spacing: 12) {
                checkboxIcon
                
                Text(text)
                    .font(font)
                    .foregroundStyle(textColor)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
        }
        .contentShape(Rectangle())
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    var checkboxIcon: some View {
        if isChecked {
            checkedBoxIcon
        } else {
            uncheckedBoxIcon
        }
    }
    
    private var checkedBoxIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill()
                .foregroundStyle(checkedBackgroundColor)
                .frame(width: checkboxSize, height: checkboxSize)
            
            Image(systemName: "checkmark")
                .resizable()
                .foregroundStyle(checkIconColor)
                .frame(width: checkboxSize * 0.5, height: checkboxSize * 0.5)
        }
    }
    
    private var uncheckedBoxIcon: some View {
        RoundedRectangle(cornerRadius: 2)
            .stroke()
            .foregroundStyle(checkedBackgroundColor)
            .frame(width: checkboxSize, height: checkboxSize)
    }
}

#Preview {
    Group {
        CheckBoxWithTextButton(isChecked: .constant(true), text: "Allow this to proceed")
        CheckBoxWithTextButton(isChecked: .constant(false), text: "Allow this to proceed")
    }
}
