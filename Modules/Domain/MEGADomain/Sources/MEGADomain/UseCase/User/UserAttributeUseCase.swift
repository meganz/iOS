import Foundation

public protocol UserAttributeUseCaseProtocol {
    func updateUserAttribute(_ attribute: UserAttributeEntity, value: String) async throws
    func updateUserAttribute(_ attribute: UserAttributeEntity, key: String, value: String) async throws
    func userAttribute(for attribute: UserAttributeEntity) async throws -> [String: String]?
    func retrieveContentConsumptionAttribute() async throws -> ContentConsumptionEntity?
    func saveTimelineFilter(key: String, timeline: ContentConsumptionTimeline) async throws
}

public struct UserAttributeUseCase<T: UserAttributeRepositoryProtocol>: UserAttributeUseCaseProtocol {
    private let repo: T
    
    public init(repo: T) {
        self.repo = repo
    }
    
    public func updateUserAttribute(_ attribute: UserAttributeEntity, value: String) async throws {
        try await repo.updateUserAttribute(attribute, value: value)
    }
    
    public func updateUserAttribute(_ attribute: UserAttributeEntity, key: String, value: String) async throws {
        try await repo.updateUserAttribute(attribute, key: key, value: value)
    }
    
    public func userAttribute(for attribute: UserAttributeEntity) async throws -> [String: String]? {
        try await repo.userAttribute(for: attribute)
    }
    
    public func retrieveContentConsumptionAttribute() async throws -> ContentConsumptionEntity? {
        guard let jsonData = try await retrieveContentConsumptionJSONData() else { return nil }
        return try JSONDecoder().decode(ContentConsumptionEntity.self, from: jsonData)
    }
    
    public func saveTimelineFilter(
        key: String,
        timeline: ContentConsumptionTimeline
    ) async throws {
        let resultJson = try await jsonStringForPreference(timeline: timeline)
        
        guard resultJson.isNotEmpty else { throw JSONCodingErrorEntity.encoding }
        try await updateUserAttribute(.contentConsumptionPreferences, key: key, value: resultJson)
    }
    
    // MARK: - Private
    private func retrieveContentConsumptionJSONData() async throws -> Data? {
        let appsPreference = try await userAttribute(for: .contentConsumptionPreferences)
        
        guard let encodedString = appsPreference?[ContentConsumptionKeysEntity.key] as? String,
              encodedString.isNotEmpty,
              let jsonData = encodedString.base64DecodedData else { return nil }
        
        return jsonData
    }
    
    private func jsonStringForPreference(timeline: ContentConsumptionTimeline) async throws -> String {
        let allPlatformCCJsonData = try? await retrieveContentConsumptionJSONData()
        
        if let allPlatformCCJsonData, let existingJson = try? jsonStringForExistingPreference(timeline: timeline, jsonData: allPlatformCCJsonData) {
            return existingJson
        }
        else {
            return try jsonStringForNonExistingPreference(timeline, jsonData: allPlatformCCJsonData)
        }
    }
    
    private func jsonStringForExistingPreference(timeline: ContentConsumptionTimeline, jsonData: Data) throws -> String {
        guard var contentConsumption = try? JSONDecoder().decode(ContentConsumptionEntity.self, from: jsonData) else { throw JSONCodingErrorEntity.encoding }
        
        contentConsumption = contentConsumption.update(timeline: timeline)
        
        guard var dictionary = try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [String: Any],
              let timeline = try? contentConsumption.ios.convertToDictionary()
        else { throw JSONCodingErrorEntity.encoding }
        dictionary[ContentConsumptionKeysEntity.ios] = timeline
        
        guard let dictionaryJson = try? JSONSerialization.data(withJSONObject: dictionary) else { throw JSONCodingErrorEntity.encoding }
        return String(decoding: dictionaryJson, as: UTF8.self)
    }
    
    private func jsonStringForNonExistingPreference(_ timeline: ContentConsumptionTimeline, jsonData: Data?) throws -> String {
        let contentConsumption = ContentConsumptionEntity(ios: ContentConsumptionIos(timeline: timeline))
        
        guard let contentConsumptionIosData = try? JSONEncoder().encode(contentConsumption) else { throw JSONCodingErrorEntity.encoding }
        
        let iosJsonString = String(decoding: contentConsumptionIosData, as: UTF8.self)
        
        if let otherPlatformPreferenceJsonData = jsonData {
            let result = String(decoding: otherPlatformPreferenceJsonData, as: UTF8.self).dropLast() + "," + iosJsonString.dropFirst()
            return String(result)
        } else {
            return iosJsonString
        }
    }
}
