import MEGAAssets
import MEGADesignToken
import MEGADomain

protocol UserAvatarHandling {
    /// Retrieves the avatar image for a given user handle.
    /// - Parameter userHandle: The Base64HandleEntity representing the user handle.
    /// - Returns: UIImage object representing the avatar image for an user
    /// - Note: Tries to get the avatar from cache or server, if the avatar is not cache and user doesn't have avatar
    /// this function creates (and caches) an avatar with the user's initials.
    func avatar(for userHandle: Base64HandleEntity) async -> UIImage
}

struct UserAvatarHandler: UserAvatarHandling {
    let userImageUseCase: any UserImageUseCaseProtocol
    let initials: String
    let avatarBackgroundColor: UIColor
    let size: CGSize
    let isRightToLeftLanguage: Bool
    
    init(
        userImageUseCase: some UserImageUseCaseProtocol,
        initials: String,
        avatarBackgroundColor: UIColor,
        size: CGSize = CGSize(width: 100, height: 100),
        isRightToLeftLanguage: Bool = false
    ) {
        self.userImageUseCase = userImageUseCase
        self.initials = initials
        self.avatarBackgroundColor = avatarBackgroundColor
        self.size = size
        self.isRightToLeftLanguage = isRightToLeftLanguage
    }
    
    func avatar(for userHandle: Base64HandleEntity) async -> UIImage {
        do {
            let avatarPath = try await userImageUseCase.fetchAvatar(base64Handle: userHandle, forceDownload: false)
            
            guard let image = UIImage(contentsOfFile: avatarPath) else {
                if let image = await drawImage() {
                    writeImage(image.jpegData(compressionQuality: 1.0), to: URL(fileURLWithPath: avatarPath))
                    return image
                }
                return MEGAAssets.UIImage.iconContacts
            }
            
            return image
        } catch {
            return MEGAAssets.UIImage.iconContacts
        }
    }
    
    // MARK: - Private
    
    @MainActor
    private func drawImage() -> UIImage? {
        UIImage.drawImage(
            forInitials: initials,
            size: size,
            backgroundColor: avatarBackgroundColor,
            textColor: TokenColors.Text.onColor,
            font: UIFont.systemFont(ofSize: min(size.width, size.height)/2.0),
            isRightToLeftLanguage: isRightToLeftLanguage)
    }
    
    private func writeImage(_ imageData: Data?, to destinationURL: URL?) {
        if let imageData,
           let destinationURL {
            do {
                try imageData.write(to: destinationURL, options: .atomic)
            } catch {
                MEGALogError("[Avatar] Error writing image data to \(destinationURL): \(error.localizedDescription)")
            }
        }
    }
}
