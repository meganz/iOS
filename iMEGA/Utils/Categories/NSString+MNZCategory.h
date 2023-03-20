
@import UIKit;

typedef NS_ENUM (NSInteger, MEGAChatStatus);
typedef NS_ENUM(NSInteger, MEGAChatMessageEndCallReason);

NS_ASSUME_NONNULL_BEGIN

@interface NSString (MNZCategory)

@property (nonatomic, readonly, getter=mnz_isImagePathExtension) BOOL mnz_imagePathExtension;
@property (nonatomic, readonly, getter=mnz_isVideoPathExtension) BOOL mnz_videoPathExtension;
@property (nonatomic, readonly, getter=mnz_isVisualMediaPathExtension) BOOL mnz_visualMediaPathExtension;
@property (nonatomic, readonly, getter=mnz_isMultimediaPathExtension) BOOL mnz_multimediaPathExtension;
@property (nonatomic, readonly, getter=mnz_isAudioPlayListPathExtension) BOOL mnz_audioPlayListPathExtension;
@property (nonatomic, readonly, getter=mnz_isEditableTextFilePathExtension) BOOL mnz_isEditableTextFilePathExtension;

#pragma mark - appData

- (NSString *)mnz_appDataToSaveInPhotosApp;
- (NSString *)mnz_appDataToAttachToChatID:(uint64_t)chatId asVoiceClip:(BOOL)asVoiceClip;
- (NSString *)mnz_appDataToDownloadAttachToMessageID:(uint64_t)messageID;
- (NSString *)mnz_appDataToSaveCoordinates:(NSString *)coordinates;
- (NSString *)mnz_appDataToLocalIdentifier:(NSString *)localIdentifier;
- (NSString *)mnz_appDataToPath:(NSString *)path;
- (NSString *)mnz_appDataToExportFile;

#pragma mark - Utils

+ (NSString *)mnz_stringWithoutUnitOfComponents:(NSArray *)componentsSeparatedByStringArray;
+ (NSString *)mnz_stringWithoutCountOfComponents:(NSArray *)componentsSeparatedByStringArray;
+ (NSString *)mnz_formatStringFromByteCountFormatter:(NSString *)stringFromByteCount;
+ (BOOL)mnz_isByteCountEmpty:(NSString *)stringFromByteCount;

- (NSString * _Nullable)mnz_stringBetweenString:(NSString*)start andString:(NSString*)end;
+ (NSString *)mnz_stringByFiles:(NSInteger)files andFolders:(NSInteger)folders;
+ (NSString *)localizedSortOrderType:(MEGASortOrderType)sortOrderType;

+ (NSString * _Nullable)chatStatusString:(MEGAChatStatus)onlineStatus;
+ (NSString *)mnz_stringByEndCallReason:(MEGAChatMessageEndCallReason)endCallReason userHandle:(uint64_t)userHandle duration:(NSNumber * _Nullable)duration isGroup:(BOOL)isGroup;
+ (NSString *)mnz_hoursDaysWeeksMonthsOrYearFrom:(NSUInteger)seconds;

- (BOOL)mnz_isValidEmail;

- (BOOL)mnz_isEmpty;
/// @return A new string by trimming leading and trailing whitespace and newline characters
- (NSString *)mnz_removeWhitespacesAndNewlinesFromBothEnds;

- (BOOL)mnz_containsInvalidChars;

- (NSString *)mnz_removeWebclientFormatters;

+ (NSString *)mnz_stringFromTimeInterval:(NSTimeInterval)interval;
+ (NSString *)mnz_stringFromCallDuration:(NSInteger)duration;

- (NSString *)SHA256;

- (BOOL)mnz_isDecimalNumber;

- (BOOL)mnz_containsEmoji;
- (BOOL)mnz_isPureEmojiString;
- (NSInteger)mnz_emojiCount;
- (NSString *)mnz_initialForAvatar;

- (NSString * _Nullable)mnz_coordinatesOfPhotoOrVideo;
+ (NSString *)mnz_base64FromBase64URLEncoding:(NSString *)base64URLEncondingString;

- (NSString *)mnz_relativeLocalPath;

+ (NSString *)mnz_lastGreenStringFromMinutes:(NSInteger)minutes;

/**
 * @brief Convert decimal degrees coordinate into degrees, minutes, seconds and direction
 *
 * @param latitude The latitude coordinate in its decimal degree notation
 * @param longitude The longitude coordinate in its decimal degree notation
 *
 * @return The coordinate in degrees, minutes, seconds and direction
 */
+ (NSString *)mnz_convertCoordinatesLatitude:(float)latitude longitude:(float)longitude;

+ (NSString *)mnz_addedByInRecentActionBucket:(MEGARecentActionBucket *)recentActionBucket;

#pragma mark - File names and extensions

- (NSString *)mnz_fileNameWithLowercaseExtension;
- (nullable NSString *)mnz_lastExtensionInLowercase;
- (NSString *)mnz_sequentialFileNameInParentNode:(MEGANode *)parentNode;
- (NSString *)mnz_fileNameWithoutExtension;

/**
 Remove invalid file characters from a string. So we can use the new string safely as a folder name or file name
 
 For now, we remove characters ":", "/", "\\"

 @return a new string without invalid characters
 */
- (NSString *)mnz_stringByRemovingInvalidFileCharacters;

/**
 Returns the size of the string if it were rendered with the specified constraints.
 
 @param font          The font to use for computing the string size.
 
 @param size          The maximum acceptable size for the string. This value is
 used to calculate where line breaks and wrapping would occur.
 
 @param lineBreakMode The line break options for computing the size of the string.
 For a list of possible values, see NSLineBreakMode.
 
 @return              The width and height of the resulting string's bounding box.
 These values may be rounded up to the nearest whole number.
 */
- (CGSize)sizeForFont:(UIFont *)font size:(CGSize)size mode:(NSLineBreakMode)lineBreakMode;

@end

NS_ASSUME_NONNULL_END
