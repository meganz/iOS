import Combine

public final class PhotoAlbumContainerInteractionManager {
    public enum Page {
        case timeline
        case album
    }
    public var pageSwitchPublisher: AnyPublisher<Page, Never> {
        pageSwitchSubject.eraseToAnyPublisher()
    }
    @Published public var searchBarText: String?
    private let pageSwitchSubject = PassthroughSubject<Page, Never>()
    
    public init() { }
    
    func changePage(to page: Page) {
        pageSwitchSubject.send(page)
    }
}
