import SwiftUI

public struct ListMenuView: View {
    let menuIcon: Image?
    let title: String
    let subTitle: String?
    let rightDetailText: String?
    let action: () -> Void
    
    private let titleFont: Font
    private let titleColor: Color?
    private let subTitleFont: Font
    private let subTitleColor: Color?
    private let rightDetailFont: Font
    private let rightDetailColor: Color?
    private let menuIconSize: CGSize
    
    @Environment(\.colorScheme) var colorScheme
    private var titleTextColor: Color {
        guard let titleColor else {
            return colorScheme == .dark ? .white : .black
        }
        return titleColor
    }
    
    private var subTitleTextColor: Color {
        guard let subTitleColor else {
            return colorScheme == .dark ? .white : .black
        }
        return subTitleColor
    }
    
    private var rightDetailTextColor: Color {
        guard let rightDetailColor else {
            return Color(red: 0.52, green: 0.52, blue: 0.52)
        }
        return rightDetailColor
    }
    
    public init(menuIcon: Image? = nil,
                menuIconSize: CGSize = CGSize(width: 28, height: 28),
                title: String,
                titleColor: Color? = nil,
                titleFont: Font = Font.body,
                subTitle: String? = nil,
                subTitleColor: Color? = nil,
                subTitleFont: Font = Font.caption.weight(.regular),
                rightDetailText: String? = nil,
                rightDetailColor: Color? = nil,
                rightDetailFont: Font = Font.body,
                action: @escaping () -> Void) {
        self.menuIcon = menuIcon
        self.menuIconSize = menuIconSize
        self.title = title
        self.subTitle = subTitle
        self.action = action
        self.titleFont = titleFont
        self.subTitleFont = subTitleFont
        self.titleColor = titleColor
        self.subTitleColor = subTitleColor
        self.rightDetailText = rightDetailText
        self.rightDetailColor = rightDetailColor
        self.rightDetailFont = rightDetailFont
    }
    
    public var body: some View {
        Button {
            action()
        } label: {
            HStack {
                if let menuIcon {
                    menuIcon
                        .resizable()
                        .scaledToFit()
                        .frame(width: menuIconSize.width, height: menuIconSize.height)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(titleFont)
                        .foregroundColor(titleTextColor)
                    
                    if let subTitle {
                        Text(subTitle)
                            .font(subTitleFont)
                            .foregroundColor(subTitleTextColor)
                    }
                }
                
                if let rightDetailText {
                    Spacer()
                    
                    Text(rightDetailText)
                        .font(rightDetailFont)
                        .foregroundColor(rightDetailTextColor)
                }
            }
            .addDisclosureIndicator()
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
