public typealias VideoPlaylistCreateSetElementsResultEntity = [HandleEntity: Result<Void, any Error>]

extension VideoPlaylistCreateSetElementsResultEntity {
    
    public var successCount: UInt {
        UInt(filter { isSuccess($0.value) }.count)
    }
    
    public var errorCount: UInt {
        UInt(filter { isFailure($0.value) }.count)
    }
    
    private func isSuccess(_ result: Result<Void, any Error>) -> Bool {
        switch result {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    private func isFailure(_ result: Result<Void, any Error>) -> Bool {
        switch result {
        case .success:
            return false
        case .failure:
            return true
        }
    }
}
