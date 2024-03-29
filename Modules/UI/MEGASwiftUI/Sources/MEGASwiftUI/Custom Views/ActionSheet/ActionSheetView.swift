import SwiftUI

public struct ActionSheetContentView<HeaderView: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    var actionButtons: [ActionSheetButton]
    var headerView: HeaderView

    public init(headerView: HeaderView, actionButtons: [ActionSheetButton]) {
        self.headerView = headerView
        self.actionButtons = actionButtons
    }

    public var body: some View {
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
                .background(colorScheme == .dark ? Color(red: 0.17, green: 0.17, blue: 0.18) : Color(red: 0.97, green: 0.97, blue: 0.97))
                
                ForEach(actionButtons, id: \.self) { button in
                    button
                }
            }
            .padding([.bottom], 30)
        }
    }
}

public struct ActionSheetButton: View, Hashable {
    @Environment(\.presentationMode) var presentationMode
    var icon: String
    var title: String
    var subtitle: String?
    var action: () -> Void
    
    public init(icon: String, title: String, subtitle: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }
    
    public static func == (lhs: ActionSheetButton, rhs: ActionSheetButton) -> Bool {
        lhs.icon == rhs.icon && lhs.title == rhs.title && lhs.subtitle == rhs.subtitle
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(icon)
        hasher.combine(title)
        hasher.combine(subtitle)
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(icon)
                    .frame(width: 28, height: 28)
                    .padding(16)
                
                Text(title)
                    .font(.body)
                
                Spacer()
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.callout)
                        .foregroundColor(Color(red: 0.52, green: 0.52, blue: 0.52))
                    
                    Image("standardDisclosureIndicator")
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
    }
}
