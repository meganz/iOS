
#import <Foundation/Foundation.h>

@interface MEGATransfer (MNZCategory)

#pragma mark - Thumbnails and previews

- (void)mnz_createThumbnailAndPreview;
- (void)mnz_renameOrRemoveThumbnailAndPreview;

#pragma mark - App data

- (void)mnz_parseSavePhotosAndSetCoordinatesAppData;
- (void)mnz_parseChatAttachmentAppData;
- (void)mnz_saveInPhotosApp;
- (void)mnz_setNodeCoordinates;
- (NSString *)mnz_extractChatIDFromAppData;
- (void)mnz_moveFileToDestinationIfVoiceClipData;
- (NSUInteger)mnz_orderByState;

@end
