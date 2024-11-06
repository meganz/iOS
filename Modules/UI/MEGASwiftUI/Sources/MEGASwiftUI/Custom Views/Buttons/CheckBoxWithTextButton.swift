import MEGADesignToken
import SwiftUI

public struct CheckBoxWithTextButton: View {
    @State private var isChecked: Bool
    private let id: Int
    private let text: String
    private let textColor: Color
    private let font: Font
    private let checkIconColor: Color
    private let checkedBackgroundColor: Color
    private let unCheckedBorderColor: Color
    private let checkboxSize: CGFloat
    private let action: (_ isChecked: Bool) -> Void
    
    public init(
        isChecked: Bool,
        id: Int = 0,
        text: String,
        textColor: Color = TokenColors.Text.primary.swiftUI,
        font: Font = .subheadline.bold(),
        checkIconColor: Color = TokenColors.Icon.inverse.swiftUI,
        checkedBackgroundColor: Color = TokenColors.Button.primary.swiftUI,
        unCheckedBorderColor: Color = TokenColors.Border.strong.swiftUI,
        checkboxSize: CGFloat = 20,
        action: @escaping (_ isChecked: Bool) -> Void
    ) {
        self.isChecked = isChecked
        self.id = id
        self.text = text
        self.textColor = textColor
        self.font = font
        self.checkIconColor = checkIconColor
        self.checkedBackgroundColor = checkedBackgroundColor
        self.unCheckedBorderColor = unCheckedBorderColor
        self.checkboxSize = checkboxSize
        self.action = action
    }
    
    public var body: some View {
        Button {
            isChecked.toggle()
            
            action(isChecked)
        } label: {
            HStack(spacing: 12) {
                checkboxIcon
                
                Text(text)
                    .font(font)
                    .foregroundStyle(textColor)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .transaction { transaction in
                transaction.animation = nil
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
        CheckBoxWithTextButton(isChecked: true, text: "Allow this to proceed", action: {_ in })
        CheckBoxWithTextButton(isChecked: false, text: "Allow this to proceed", action: {_ in })
    }
}
