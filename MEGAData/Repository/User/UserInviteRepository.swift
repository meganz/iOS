import MEGADomain

struct UserInviteRepository: UserInviteRepositoryProtocol {
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func sendInvite(forEmail email: String,
                    completion: @escaping (Result<Void, InviteErrorEntity>) -> Void) {
        sdk.inviteContact(withEmail: email, message: "", action: .add, delegate: InviteRequestDelegate(completion: completion))
    }
}
