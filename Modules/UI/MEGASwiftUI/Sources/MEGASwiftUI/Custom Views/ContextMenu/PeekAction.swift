import SwiftUI
import UIKit

public struct PeekAction {
    public  init(
        title: String,
        imageName: String,
        handler: @escaping () -> Void
    ) {
        self.title = title
        self.imageName = imageName
        self.handler = handler
    }
    
    public let title: String
    public let imageName: String
    public let handler: () -> Void
}

extension Array where Element == PeekAction {
    public var toUIActions: [UIAction] {
        self.map { peekAction in
            UIAction(
                title: peekAction.title,
                image: UIImage(systemName: peekAction.imageName),
                handler: { _ in
                    peekAction.handler()
                }
            )
        }
    }
}

public struct PreviewContent {
    public init(
        actions: [PeekAction],
        previewMode: PreviewContent.PreviewMode
    ) {
        self.actions = actions
        self.previewMode = previewMode
    }
    
    public enum PreviewMode {
        case noPreview
        case preview(UIContextMenuContentPreviewProvider)
    }
    
    public let actions: [PeekAction]
    public let previewMode: PreviewMode
}
