import MEGASwift

public protocol FloatingAddButtonVisibilityDataSourceProtocol: Sendable {
    var floatingButtonVisibility: AnyAsyncSequence<Bool> { get }
}
