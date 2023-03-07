import FileProvider

final class FileProviderEnumerator: NSObject, NSFileProviderEnumerator {
    
    private let identifier: NSFileProviderItemIdentifier
    
    init(identifier: NSFileProviderItemIdentifier) {
        self.identifier = identifier
        super.init()
    }

    func invalidate() {
        MEGALogDebug("[Picker] invalidate")
    }

    func enumerateItems(for observer: NSFileProviderEnumerationObserver, startingAt page: NSFileProviderPage) {
        do {
            let items = try fetchItems()
            observer.didEnumerate(items)
        } catch (let error) {
            observer.finishEnumeratingWithError(error)
            return
        }
        
        observer.finishEnumerating(upTo: nil)
    }
    
    // MARK: - Private
    
    private func fetchItems() throws -> [FileProviderItem] {
        var items: [FileProviderItem] = []
        var path: String
        if identifier == NSFileProviderItemIdentifier.rootContainer {
            path = "/"
        } else {
            path = identifier.rawValue
        }
        guard let node = MEGASdk.shared.node(forPath: path) else {
            throw NSFileProviderError(.noSuchItem)
        }
        
        if node.isFolder() {
            let childrenArray = MEGASdk.shared.children(forParent: node).toNodeArray()
            childrenArray.forEach { items.append(FileProviderItem(node: $0.toNodeEntity())) }
        } else {
            items.append(FileProviderItem(node: node.toNodeEntity()))
        }
        return items
    }
}
