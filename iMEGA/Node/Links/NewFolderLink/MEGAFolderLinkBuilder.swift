import FolderLink

struct MEGAFolderLinkBuilder: FolderLinkBuilderProtocol {
    func build(link: String, with key: String) async -> String {
        await MEGALinkManager.buildFolderLink(link, with: key)
    }
}
