import WebKit

final class MockWKFrameInfo: WKFrameInfo {
    private let _isMainFrame: Bool
    
    init(isMainFrame: Bool) {
        _isMainFrame = isMainFrame
    }
    
    override var isMainFrame: Bool { _isMainFrame }
}

final class MockWKNavigationAction: WKNavigationAction {
    private let _navigationType: WKNavigationType
    private let _sourceFrame: MockWKFrameInfo
    private let _targetFrame: MockWKFrameInfo?
    
    init(navigationType: WKNavigationType,
         sourceFrame: MockWKFrameInfo,
         targetFrame: MockWKFrameInfo?) {
        _navigationType = navigationType
        _sourceFrame = sourceFrame
        _targetFrame = targetFrame
    }
    
    override var navigationType: WKNavigationType { _navigationType }
    
    override var sourceFrame: WKFrameInfo { _sourceFrame }
    
    override var targetFrame: WKFrameInfo? { _targetFrame }
}
