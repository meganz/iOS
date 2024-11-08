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
        TokenColors.Border.strong.swiftUI
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
        .background(TokenColors.Background.page.swiftUI)
        .separatorView(
            offset: 55,
            color: separatorColor
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(menuDetails.sectionText ?? "Menu")
        .accessibilityAddTraits(.isButton)
    }
    
    @ViewBuilder
    private var menuIcon: some View {
        if let menuIcon = menuDetails.icon {
            Image(uiImage: menuIcon)
                .renderingMode(.template)
                .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                .frame(width: 24, height: 24)
                .padding(EdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 10))
                .flipsForRightToLeftLayoutDirection(layoutDirection == .rightToLeft)
        }
    }
    
    private var menuTitleView: some View {
        Text(menuDetails.sectionText ?? "")
            .font(.body)
            .foregroundStyle(TokenColors.Text.primary.swiftUI)
    }
    
    private var disclosureIndicatorView: some View {
        Image(uiImage: menuDetails.disclosureIndicatorIcon)
            .frame(width: 24, height: 24)
            .padding(.horizontal, 12)
            .flipsForRightToLeftLayoutDirection(layoutDirection == .rightToLeft)
    }
}
