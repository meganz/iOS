import FileProvider
import MEGADomain
import MEGAPickerFileProviderDomain

extension FileProviderItemEntity {
    /// A file, or a folder, whose versions change with `name`.
    static func make(
        _ identifier: String,
        in parentIdentifier: NSFileProviderItemIdentifier = .rootContainer,
        name: String? = nil,
        isFolder: Bool = false
    ) -> FileProviderItemEntity {
        FileProviderItemEntity(
            identifier: NSFileProviderItemIdentifier(identifier),
            parentIdentifier: parentIdentifier,
            node: NodeEntity(
                name: name ?? identifier,
                base64Handle: identifier,
                isFile: !isFolder,
                isFolder: isFolder,
                modificationTime: Date(timeIntervalSince1970: 0)
            ),
            childCount: isFolder ? 0 : nil
        )
    }
}
