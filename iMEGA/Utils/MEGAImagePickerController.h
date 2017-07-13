
@interface MEGAImagePickerController : UIImagePickerController

- (id)init NS_UNAVAILABLE;

- (instancetype)initToUploadWithParentNode:(MEGANode *)parentNode sourceType:(UIImagePickerControllerSourceType)sourceType;

- (instancetype)initToChangeAvatarWithSourceType:(UIImagePickerControllerSourceType)sourceType;

@end
