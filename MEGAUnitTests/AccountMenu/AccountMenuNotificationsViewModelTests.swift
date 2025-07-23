@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing

@MainActor
struct AccountMenuNotificationsViewModelTests {
    struct TestCaseInputSource: OptionSet {
        let rawValue: Int

        static let userAlert = TestCaseInputSource(rawValue: 1)
        static let contactRequest = TestCaseInputSource(rawValue: 2)
    }

    @Suite("Testing output emissions from input streams")
    @MainActor
    struct NotificationSignalTest {
        @Test("Each time we receive ContactRequest or UserAlert update, one output values should be emitted",
              arguments: [[TestCaseInputSource.userAlert], [.contactRequest], [.userAlert, .contactRequest]],
              [0, 1, 10, 99]
        )
        func outputEmissionsFromContactRequests(inputSources: [TestCaseInputSource], inputCount: Int) async {
            let contactRequestStream = inputSources.contains(.contactRequest) ? makeContactRequestInputStream(size: inputCount) : makeContactRequestInputStream(size: 0)
            let userAlertStream = inputSources.contains(.userAlert) ? makeUserAlertInputStream(size: inputCount) : makeUserAlertInputStream(size: 0)
            let accountUseCase = createMockAccountUseCase(
                contactRequestStream: contactRequestStream,
                userAlertStream: userAlertStream
            )

            let sut = makeSut(accountUseCase: accountUseCase)
            var outputCount = 0
            for await _ in sut.notificationBadgeValue {
                outputCount += 1
            }

            #expect(outputCount == inputSources.count * inputCount)
        }
    }

    @Suite("Test notifications input from AccountUseCase")
    @MainActor
    struct TestInputFromAccountUseCase {
        @Test("Show notifications badge from ContactRequest update",
              arguments: [[TestCaseInputSource.userAlert], [.contactRequest], [.userAlert, .contactRequest]],
            [0, 1]
        )
        func showNotificationBadge(inputSources: [TestCaseInputSource], updatesCount: Int) async {
            let userAlertUpdatesCount = inputSources.contains(.userAlert) ? updatesCount : 0
            let contactRequestUpdatesCount = inputSources.contains(.contactRequest) ? updatesCount : 0
            let accountUseCase = createMockAccountUseCase(
                incomingContactsRequestsCount: contactRequestUpdatesCount,
                relevantUserAlertsCount: UInt(userAlertUpdatesCount),
                contactRequestStream: makeContactRequestInputStream(size: 1),
                userAlertStream: makeUserAlertInputStream(size: 1)
            )

            let sut = makeSut(accountUseCase: accountUseCase)

            for await value in sut.notificationBadgeValue {
                let expected: String? = userAlertUpdatesCount + contactRequestUpdatesCount > 0 ? "" : nil
                #expect(value == expected)
            }
        }
    }

    private static func makeSut(
        accountUseCase: MockAccountUseCase = MockAccountUseCase(),
        sharedItemsUseCase: MockShareUseCase = MockShareUseCase(),
        notificationsUseCase: MockNotificationUseCase = MockNotificationUseCase(),
        contactsUseCase: MockContactsUseCase = MockContactsUseCase()
    ) -> AccountMenuNotificationsViewModel {

        AccountMenuNotificationsViewModel(
            accountUseCase: accountUseCase,
            sharedItemsUseCase: sharedItemsUseCase,
            notificationsUseCase: notificationsUseCase,
            contactsUseCase: contactsUseCase
        )
    }

    private static func createMockAccountUseCase(
        incomingContactsRequestsCount: Int = 0,
        relevantUserAlertsCount: UInt = 0,
        contactRequestStream: AnyAsyncSequence<[ContactRequestEntity]> = EmptyAsyncSequence<[ContactRequestEntity]>().eraseToAnyAsyncSequence(),
        userAlertStream: AnyAsyncSequence<[UserAlertEntity]> = EmptyAsyncSequence<[UserAlertEntity]>().eraseToAnyAsyncSequence(),
    ) -> MockAccountUseCase {
        MockAccountUseCase(
            incomingContactsRequestsCount: incomingContactsRequestsCount,
            relevantUnseenUserAlertsCount: relevantUserAlertsCount,
            onContactRequestsUpdates: contactRequestStream.eraseToAnyAsyncSequence(),
            onUserAlertsUpdates: userAlertStream.eraseToAnyAsyncSequence()
        )
    }

    private static func makeContactRequestInputStream(size: Int = Int.random(in: 0...10000)) -> AnyAsyncSequence<[ContactRequestEntity]> {
        [[ContactRequestEntity]].init(repeating: [.random], count: size)
            .async.eraseToAnyAsyncSequence()
    }

    private static func makeUserAlertInputStream(size: Int) -> AnyAsyncSequence<[UserAlertEntity]> {
        [[UserAlertEntity]].init(repeating: [.random], count: size)
            .async.eraseToAnyAsyncSequence()
    }
}
