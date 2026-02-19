@preconcurrency import Combine

import MEGADomain
import MEGASwift
import SwiftUI

protocol AccountDetailsAvatarUseCaseProtocol: Sendable {
    /// Emits the current user's avatar image whenever it changes.
    /// Falls back to an initial-letter placeholder when no avatar file is available.
    var avatar: AnyAsyncSequence<Image> { get }
}

package final class AccountDetailsAvatarUseCase: AccountDetailsAvatarUseCaseProtocol, @unchecked Sendable {
    private static let placeHolderImage = Image(systemName: "person.crop.circle.fill")
    private let accountUseCase: any AccountUseCaseProtocol
    private let userNameUseCase: any AccountDetailsUserNameUseCaseProtocol

    private let avatarSubject: CurrentValueSubject<Image, Never>
    private let monitorTask: Task<Void, Never>

    package var avatar: AnyAsyncSequence<Image> {
        avatarSubject
            .values
            .eraseToAnyAsyncSequence()
    }

    package init(
        accountUseCase: some AccountUseCaseProtocol,
        userNameUseCase: some AccountDetailsUserNameUseCaseProtocol,
        avatarFetcher: @escaping @Sendable () async -> Image?
    ) {
        self.accountUseCase = accountUseCase
        self.userNameUseCase = userNameUseCase

        let subject = CurrentValueSubject<Image, Never>(Self.placeHolderImage)
        self.avatarSubject = subject

        monitorTask = Task { [userNameUseCase] in
            // Observe user name change, in case user doesn't have a profile pic we'll display the
            // First initial letter of user's name
            async let nameTracking: () = {
                for await _ in userNameUseCase.names {
                    guard !Task.isCancelled else { break }
                    if let fetchedAvatar = await avatarFetcher() {
                        subject.send(fetchedAvatar)
                    }
                }
            }()

            async let avatarTracking: () = {
                // If there's an available avatar, we update the UI immediately
                if let fetchedAvatar = await avatarFetcher() {
                    subject.send(fetchedAvatar)
                }

                // React to SDK avatar-change notifications.
                for await result in accountUseCase.onAccountRequestFinish {
                    guard !Task.isCancelled else { break }
                    guard Self.shouldUpdateAvatar(result), let fetchedAvatar = await avatarFetcher() else { continue }
                    subject.send(fetchedAvatar)
                }
            }()

            _ = await (nameTracking, avatarTracking)
        }
    }

    deinit {
        monitorTask.cancel()
    }

    private static func shouldUpdateAvatar(
        _ result: Result<AccountRequestEntity, any Error>
    ) -> Bool {
        guard case .success(let request) = result,
              request.type == .getAttrUser,
              request.file != nil
        else { return false }
        return true
    }
}
