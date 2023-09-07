import Foundation

struct Meta: Codable {
    var status: Int?
    var msg: String = ""
}

struct Pagination: Codable {
    var totalCount: Int?
    var count: Int?
    var offset: Int?
    
    private enum CodingKeys: String, CodingKey {
         case totalCount = "total_count"
         case count
         case offset
     }
}

struct ResponseModel<T: Decodable>: Decodable {
    
    // MARK: - Properties
    var error: ErrorModel {
        guard let meta = meta else {
            return ErrorModel("")
        }
        return ErrorModel(meta.msg)
    }
    var rawData: Data?
    var data: [T]?
    var meta: Meta?
    var pagination: Pagination?
    var json: String? {
        guard let rawData = rawData else { return nil }
        return String(data: rawData, encoding: String.Encoding.utf8)
    }
    var request: RequestModel?
    
    public init(from decoder: any Decoder) throws {
        let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
        
        data = try? keyedContainer.decode([T].self, forKey: CodingKeys.data)
        meta = try? keyedContainer.decode(Meta.self, forKey: CodingKeys.meta)
        pagination = try? keyedContainer.decode(Pagination.self, forKey: CodingKeys.pagination)

    }
}

// MARK: - Private Functions
extension ResponseModel {
    private enum CodingKeys: String, CodingKey {
        case data
        case pagination
        case meta
    }
}
