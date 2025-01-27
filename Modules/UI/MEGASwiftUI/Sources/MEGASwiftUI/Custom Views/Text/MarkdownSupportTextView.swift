import SwiftUI

public struct MarkdownSupportTextView: View {
    @StateObject private var viewModel: MarkdownSupportTextViewModel
    
    public init(viewModel: @autoclosure @escaping () -> MarkdownSupportTextViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }
    
    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(viewModel.textChunks.indices, id: \.self) { index in
                    Text(viewModel.textChunks[index])
                        .textSelection(.enabled)
                }
            }
            .padding(.vertical)
            .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .onAppear {
            viewModel.loadText()
        }
    }
}

// MARK: - Previvew

#Preview {
    MarkdownSupportTextView(viewModel: MarkdownSupportTextViewModel(string: "**Hello,**\n\n**Welcome to SwiftUI!**\n\nThis is a Markdown string."))
}

#Preview {
    MarkdownSupportTextView(viewModel: MarkdownSupportTextViewModel(string: "**Hello** \n *world*!"))
}

#Preview {
    MarkdownSupportTextView(
        viewModel: MarkdownSupportTextViewModel(string: """
                **SwiftUI** is Apple's framework for building UI with a declarative syntax. It's designed to work seamlessly with *Swift*, allowing developers to write beautiful UIs with minimal code. In SwiftUI, we can use `VStack`, `HStack`, and `ZStack` to arrange views vertically, horizontally, or in layers.
                 
                For example, you can create a vertical stack using the `VStack` layout:
                 
                ```swift
                VStack {
                    Text("Hello, world!")
                    Text("Welcome to SwiftUI")
                }
                ```
                 
                This framework not only simplifies UI creation but also brings **native performance** to all Apple platforms. You can visit [Apple's SwiftUI Documentation](https://developer.apple.com/documentation/swiftui) for more details.
                 
                ~~Old approaches to UI development~~ are quickly becoming a thing of the past, and SwiftUI is the future. Don't forget to add `@State` properties to track changes in your views, like this:
                 
                ```swift
                @State var counter = 0
                ```
                 
                Combine the power of **modern Swift** and *elegant UI frameworks* to build stunning apps with **SwiftUI**!
                """
    ))
}
