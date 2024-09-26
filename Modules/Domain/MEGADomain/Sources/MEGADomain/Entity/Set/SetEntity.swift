import Foundation

public struct SetEntity: Hashable, Sendable {
    public let setIdentifier: SetIdentifier
    public let userId: HandleEntity
    public let coverId: HandleEntity
    public let creationTime: Date
    public let modificationTime: Date
    public let setType: SetTypeEntity
    public let name: String
    public let isExported: Bool
    public let changeTypes: SetChangeTypeEntity
    
    public init(setIdentifier: SetIdentifier, userId: HandleEntity, coverId: HandleEntity, creationTime: Date,
                modificationTime: Date, setType: SetTypeEntity, name: String, isExported: Bool, changeTypes: SetChangeTypeEntity) {
        self.setIdentifier = setIdentifier
        self.userId = userId
        self.coverId = coverId
        self.creationTime = creationTime
        self.modificationTime = modificationTime
        self.setType = setType
        self.name = name
        self.isExported = isExported
        self.changeTypes = changeTypes
    }
    
    public init(
        handle: SetHandleEntity,
        userId: HandleEntity,
        coverId: HandleEntity,
        creationTime: Date,
        modificationTime: Date,
        setType: SetTypeEntity,
        name: String,
        isExported: Bool,
        changeTypes: SetChangeTypeEntity
    ) {
        self.init(
            setIdentifier: SetIdentifier(handle: handle),
            userId: userId,
            coverId: coverId,
            creationTime: creationTime,
            modificationTime: modificationTime,
            setType: setType,
            name: name,
            isExported: isExported,
            changeTypes: changeTypes
        )
    }
}

extension SetEntity: Identifiable {
    public var id: SetIdentifier { setIdentifier }
}

extension SetEntity {
    public var handle: SetHandleEntity { setIdentifier.handle }
}
