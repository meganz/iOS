import FileLink

struct MEGAFileLinkBuilder: FileLinkBuilderProtocol {
    func build(link: String, with key: String) async -> String {
        await MEGALinkManager.buildFileLink(link, with: key)
    }
}
