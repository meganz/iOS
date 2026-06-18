import MEGAAppSDKRepo
import MEGADomain
import MEGARepo

enum DependencyInjection {
    static var transferCounterUseCase: some TransferCounterUseCaseProtocol {
        TransferCounterUseCase(
            repo: NodeTransferRepository.newRepo,
            transferInventoryRepository: TransferInventoryRepository.newRepo,
            fileSystemRepository: FileSystemRepository.sharedRepo
        )
    }
}
