
#import <Foundation/Foundation.h>

@class PHAsset;

typedef NS_ENUM (NSInteger, MEGAChatStatus);

@interface NSString (MNZCategory)

@property (nonatomic, readonly, getter=mnz_isImageUTI) BOOL mnz_imageUTI;
@property (nonatomic, readonly, getter=mnz_isAudiovisualContentUTI) BOOL mnz_audiovisualContentUTI;

@property (nonatomic, readonly, getter=mnz_isImagePathExtension) BOOL mnz_imagePathExtension;
@property (nonatomic, readonly, getter=mnz_isVideoPathExtension) BOOL mnz_videoPathExtension;
@property (nonatomic, readonly, getter=mnz_isMultimediaPathExtension) BOOL mnz_multimediaPathExtension;

#pragma mark - appData

- (NSString *)mnz_appDataToSaveCameraUploadsCount:(NSUInteger)operationCount;
- (NSString *)mnz_appDataToSaveInPhotosApp;
- (NSString *)mnz_appDataToAttachToChatID:(uint64_t)chatId;
- (NSString *)mnz_appDataToSaveCoordinates:(NSString *)coordinates;

#pragma mark - Utils

+ (NSString *)mnz_stringWithoutUnitOfComponents:(NSArray *)componentsSeparatedByStringArray;
+ (NSString *)mnz_stringWithoutCountOfComponents:(NSArray *)componentsSeparatedByStringArray;

- (NSString *)mnz_stringBetweenString:(NSString*)start andString:(NSString*)end;
+ (NSString *)mnz_stringByFiles:(NSInteger)files andFolders:(NSInteger)folders;
+ (NSString *)mnz_stringByMissedAudioCalls:(NSInteger)missedAudioCalls andMissedVideoCalls:(NSInteger)missedVideoCalls;

+ (NSString *)chatStatusString:(MEGAChatStatus)onlineStatus;

- (BOOL)mnz_isValidEmail;

- (BOOL)mnz_isEmpty;

- (NSString *)mnz_removeWebclientFormatters;

+ (NSString *)mnz_stringFromTimeInterval:(NSTimeInterval)interval;

- (NSString*)SHA256;

- (BOOL)mnz_containsEmoji;
- (BOOL)mnz_isPureEmojiString;
- (NSInteger)mnz_emojiCount;

- (NSString *)mnz_coordinatesOfPhotoOrVideo;

@end
