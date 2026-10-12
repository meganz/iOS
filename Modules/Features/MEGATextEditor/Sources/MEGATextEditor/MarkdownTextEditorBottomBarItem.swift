import MEGADomain

/// The bottom bar actions of a text file in view mode.
public enum MarkdownTextEditorBottomBarItem: Equatable, Sendable {
    case download
    case edit
    case export
    case `import`

    /// Download always. Edit unless the access is read only. Export for the owner, else Import.
    public static func items(for accessType: NodeAccessTypeEntity) -> [MarkdownTextEditorBottomBarItem] {
        var items: [MarkdownTextEditorBottomBarItem] = [.download]
        if accessType != .read {
            items.append(.edit)
        }
        items.append(accessType == .owner ? .export : .import)
        return items
    }
}
