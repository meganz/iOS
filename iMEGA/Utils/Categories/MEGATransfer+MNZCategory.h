#import <Foundation/Foundation.h>
#import "MEGAChatMessage.h"

@interface MEGATransfer (MNZCategory)

#pragma mark - Thumbnails and previews

- (MEGAChatMessageType)transferChatMessageType;

#pragma mark - App data

- (void)mnz_parseChatAttachmentAppData;
- (NSString *)mnz_extractChatIDFromAppData;
- (NSString *)mnz_extractMessageIDFromAppData;
- (void)mnz_moveFileToDestinationIfVoiceClipData;
- (NSUInteger)mnz_orderByState;
- (void)mnz_setCoordinates:(NSString *)coordinates;

- (MEGANode *)node;

@end
