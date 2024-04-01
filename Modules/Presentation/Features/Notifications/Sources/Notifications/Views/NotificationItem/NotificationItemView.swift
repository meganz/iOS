import MEGADesignToken
import SwiftUI

public struct NotificationItemView: View {
    private let viewModel: NotificationItemViewModel
    
    @Environment(\.colorScheme) var colorScheme
    private var defaultBackgroundColor: Color {
        guard isDesignTokenEnabled else {
            return colorScheme == .dark ? Color(red: 44/255, green: 44/255, blue: 46/255) : Color.white
        }
        return TokenColors.Background.page.swiftUI
    }
    
    private var separatorColor: Color {
        guard isDesignTokenEnabled else {
            return colorScheme == .dark ? Color(red: 0.329, green: 0.329, blue: 0.345, opacity: 0.65) : Color(red: 0.235, green: 0.235, blue: 0.263, opacity: 0.3)
        }
        return TokenColors.Border.strong.swiftUI
    }
    
    public init(viewModel: NotificationItemViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NotificationItemHeaderView(
                type: viewModel.notification.type,
                tag: viewModel.notification.tag
            )
            NotificationItemContentView(
                viewModel: viewModel
            )
        }
        .padding(12)
        .background(defaultBackgroundColor)
        .frame(maxWidth: .infinity)
        .separatorView(offset: 0, color: separatorColor)
    }
}
