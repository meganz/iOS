import SwiftUI

public struct ContentUnavailableView_iOS16<Label, Description, Actions>: View where Label: View, Description: View, Actions: View {
    
    var label: () -> Label
    var description: () -> Description
    var actions: () -> Actions
    
    public init(
        @ViewBuilder label: @escaping () -> Label,
        @ViewBuilder description: @escaping  () -> Description = { EmptyView() },
        @ViewBuilder actions: @escaping  () -> Actions = { EmptyView() }
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
                    Spacer().frame(height: 40)
                }
                Spacer()
            }
        }
    }
    
    func iconSize(_ proxy: GeometryProxy) -> CGFloat {
        proxy.size.height > 300 ? 120 : 80
    }
}

public struct ContentUnavailableView_iOS16ViewModel {
    public init(
        image: Image,
        title: String,
        font: Font,
        color: Color,
        actions: [Action] = []
    ) {
        self.image = image
        self.title = title
        self.font = font
        self.color = color
        self.actions = actions
    }
    
    public let image: Image
    public let title: String
    public let font: Font
    public let color: Color
    public let actions: [Action]
    
    public struct Action {
        public init(
            title: String,
            handler: @escaping () -> Void,
            color: Color
        ) {
            self.title = title
            self.handler = handler
            self.color = color
        }
        
        public let title: String
        public let handler: () -> Void
        public let color: Color
    }
}

extension ContentUnavailableView_iOS16 where Label == Image, Description == Text, Actions == ActionsView {

    public init(viewModel: ContentUnavailableView_iOS16ViewModel) {
        
        self.label = {
            viewModel.image.resizable()
        }
        self.description = {
            Text(viewModel.title)
                .foregroundColor(viewModel.color)
                .font(viewModel.font)
        }
        self.actions = {
            ActionsView(actions: viewModel.actions)
        }
    }
}

public struct ActionsView: View {
    public let actions: [ContentUnavailableView_iOS16ViewModel.Action]

    public var body: some View {
        Group {
            if actions.isEmpty {
                EmptyView()
            } else {
                VStack {
                    ForEach(Array(actions.indices), id: \.self) { index in
                        Button(action: actions[index].handler) {
                            Text(actions[index].title)
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                                .padding([.horizontal], 40)
                        }
                        .frame(height: 50)
                        .background(actions[index].color)
                        .cornerRadius(8)
                    }
                }
            }
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

struct ContentUnavailableView_iOS16_Previews: PreviewProvider {
    static var previews: some View {
        ContentUnavailableView_iOS16 {
            Label("Label", systemImage: "42.circle")
        } description: {
            Text("Try different search query")
        } actions: {
            EmptyView()
        }
        
    }
}
