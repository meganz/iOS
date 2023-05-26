import Foundation
import MEGADomain

public final class MockFileExistUseCase: FileExistUseCaseProtocol {
    private let fileExist: Bool
    
    public init(fileExist: Bool) {
        self.fileExist = fileExist
    }
    
    public func fileExists(at url: URL) -> Bool {
        fileExist
    }
}
