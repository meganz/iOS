import Foundation
import UIKit

public struct NotificationItem {
    let title: String
    let type: String
    let typeColor: UIColor
    let tag: NotificationTag
    let description: String
    let date: Date?
    let rightThumbnailURL: URL?
    let bottomImageURL: URL?
    
    public init(
        title: String,
        type: String,
        typeColor: UIColor,
        tag: NotificationTag,
        description: String,
        date: Date? = nil,
        rightThumbnailURL: URL? = nil,
        bottomImageURL: URL? = nil
    ) {
        self.title = title
        self.type = type
        self.typeColor = typeColor
        self.tag = tag
        self.description = description
        self.date = date
        self.rightThumbnailURL = rightThumbnailURL
        self.bottomImageURL = bottomImageURL
    }
}
