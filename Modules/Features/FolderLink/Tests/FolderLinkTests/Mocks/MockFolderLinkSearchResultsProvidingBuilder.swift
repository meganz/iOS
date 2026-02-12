import MEGADomain
import FolderLink
import Search
import SearchMock

final class MockFolderLinkSearchResultsProvidingBuilder: FolderLinkSearchResultsProvidingBuilderProtocol {
    func build(with handle: HandleEntity) -> any SearchResultsProviding {
        MockSearchResultsProviding()
    }
}
