import MEGADesignToken
import SwiftUI

public struct NotificationItemView: View {
    private let viewModel: NotificationItemViewModel
    
    @Environment(\.colorScheme) var colorScheme
    
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
        .background(TokenColors.Background.page.swiftUI)
        .frame(maxWidth: .infinity)
        .separatorView(offset: 0, color: TokenColors.Border.strong.swiftUI)
    }
}
