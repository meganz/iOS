import MEGAAppSDKRepo
import MEGADomain

enum Dependency {
    static var quotaDialogUseCase: QuotaDialogUseCase {
        QuotaDialogUseCase(accountUseCase: AccountUseCase(repository: AccountRepository.newRepo))
    }
}
