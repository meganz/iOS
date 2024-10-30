import SwiftUI

public struct MarkdownSupportTextView: View {
    
    let localizedStringKey: LocalizedStringKey
    
    public init(string: String) {
        self.localizedStringKey = LocalizedStringKey(string)
    }
    
    public var body: some View {
        ScrollView {
            Text(localizedStringKey)
                .textSelection(.enabled)
                .multilineTextAlignment(.leading)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - Previvew

#Preview {
    MarkdownSupportTextView(string: "**Hello,**\n\n**Welcome to SwiftUI!**\n\nThis is a Markdown string.")
}

#Preview {
    MarkdownSupportTextView(string: "**Hello** \n *world*!")
}

#Preview {
    MarkdownSupportTextView(
        string: """
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
    )
}
