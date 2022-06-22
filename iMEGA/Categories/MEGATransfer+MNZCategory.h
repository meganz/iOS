
#import <Foundation/Foundation.h>
#import "MEGAChatMessage.h"

@interface MEGATransfer (MNZCategory)

#pragma mark - Thumbnails and previews

- (void)mnz_createThumbnailAndPreview;
- (void)mnz_renameOrRemoveThumbnailAndPreview;
- (MEGAChatMessageType)transferChatMessageType;

#pragma mark - App data

- (void)mnz_parseChatAttachmentAppData;
- (NSString *)mnz_extractChatIDFromAppData;
- (NSString *)mnz_extractMessageIDFromAppData;
- (void)mnz_moveFileToDestinationIfVoiceClipData;
- (NSUInteger)mnz_orderByState;

- (MEGANode *)node;

@end
