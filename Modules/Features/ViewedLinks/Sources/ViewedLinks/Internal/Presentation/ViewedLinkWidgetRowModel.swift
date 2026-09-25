import Foundation
struct ViewedLinkWidgetRowModel: Identifiable {
    let link: ViewedLinkEntity
    var id: Int {
        var hasher = Hasher()
        hasher.combine(link.handle)
        hasher.combine(link.name)
        return hasher.finalize()
    }

    var name: String { link.name }
    var isFolder: Bool { link.isFolder }
    var linkURL: URL { link.linkURL }
}

extension ViewedLinkEntity {
    var toWidgetRowModel: ViewedLinkWidgetRowModel {
        .init(link: self)
    }
}
