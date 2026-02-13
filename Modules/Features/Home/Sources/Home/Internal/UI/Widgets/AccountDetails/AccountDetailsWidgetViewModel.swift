import Combine
import MEGAAppSDKRepo
import MEGADomain
import SwiftUI

// [IOS-11315]: Implement the logic to populate user data
@MainActor
final class AccountDetailsWidgetViewModel: ObservableObject {
    struct Dependency {
        let userNameUseCase: any AccountDetailsUserNameUseCaseProtocol
        let planUseCase: any AccountDetailsPlanUseCaseProtocol

        package init(
            userNameUseCase: some AccountDetailsUserNameUseCaseProtocol,
            planUseCase: some AccountDetailsPlanUseCaseProtocol
        ) {
            self.userNameUseCase = userNameUseCase
            self.planUseCase = planUseCase
        }

        init(
            currentUserSource: CurrentUserSource = .shared,
            fullNameHandler: @escaping @Sendable (CurrentUserSource) -> String
        ) {
            let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
            userNameUseCase = AccountDetailsUserNameUseCase(
                currentUserSource: CurrentUserSource.shared,
                accountUseCase: accountUseCase,
                fullNameHandler: fullNameHandler
            )
            planUseCase = AccountDetailsPlanUseCase(accountUseCase: accountUseCase)
        }
    }

    @Published var userName: String = ""
    @Published var plan: String = ""
    @Published var profilePicture: Image
    @Published var storageUsage: String
    @Published var storageUsedFraction: Double

    private var dependency: Dependency

    init(
        dependency: Dependency
    ) {
        self.dependency = dependency
        profilePicture = Image(systemName: "person.crop.circle.fill")
        storageUsage = "10GB of 20GB used"
        storageUsedFraction = 0.9
    }

    func onTask() async {
        async let nameTask: () = monitorUserName()
        async let planTask: () = monitorPlan()
        _ = await (nameTask, planTask)
    }

    private func monitorUserName() async {
        for await name in dependency.userNameUseCase.names {
            userName = name
        }
    }

    private func monitorPlan() async {
        for await accountType in dependency.planUseCase.currentPlan {
            plan = accountType?.toAccountTypeDisplayName() ?? ""
        }
    }

    var storageUsedFractionColor: Color {
        if storageUsedFraction < 0.5 {
            .blue
        } else if storageUsedFraction < 0.75 {
            .yellow
        } else { .red }
    }
}
