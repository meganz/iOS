@testable import MEGA

extension ContactRequest {
    
    static var random: Self {
        ContactRequest.init(handle: .random(in: 1...1000),
                            sourceEmail: "random",
                            sourceMessage: nil,
                            targetEmail: nil,
                            creationTime: Date(),
                            modificationTime: Date(),
                            isOutgoing: .random(),
                            status: .accepted)
    }
}
