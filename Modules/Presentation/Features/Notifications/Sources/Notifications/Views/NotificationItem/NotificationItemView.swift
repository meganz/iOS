import MEGADesignToken
import SwiftUI

public struct NotificationItemView: View {
    private let viewModel: NotificationItemViewModel
    
    @Environment(\.colorScheme) var colorScheme
    private var backgroundColor: Color {
        guard isDesignTokenEnabled else {
            return colorScheme == .dark ? Color(red: 0.110, green: 0.110, blue: 0.118) : Color(red: 0.980, green: 0.980, blue: 0.980)
        }
        return TokenColors.Background.surface1.swiftUI
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
            VStack {
                NotificationItemHeaderView(
                    type: viewModel.notification.type,
                    tag: viewModel.notification.tag
                )
                NotificationItemContentView(
                    viewModel: viewModel
                )
            }
            .padding(12)
            .background(backgroundColor)
            
            separatorColor
                .frame(maxWidth: .infinity, maxHeight: 0.4)
        }
        .frame(maxWidth: .infinity)
    }
}
