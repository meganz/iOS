import MEGAAssets
import MEGADesignToken
import MEGASwiftUI
import SwiftUI

public struct MyAccountHallMenuView: View {
    @Environment(\.layoutDirection) var layoutDirection
    private var menuDetails: MyAccountHallCellData
    
    public init(menuDetails: MyAccountHallCellData) {
        self.menuDetails = menuDetails
    }
    
    @Environment(\.colorScheme) var colorScheme
    private var separatorColor: Color {
        guard isDesignTokenEnabled else {
            return colorScheme == .dark ? Color(red: 38/255, green: 38/255, blue: 38/255, opacity: 1.0) : Color(red: 240/255, green: 240/255, blue: 240/255, opacity: 1.0)
        }
        return TokenColors.Border.strong.swiftUI
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(red: 28/255, green: 28/255, blue: 30/255) : Color.white
    }
    
    public var body: some View {
        HStack {
            menuIcon
            menuTitleView
            Spacer()
            disclosureIndicatorView
        }
        .padding(.vertical, 20)
        .background(
            isDesignTokenEnabled ? TokenColors.Background.page.swiftUI : backgroundColor
        )
        .separatorView(
            offset: 55,
            color: separatorColor
        )
    }
    
    @ViewBuilder
    private var menuIcon: some View {
        if let menuIcon = menuDetails.icon {
            Image(uiImage: menuIcon)
                .renderingMode(isDesignTokenEnabled ? .template : .original)
                .foregroundStyle(isDesignTokenEnabled ? TokenColors.Icon.primary.swiftUI : Color.primary)
                .frame(width: 24, height: 24)
                .padding(EdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 10))
                .flipsForRightToLeftLayoutDirection(layoutDirection == .rightToLeft)
        }
    }
    
    private var menuTitleView: some View {
        Text(menuDetails.sectionText ?? "")
            .font(.body)
            .foregroundStyle(
                isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : Color(UIColor.label)
            )
    }
    
    private var disclosureIndicatorView: some View {
        Image(uiImage: menuDetails.disclosureIndicatorIcon)
            .frame(width: 24, height: 24)
            .padding(.horizontal, 12)
            .flipsForRightToLeftLayoutDirection(layoutDirection == .rightToLeft)
    }
}
