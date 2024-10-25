import Foundation

struct Description: Decodable {
    let paragraph1: String?
    let paragraph2: String?
    let paragraph3: String?
    let paragraph4: String?
    let paragraph5: String?
    let paragraph6: String?
    let paragraph7: String?
    let paragraph8: String?
    let paragraph9: String?
    let paragraph10: String?
    let paragraph11: String?
    let paragraph12: String?
    let paragraph13: String?
    let paragraph14: String?
    let paragraph15: String?
    let paragraph16: String?
    let paragraph17: String?
    let paragraph18: String?
    let paragraph19: String?
    let paragraph20: String?

    var formattedString: String {
        get throws {
            let paragraphs = [
                paragraph1, paragraph2, paragraph3, paragraph4, paragraph5,
                paragraph6, paragraph7, paragraph8, paragraph9, paragraph10,
                paragraph11, paragraph12, paragraph13, paragraph14, paragraph15,
                paragraph16, paragraph17, paragraph18, paragraph19, paragraph20
            ]

            let nonEmptyParagraphs = paragraphs.compactMap { $0 }
            if nonEmptyParagraphs.isEmpty {
                throw "App Description is empty (Transifex)"
            } else {
                return nonEmptyParagraphs.joined(separator: "\n\n")
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case paragraph1 = "string1"
        case paragraph2 = "string2"
        case paragraph3 = "string3"
        case paragraph4 = "string4"
        case paragraph5 = "string5"
        case paragraph6 = "string6"
        case paragraph7 = "string7"
        case paragraph8 = "string8"
        case paragraph9 = "string9"
        case paragraph10 = "string10"
        case paragraph11 = "string11"
        case paragraph12 = "string12"
        case paragraph13 = "string13"
        case paragraph14 = "string14"
        case paragraph15 = "string15"
        case paragraph16 = "string16"
        case paragraph17 = "string17"
        case paragraph18 = "string18"
        case paragraph19 = "string19"
        case paragraph20 = "string20"
    }
}
