import MEGADomain
import SwiftUI

public struct NodeUploadAction: Sendable, Identifiable {
    public var id: UploadAddActionEntity { actionEntity }

    let actionEntity: UploadAddActionEntity
    let image: Image
    let title: String
    let action: @MainActor () -> Void

    public init(
        actionEntity: UploadAddActionEntity,
        image: Image,
        title: String,
        action: @escaping @MainActor () -> Void
    ) {
        self.actionEntity = actionEntity
        self.image = image
        self.title = title
        self.action = action
    }
}
