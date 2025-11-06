import WebKit

public final class MockWKFrameInfo: WKFrameInfo {
    private let _isMainFrame: Bool
    
    public init(isMainFrame: Bool) {
        _isMainFrame = isMainFrame
    }
    
    public override var isMainFrame: Bool { _isMainFrame }
}

public final class MockWKNavigationAction: WKNavigationAction {
    private let _navigationType: WKNavigationType
    private let _sourceFrame: MockWKFrameInfo
    private let _targetFrame: MockWKFrameInfo?
    
    public init(navigationType: WKNavigationType,
                sourceFrame: MockWKFrameInfo,
                targetFrame: MockWKFrameInfo?) {
        _navigationType = navigationType
        _sourceFrame = sourceFrame
        _targetFrame = targetFrame
    }
    
    public override var navigationType: WKNavigationType { _navigationType }
    
    public override var sourceFrame: WKFrameInfo { _sourceFrame }
    
    public override var targetFrame: WKFrameInfo? { _targetFrame }
}
