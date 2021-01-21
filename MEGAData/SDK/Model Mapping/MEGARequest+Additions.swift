
extension MEGARequest {
    var psaEntity: PSAEntity {
        return PSAEntity(
            identifier: number.intValue,
            title: name,
            description: text,
            imageURL: file,
            positiveText: password,
            positiveLink: link,
            URLString: email
        )
    }
}
