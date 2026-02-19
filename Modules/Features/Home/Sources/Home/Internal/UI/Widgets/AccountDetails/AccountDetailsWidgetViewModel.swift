import Combine
import MEGAAppSDKRepo
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPreference
import SwiftUI
import UIKit

// [IOS-11315]: Implement the logic to populate user data
@MainActor
final class AccountDetailsWidgetViewModel: ObservableObject {
    struct Dependency {
        let userNameUseCase: any AccountDetailsUserNameUseCaseProtocol
        let planUseCase: any AccountDetailsPlanUseCaseProtocol
        let storageUseCase: any AccountDetailsStorageUseCaseProtocol
        let avatarUseCase: any AccountDetailsAvatarUseCaseProtocol

        package init(
            userNameUseCase: some AccountDetailsUserNameUseCaseProtocol,
            planUseCase: some AccountDetailsPlanUseCaseProtocol,
            storageUseCase: some AccountDetailsStorageUseCaseProtocol,
            avatarUseCase: some AccountDetailsAvatarUseCaseProtocol,
        ) {
            self.userNameUseCase = userNameUseCase
            self.planUseCase = planUseCase
            self.storageUseCase = storageUseCase
            self.avatarUseCase = avatarUseCase
        }

        init(
            currentUserSource: CurrentUserSource = .shared,
            fullNameHandler: @escaping @Sendable (CurrentUserSource) -> String,
            userImageUseCase: some UserImageUseCaseProtocol,
            avatarFetcher: @escaping @Sendable () async -> Image?
        ) {
            let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
            let accountStorageUseCase = AccountStorageUseCase(
                accountRepository: AccountRepository.newRepo,
                preferenceUseCase: PreferenceUseCase.default
            )

            let userNameUseCase = AccountDetailsUserNameUseCase(
                currentUserSource: currentUserSource,
                accountUseCase: accountUseCase,
                fullNameHandler: fullNameHandler
            )
            
            self.userNameUseCase = userNameUseCase
            planUseCase = AccountDetailsPlanUseCase(accountUseCase: accountUseCase)
            storageUseCase = AccountDetailsStorageUseCase(
                accountUseCase: accountUseCase,
                accountStorageUseCase: accountStorageUseCase
            )
            avatarUseCase = AccountDetailsAvatarUseCase(
                accountUseCase: accountUseCase,
                userNameUseCase: userNameUseCase,
                avatarFetcher: avatarFetcher
            )
        }
    }

    @Published var title: String = ""
    @Published var plan: String = ""
    @Published var profilePicture: Image = Image(systemName: "person.crop.circle.fill")
    @Published var storageUsage: String = ""
    @Published var storageUsedFraction: Double = 0

    private var dependency: Dependency

    init(
        dependency: Dependency
    ) {
        self.dependency = dependency
    }

    func onTask() async {
        async let nameTask: () = monitorUserName()
        async let planTask: () = monitorPlan()
        async let storageTask: () = monitorStorage()
        async let profilePictureTask: () = monitorAvatar()
        _ = await (nameTask, planTask, storageTask, profilePictureTask)
    }

    private func monitorUserName() async {
        for await name in dependency.userNameUseCase.names {
            title = titleText(for: name)
        }
    }

    private func monitorPlan() async {
        for await accountType in dependency.planUseCase.currentPlan {
            plan = accountType?.toAccountTypeDisplayName() ?? ""
        }
    }

    private func monitorAvatar() async {
        for await image in dependency.avatarUseCase.avatar {
            profilePicture = image
        }
    }

    private func monitorStorage() async {
        for await storageDetail in dependency.storageUseCase.storageDetails {
            storageUsage = storageText(for: storageDetail)
            storageUsedFraction = storageFraction(for: storageDetail)
        }
    }

    package func titleText(for name: String) -> String {
        Strings.Localizable.Home.Widgets.AccountDetails.nameTitle(name)
    }

    package func storageText(for details: AccountStorageDetails?) -> String {
        guard let details else { return "" }
        switch details {
        case .unlimited(let storageUsed):
            let storageUsedString = String.memoryStyleString(fromByteCount: storageUsed).formattedByteCountString()
            return Strings.Localizable.AccountMenu.BusinessAndProFlexiAccountsStorageUsed.title(storageUsedString)
        case .limited(let storageUsed, let storageMax):
            let storageUsedString = String.memoryStyleString(fromByteCount: storageUsed).formattedByteCountString()
            let storageMaxString = String.memoryStyleString(fromByteCount: storageMax).formattedByteCountString()
            return Strings.Localizable.Home.Widgets.AccountDetails.storageUsage(storageUsedString, storageMaxString)
        }
    }

    package func storageFraction(for details: AccountStorageDetails?) -> Double {
        guard let details else { return 0 }
        switch details {
        case .unlimited:
            return 0
        case .limited(let storageUsed, let storageMax):
            return Double(storageUsed) / Double(storageMax)
        }
    }

    var storageUsedFractionColor: Color {
        if storageUsedFraction > 0.9 { return TokenColors.Support.error.swiftUI }
        if storageUsedFraction > 0.8 { return TokenColors.Support.warning.swiftUI }
        return TokenColors.Support.success.swiftUI
    }
}
