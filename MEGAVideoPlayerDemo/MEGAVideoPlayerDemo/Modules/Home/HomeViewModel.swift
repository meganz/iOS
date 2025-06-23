import MEGAAccountManagement
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    private let offboardingUseCase: any OffboardingUseCaseProtocol

    init(offboardingUseCase: some OffboardingUseCaseProtocol) {
        self.offboardingUseCase = offboardingUseCase
    }

    func logout() async {
        await offboardingUseCase.activeLogout()
    }
}

extension HomeViewModel {
    static var liveValue: HomeViewModel {
        HomeViewModel(offboardingUseCase: DependencyInjection.offboardingUseCase)
    }
}
