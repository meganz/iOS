import MEGAAppSDKRepo
import MEGASdk

public final class MockFolderInfo: MEGAFolderInfo {
    
    private var _versions: Int
    private var _files: Int
    private var _folders: Int
    private var _currentSize: Int64
    private var _versionsSize: Int64
    
    public init(
        versions: Int = 0,
        files: Int = 0,
        folders: Int = 0,
        currentSize: Int64 = 0,
        versionsSize: Int64 = 0
    ) {
        self._versions = versions
        self._files = files
        self._folders = folders
        self._currentSize = currentSize
        self._versionsSize = versionsSize
    }
    
    override public var versions: Int {
        _versions
    }
    
    public override var files: Int {
        _files
    }
    
    public override var folders: Int {
        _folders
    }
    
    public override var currentSize: Int64 {
        _currentSize
    }
    
    public override var versionsSize: Int64 {
        _versionsSize
    }
}
