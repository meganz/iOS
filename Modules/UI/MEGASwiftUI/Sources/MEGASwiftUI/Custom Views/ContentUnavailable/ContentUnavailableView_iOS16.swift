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
                    actions()
                    Spacer()
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
        color: Color
    ) {
        self.image = image
        self.title = title
        self.font = font
        self.color = color
    }
    
    public let image: Image
    public let title: String
    public let font: Font
    public let color: Color
    
}

extension ContentUnavailableView_iOS16 where Label == Image, Description == Text?, Actions == EmptyView {
    
    public init(viewModel: ContentUnavailableView_iOS16ViewModel) {
        
        self.label = {
            viewModel
                .image
                .resizable()
        }
        self.description = {
            Text(viewModel.title)
                .foregroundColor(viewModel.color)
                .font(viewModel.font)
        }
        self.actions = {
            EmptyView()
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
