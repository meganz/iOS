import MEGAPickerFileProviderDomain

actor MockFileProviderWorkingSetSignalRepository: FileProviderWorkingSetSignalRepositoryProtocol {
    static var newRepo: MockFileProviderWorkingSetSignalRepository { MockFileProviderWorkingSetSignalRepository() }

    private(set) var signalCount = 0

    func signalWorkingSet() {
        signalCount += 1
    }
}
