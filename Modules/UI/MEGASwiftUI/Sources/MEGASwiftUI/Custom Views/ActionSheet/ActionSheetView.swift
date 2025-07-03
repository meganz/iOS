import MEGADesignToken
import SwiftUI

public struct ActionSheetButtonViewModel: Identifiable {
    public var id: UUID
    var icon: Image
    var title: String
    var subtitle: String?
    var disclosureIcon: Image
    var action: () -> Void
    
    public init(
        id: UUID,
        icon: Image,
        title: String,
        subtitle: String? = nil,
        disclosureIcon: Image,
        action: @escaping () -> Void
    ) {
        self.id = id
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.disclosureIcon = disclosureIcon
    }
}

public struct ActionSheetContentView<HeaderView: View>: View {
    var style: Style = .default
    var actionSheetButtonViewModels: [ActionSheetButtonViewModel]
    var headerView: HeaderView
    var actionHandler: ((@escaping () -> Void) -> Void)?
    
    public enum Style {
        case `default`
        case plainIgnoreHeaderIgnoreScrolling
    }
    
    private var bodyBackgroundColor: Color {
        TokenColors.Background.surface1.swiftUI
    }

    public init(
        style: ActionSheetContentView.Style = .default,
        headerView: HeaderView,
        actionSheetButtonViewModels: [ActionSheetButtonViewModel],
        actionHandler: ((@escaping () -> Void) -> Void)? = nil
    ) {
        self.style = style
        self.headerView = headerView
        self.actionSheetButtonViewModels = actionSheetButtonViewModels
        self.actionHandler = actionHandler
    }

    public var body: some View {
        switch style {
        case .default:
            defaultContent
        case .plainIgnoreHeaderIgnoreScrolling:
            plainIgnoreHeaderIgnoreScrolling
        }
    }
    
    private var defaultContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    Capsule()
                        .fill(Color.secondary)
                        .opacity(0.5)
                        .frame(width: 36, height: 5)
                        .padding(5)
                    
                    headerView
                        .padding(.bottom, 2)
                    
                    Divider()
                }
                .background(TokenColors.Background.surface2.swiftUI)
                
                ForEach(actionSheetButtonViewModels, id: \.id) {
                    ActionSheetButton(
                        viewModel: $0,
                        actionHandler: actionHandler)
                }
            }
            .padding([.bottom], 30)
        }
        .background(bodyBackgroundColor)
    }
    
    private var plainIgnoreHeaderIgnoreScrolling: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 16)
            ForEach(actionSheetButtonViewModels, id: \.id) {
                ActionSheetButton(
                    viewModel: $0,
                    actionHandler: actionHandler)
            }
            Spacer()
        }
        .padding([.bottom, .top], 30)
        .background(bodyBackgroundColor)
    }
}

public struct ActionSheetButton: View {
    @Environment(\.dismiss) var dismiss
    var viewModel: ActionSheetButtonViewModel
    var actionHandler: ((@escaping () -> Void) -> Void)?

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                viewModel.icon
                    .frame(width: 28, height: 28)
                    .padding(16)
                
                Text(viewModel.title)
                    .font(.body)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                
                Spacer()
                if let subtitle = viewModel.subtitle {
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                    
                    viewModel.disclosureIcon
                        .padding([.trailing], 16)
                        .padding([.leading], 5)
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                dismiss()
                if let actionHandler {
                    actionHandler(viewModel.action)
                } else {
                    viewModel.action()
                }
            }
            Divider()
                .padding([.leading], 60)
        }
        .background(TokenColors.Background.surface1.swiftUI)
    }
}
