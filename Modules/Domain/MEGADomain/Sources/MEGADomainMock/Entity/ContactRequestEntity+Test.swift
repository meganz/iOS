import Foundation
import MEGADomain

extension ContactRequestEntity {
    
    public static var random: Self {
        ContactRequestEntity(handle: .random(in: 1...1000),
                            sourceEmail: "random",
                            sourceMessage: nil,
                            targetEmail: nil,
                            creationTime: Date(),
                            modificationTime: Date(),
                            isOutgoing: .random(),
                            status: .accepted)
    }
}
