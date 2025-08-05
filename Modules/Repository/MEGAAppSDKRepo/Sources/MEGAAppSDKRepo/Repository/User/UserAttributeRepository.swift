import MEGADomain
import MEGASdk
import MEGASwift

public struct UserAttributeRepository: UserAttributeRepositoryProtocol {
    public static var newRepo: UserAttributeRepository {
        UserAttributeRepository(sdk: MEGASdk.sharedSdk)
    }

    private let sdk: MEGASdk
    private let jsonDecoder = JSONDecoder()

    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }

    public func updateUserAttribute(_ attribute: UserAttributeEntity, value: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            guard Task.isCancelled == false else {
                continuation.resume(throwing: CancellationError())
                return
            }

            sdk.setUserAttributeType(attribute.toMEGAUserAttribute(), value: value, delegate: RequestDelegate { result in
                guard Task.isCancelled == false else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                continuation.resume(with: result.map {_ in })
            })
        }
    }
    
    public func mergeUserAttribute<T: Encodable>(_ attribute: UserAttributeEntity, key: String, object: T) async throws {
        let supportedModelDictionary = try object.convertToDictionary()
        let currentAppsPreference = try? await userAttribute(for: attribute)
        
        let contentToSave: [String: Any] = if let existingEncodedString = currentAppsPreference?[key],
            existingEncodedString.isNotEmpty,
            let jsonData = existingEncodedString.base64DecodedData,
            let allPlatformDictionary = try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [String: Any] {
                // Merge results from existing preference with new preferences. 
                // So as to not overwrite other platform/unsupported properties
                allPlatformDictionary.merging(supportedModelDictionary, uniquingKeysWith: { $1 })
            } else {
                supportedModelDictionary
            }
        
        guard let contentToSaveJson = try? JSONSerialization.data(withJSONObject: contentToSave) else { throw JSONCodingErrorEntity.encoding }
        
        try await updateUserAttribute(attribute, key: key, value: String(decoding: contentToSaveJson, as: UTF8.self))
    }
    
    public func updateUserAttribute(_ attribute: UserAttributeEntity, key: String, value: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            guard Task.isCancelled == false else {
                continuation.resume(throwing: CancellationError())
                return
            }

            sdk.setUserAttributeType(attribute.toMEGAUserAttribute(), key: key, value: value, delegate: RequestDelegate { result in
                guard Task.isCancelled == false else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                continuation.resume(with: result.map { _ in })
            })
        }
    }

    public func userAttribute(for attribute: UserAttributeEntity) async throws -> [String: String]? {
        try await withAsyncThrowingValue(in: { completion in
            sdk.getUserAttributeType(attribute.toMEGAUserAttribute(), delegate: RequestDelegate { result in
                switch result {
                case .success(let request):
                    completion(.success(request.megaStringDictionary))
                case .failure(let error):
                    let mappedError: any Error = switch error.type {
                    case .apiERange:
                        UserAttributeErrorEntity.attributeNotFound
                    default:
                        GenericErrorEntity()
                    }
                    completion(.failure(mappedError))
                }
            })
        })
    }
    
    public func userAttribute<T: Decodable>(for attribute: UserAttributeEntity, key: String) async throws -> T {
        let appsPreference = try await userAttribute(for: attribute)
        guard
            let encodedString = appsPreference?[key],
            encodedString.isNotEmpty,
            let jsonData = encodedString.base64DecodedData,
            let decodedObject = try? jsonDecoder.decode(T.self, from: jsonData)
        else {
            throw JSONCodingErrorEntity.decoding
        }
        return decodedObject
    }
    
    public func getUserAttribute(for attribute: UserAttributeEntity) async throws -> String? {
        try await withAsyncThrowingValue(in: { completion in
            sdk.getUserAttributeType(attribute.toMEGAUserAttribute(), delegate: RequestDelegate { result in
                switch result {
                case .success(let request):
                    completion(.success(request.text))
                case .failure(let error):
                    let mappedError: any Error = switch error.type {
                    case .apiERange:
                        UserAttributeErrorEntity.attributeNotFound
                    default:
                        GenericErrorEntity()
                    }
                    completion(.failure(mappedError))
                }
            })
        })
    }
}
