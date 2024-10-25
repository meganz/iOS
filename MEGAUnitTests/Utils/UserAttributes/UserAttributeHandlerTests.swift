@testable import MEGA
import MEGADomain
import Testing

@Suite("User Attribute Handler Tests - Using in-memory MockMEGAStore")
struct UserAttributeHandlerTests {
    static let defaultHandle: UInt64 = 12345
    static let defaultEmail = "test@example.com"
    static let defaultNewFirstName = "NewFirstName"
    static let defaultNewLastName = "NewLastName"
    static let defaultNewAlias = "NewAlias"
    static let user = MockMOUser(firstname: "John", lastname: "Doe", nickname: "Johnny", email: defaultEmail)
    
    // MARK: - Helper to create the System Under Test (SUT)
    @MainActor
    private static func makeSUT(
        existingUserForHandle: MockMOUser? = nil,
        existingUserForEmail: MockMOUser? = nil,
        currentContext: NSManagedObjectContext = makeInMemoryPersistentContainer().viewContext
    ) -> (handler: UserAttributeHandler, mockStore: MockUserAttributesMEGAStore) {
        let mockStore = MockUserAttributesMEGAStore(currentContext: currentContext)
        
        if let userByHandle = existingUserForHandle {
            mockStore.insertUser(withUserHandle: defaultHandle, firstname: userByHandle.firstname, lastname: userByHandle.lastname, nickname: userByHandle.nickname, email: userByHandle.email)
        }
        
        if let userByEmail = existingUserForEmail {
            mockStore.insertUser(withUserHandle: defaultHandle, firstname: userByEmail.firstname, lastname: userByEmail.lastname, nickname: userByEmail.nickname, email: userByEmail.email)
        }
        
        let handler = UserAttributeHandler(store: mockStore)
        return (handler, mockStore)
    }
    
    private static func makeInMemoryPersistentContainer() -> NSPersistentContainer {
        let description = NSPersistentStoreDescription()
        description.url = URL(fileURLWithPath: "/dev/null")
        let container = NSPersistentContainer(name: "MEGACD")
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }

    // MARK: - Handle-Based Tests
    @Suite("Handle-Based User Attribute Tests")
    struct HandleTests {
        
        @MainActor
        @Test("Updates first name when user exists by handle")
        func updatesFirstNameWhenUserExistsByHandle() {
            let (handler, mockStore) = makeSUT(existingUserForHandle: user)

            handler.handleUserAttribute(user: UserEntity(handle: defaultHandle), email: nil, attributeType: .firstName, newValue: defaultNewFirstName)
            let updatedUser = mockStore.fetchUser(withUserHandle: defaultHandle)
            
            #expect(updatedUser?.firstname == defaultNewFirstName, "Expected user's first name to be updated to \(defaultNewFirstName).")
        }

        @MainActor
        @Test("Inserts new user when user does not exist by handle")
        func insertsNewUserWhenUserDoesNotExistByHandle() {
            let (handler, mockStore) = makeSUT()

            handler.handleUserAttribute(user: UserEntity(handle: defaultHandle), email: nil, attributeType: .firstName, newValue: defaultNewFirstName)
            let insertedUser = mockStore.fetchUser(withUserHandle: defaultHandle)
            
            #expect(insertedUser?.firstname == defaultNewFirstName, "Expected new user with first name \(defaultNewFirstName) to be inserted.")
        }
    }

    // MARK: - Email-Based Tests
    @Suite("Email-Based User Attribute Tests")
    struct EmailTests {

        @MainActor
        @Test("Updates first name when user exists by email")
        func updatesFirstNameWhenUserExistsByEmail() {
            let (handler, mockStore) = makeSUT(existingUserForEmail: user)

            handler.handleUserAttribute(user: nil, email: defaultEmail, attributeType: .firstName, newValue: defaultNewFirstName)
            let updatedUser = mockStore.fetchUser(withEmail: defaultEmail)
            
            #expect(updatedUser?.firstname == defaultNewFirstName, "Expected user's first name to be updated to \(defaultNewFirstName).")
        }

        @MainActor
        @Test("Inserts new user when user does not exist by email")
        func insertsNewUserWhenUserDoesNotExistByEmail() {
            let (handler, mockStore) = makeSUT()
            
            handler.handleUserAttribute(user: nil, email: defaultEmail, attributeType: .firstName, newValue: defaultNewFirstName)
            let insertedUser = mockStore.fetchUser(withUserHandle: MEGASdk.handle(forBase64UserHandle: defaultEmail))
            
            #expect(insertedUser?.firstname == defaultNewFirstName, "Expected new user with first name \(defaultNewFirstName) to be inserted.")
        }

        @MainActor
        @Test("Updates last name when user exists by email")
        func updatesLastNameWhenUserExistsByEmail() {
            let (handler, mockStore) = makeSUT(existingUserForEmail: user)

            handler.handleUserAttribute(user: nil, email: defaultEmail, attributeType: .lastName, newValue: defaultNewLastName)
            let updatedUser = mockStore.fetchUser(withEmail: defaultEmail)
            
            #expect(updatedUser?.lastname == defaultNewLastName, "Expected user's last name to be updated to \(defaultNewLastName).")
        }
    }

    // MARK: - Alias-Based Tests
    @Suite("Alias-Based User Attribute Tests")
    struct AliasTests {

        @MainActor
        @Test("Updates alias when alias is different from the new value")
        func updatesAliasWhenAliasIsDifferent() {
            let (handler, mockStore) = makeSUT(existingUserForHandle: user)

            handler.handleUserAttribute(user: UserEntity(handle: defaultHandle), email: nil, attributeType: .alias, newValue: defaultNewAlias)
            let updatedUser = mockStore.fetchUser(withUserHandle: defaultHandle)
            
            #expect(updatedUser?.nickname == defaultNewAlias, "Expected user's nickname to be updated to \(defaultNewAlias).")
        }

        @MainActor
        @Test("Does not update alias when the new value is the same")
        func doesNotUpdateAliasWhenValueIsSame() {
            let (handler, mockStore) = makeSUT(existingUserForHandle: user)
            let newAlias = user.nickname ?? ""

            handler.handleUserAttribute(user: UserEntity(handle: defaultHandle), email: nil, attributeType: .alias, newValue: newAlias)
            let updatedUser = mockStore.fetchUser(withUserHandle: defaultHandle)
            
            #expect(updatedUser?.nickname == newAlias, "Expected alias to remain unchanged because it was the same.")
        }
    }
}
