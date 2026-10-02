public protocol LeftOffItemRecordUseCaseProtocol: Sendable {
    func record(handle: HandleEntity, name: String) async
    func remove(handle: HandleEntity) async
}
