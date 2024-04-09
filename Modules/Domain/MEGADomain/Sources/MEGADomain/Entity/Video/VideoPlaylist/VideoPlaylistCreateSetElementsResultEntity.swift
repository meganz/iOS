public typealias VideoPlaylistCreateSetElementsResultEntity = [HandleEntity: Result<SetEntity, any Error>]

extension VideoPlaylistCreateSetElementsResultEntity {
    
    public var successCount: UInt {
        UInt(filter { isSuccess($0.value) }.count)
    }
    
    public var errorCount: UInt {
        UInt(filter { isFailure($0.value) }.count)
    }
    
    private func isSuccess(_ result: Result<SetEntity, any Error>) -> Bool {
        switch result {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    private func isFailure(_ result: Result<SetEntity, any Error>) -> Bool {
        switch result {
        case .success:
            return false
        case .failure:
            return true
        }
    }
}
