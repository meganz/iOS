import Foundation

struct GiphyResponseModel: Decodable {
   
    var title: String
    var url: String = ""
    var height: String = ""
    var width: String = ""
    var webp: String = ""
    var mp4: String = ""
    var webp_size: String = ""
    var mp4_size: String = ""
    
    enum CodingKeys: String, CodingKey {
        case title
        case images
        case fixed_height
        case url
        case height
        case width
        case webp
        case mp4
        case webp_size
        case mp4_size
    }
    
    init(from decoder: Decoder) throws {
        let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
        title = (try? keyedContainer.decode(String.self, forKey: CodingKeys.title)) ?? ""
        let images = try? keyedContainer.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.images)
        let fixedHeight = try? images?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.fixed_height)
        url = (try? fixedHeight?.decode(String.self, forKey: CodingKeys.url)) ?? ""
        webp = (try? fixedHeight?.decode(String.self, forKey: CodingKeys.webp)) ?? ""
        height = (try? fixedHeight?.decode(String.self, forKey: CodingKeys.height)) ?? ""
        width = (try? fixedHeight?.decode(String.self, forKey: CodingKeys.width)) ?? ""
        mp4 = (try? fixedHeight?.decode(String.self, forKey: CodingKeys.mp4)) ?? ""
        webp_size = (try? fixedHeight?.decode(String.self, forKey: CodingKeys.webp_size)) ?? ""
        mp4_size = (try? fixedHeight?.decode(String.self, forKey: CodingKeys.mp4_size)) ?? ""
    }
    
}
