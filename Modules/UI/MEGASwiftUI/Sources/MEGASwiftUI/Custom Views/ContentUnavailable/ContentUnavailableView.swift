import MEGADesignToken
import SwiftUI

public struct ContentUnavailableView<Label, Description, Actions>: View where Label: View, Description: View, Actions: View {
    @Environment(\.colorScheme) var colorScheme

    var label: () -> Label
    var description: () -> Description
    var actions: () -> Actions
    
    public init(
        @ViewBuilder label: @escaping () -> Label,
        @ViewBuilder description: @escaping () -> Description = { EmptyView() },
        @ViewBuilder actions: @escaping () -> Actions = { EmptyView() }
    ) {
        self.label = label
        self.description = description
        self.actions = actions
    }
    
    public var body: some View {
        backwardsCompatible
    }
    
    var backwardsCompatible: some View {       
        GeometryReader { geo in
            HStack {
                Spacer()
                VStack {
                    Spacer()
                    label()
                        .scaledToFit()
                        .foregroundColor(Color.gray)
                        .frame(
                            width: iconSize(geo),
                            height: iconSize(geo)
                        )
                        .labelStyle(VerticalLabelStyle())
                    Spacer()
                        .frame(height: 10)
                    description()
                    Spacer()
                    actions()
                    Spacer().frame(height: 27)
                }
                Spacer()
            }
        }
    }
    
    func iconSize(_ proxy: GeometryProxy) -> CGFloat {
        proxy.size.height > 300 ? 120 : 80
    }
}

public protocol Action {
    var title: String { get }
    var backgroundColor: Color? { get }
}

public struct ContentUnavailableViewModel {
    public struct ButtonAction: Action {
        public let id = UUID()
        public let title: String
        public let titleTextColor: Color?
        public let backgroundColor: Color?
        public let image: Image?
        public let handler: () -> Void

        public init(
            title: String,
            titleTextColor: Color? = nil,
            backgroundColor: Color? = nil,
            image: Image?,
            handler: @escaping () -> Void
        ) {
            self.title = title
            self.titleTextColor = titleTextColor
            self.backgroundColor = backgroundColor
            self.image = image
            self.handler = handler
        }
    }

    public struct MenuAction: Action {
        public let id = UUID()
        public let title: String
        public let titleTextColor: Color?
        public let backgroundColor: Color?
        public let actions: [ButtonAction]
        public init(
            title: String,
            titleTextColor: Color? = nil,
            backgroundColor: Color? = nil,
            actions: [ButtonAction]
        ) {
            self.title = title
            self.titleTextColor = titleTextColor
            self.backgroundColor = backgroundColor
            self.actions = actions
        }
    }

    public let image: Image
    public let title: String
    public let font: Font
    public let titleTextColor: Color?
    public let actions: [any Action]

    public init(
        image: Image,
        title: String,
        font: Font,
        titleTextColor: Color?,
        actions: [any Action] = []
    ) {
        self.image = image
        self.title = title
        self.font = font
        self.titleTextColor = titleTextColor
        self.actions = actions
    }
}

public struct ActionsView: View {
    public let actions: [any Action]

    public init(actions: [any Action]) {
        self.actions = actions
    }

    public var body: some View {
        VStack {
            ForEach(0..<actions.count, id: \.self) { index in
                if let buttonAction = actions[index] as? ContentUnavailableViewModel.ButtonAction {
                    ButtonActionView(action: buttonAction)
                } else if let menuAction = actions[index] as? ContentUnavailableViewModel.MenuAction {
                    MenuActionView(action: menuAction)
                } else {
                    EmptyView()
                }
            }
        }
        .frame(maxWidth: 480)
        .padding([.horizontal], 40)
    }
}

extension ContentUnavailableView where Label == Image, Description == Text, Actions == ActionsView {

    public init(viewModel: ContentUnavailableViewModel) {

        self.label = {
            viewModel.image.resizable()
        }
        self.description = {
            Text(viewModel.title)
                .foregroundColor(viewModel.titleTextColor)
                .font(viewModel.font)
        }
        self.actions = {
            ActionsView(actions: viewModel.actions)
        }
    }
}

struct VerticalLabelStyle: LabelStyle {
    @Environment(\.sizeCategory) var size

    func makeBody(configuration: Configuration) -> some View {
        VStack {
            configuration.icon
            configuration.title
        }
    }
}

struct ButtonActionView: View {
    let action: ContentUnavailableViewModel.ButtonAction

    public var body: some View {
        Button(action: action.handler) {
            if let image = action.image {
                Label {
                    text(for: action.title)
                } icon: {
                    image
                }
            } else {
                text(for: action.title)
            }
        }
        .frame(width: 288, height: 50)
        .background(action.backgroundColor)
        .cornerRadius(8)
    }

    private func text(for title: String) -> some View {
        Text(title)
            .fontWeight(.semibold)
            .foregroundStyle(action.titleTextColor ?? TokenColors.Text.onColor.swiftUI)
    }
}

struct MenuActionView: View {
    let action: ContentUnavailableViewModel.MenuAction

    public var body: some View {
        Menu {
            ForEach(Array(action.actions.indices), id: \.self) { index in
                ButtonActionView(action: action.actions[index])
            }
        } label: {
            Text(action.title)
                .foregroundColor(action.titleTextColor ?? .white)
                .fontWeight(.semibold)
                .frame(width: 288, height: 50)
                .background(action.backgroundColor)
                .cornerRadius(8)
        }
    }
}

#Preview {
    ContentUnavailableView {
        Label("Label", systemImage: "42.circle")
    } description: {
        Text("Try different search query")
    } actions: {
        EmptyView()
    }
}
