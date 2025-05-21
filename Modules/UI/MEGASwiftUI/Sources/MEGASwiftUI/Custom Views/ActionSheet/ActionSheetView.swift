import MEGADesignToken
import SwiftUI

public struct ActionSheetContentView<HeaderView: View>: View {
    var style: Style = .default
    var actionButtons: [ActionSheetButton]
    var headerView: HeaderView
    
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
        actionButtons: [ActionSheetButton]
    ) {
        self.style = style
        self.headerView = headerView
        self.actionButtons = actionButtons
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
                
                ForEach(actionButtons, id: \.id) { button in
                    button
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
            ForEach(actionButtons, id: \.id) { button in
                button
            }
            Spacer()
        }
        .padding([.bottom, .top], 30)
        .background(bodyBackgroundColor)
    }
}

public struct ActionSheetButton: View {
    @Environment(\.presentationMode) var presentationMode
    var id: UUID
    var icon: Image
    var title: String
    var subtitle: String?
    var disclosureIcon: Image
    var action: () -> Void
    
    public init(id: UUID, icon: Image, title: String, subtitle: String? = nil, disclosureIcon: Image, action: @escaping () -> Void) {
        self.id = id
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.disclosureIcon = disclosureIcon
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                icon
                    .frame(width: 28, height: 28)
                    .padding(16)
                
                Text(title)
                    .font(.body)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                
                Spacer()
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                    
                    disclosureIcon
                        .padding([.trailing], 16)
                        .padding([.leading], 5)
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                action()
                presentationMode.wrappedValue.dismiss()
            }
            Divider()
                .padding([.leading], 60)
        }
        .background(TokenColors.Background.surface1.swiftUI)
    }
}
