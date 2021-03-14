
#import <Foundation/Foundation.h>
#import "MEGAChatMessage.h"

@interface MEGATransfer (MNZCategory)

#pragma mark - Thumbnails and previews

- (void)mnz_createThumbnailAndPreview;
- (void)mnz_renameOrRemoveThumbnailAndPreview;
- (MEGAChatMessageType)transferChatMessageType;

#pragma mark - App data

- (void)mnz_parseSavePhotosAndSetCoordinatesAppData;
- (void)mnz_parseChatAttachmentAppData;
- (void)mnz_saveInPhotosApp;
- (void)mnz_setNodeCoordinates;
- (NSString *)mnz_extractChatIDFromAppData;
- (void)mnz_moveFileToDestinationIfVoiceClipData;
- (NSUInteger)mnz_orderByState;

- (MEGANode *)node;

@end
