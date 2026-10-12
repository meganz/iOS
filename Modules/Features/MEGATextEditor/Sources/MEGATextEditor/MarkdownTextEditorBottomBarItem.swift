import MEGADomain

/// The bottom bar actions of a text file in view mode.
public enum MarkdownTextEditorBottomBarItem: Equatable, Sendable {
    case download
    case edit
    case export
    case `import`

    /// Download always. Edit only with write access, so an unknown access cannot edit. Export for the owner, else Import.
    public static func items(for accessType: NodeAccessTypeEntity) -> [MarkdownTextEditorBottomBarItem] {
        var items: [MarkdownTextEditorBottomBarItem] = [.download]
        if accessType != .read && accessType != .unknown {
            items.append(.edit)
        }
        items.append(accessType == .owner ? .export : .import)
        return items
    }
}
