import SwiftUI

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
    public let subtitle: String?
    public let font: Font
    public let titleTextColor: Color?
    public let actions: [any Action]

    public init(
        image: Image,
        title: String,
        subtitle: String? = nil,
        font: Font,
        titleTextColor: Color?,
        actions: [any Action] = [],
    ) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.font = font
        self.titleTextColor = titleTextColor
        self.actions = actions
    }
}
