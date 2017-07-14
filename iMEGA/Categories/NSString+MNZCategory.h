
#import <Foundation/Foundation.h>

typedef NS_ENUM (NSInteger, MEGAChatStatus);

@interface NSString (MNZCategory)

@property (nonatomic, readonly, getter=mnz_isImageUTI) BOOL mnz_imageUTI;
@property (nonatomic, readonly, getter=mnz_isAudiovisualContentUTI) BOOL mnz_audiovisualContentUTI;

@property (nonatomic, readonly, getter=mnz_isImagePathExtension) BOOL mnz_imagePathExtension;
@property (nonatomic, readonly, getter=mnz_isVideoPathExtension) BOOL mnz_videoPathExtension;
@property (nonatomic, readonly, getter=mnz_isMultimediaPathExtension) BOOL mnz_multimediaPathExtension;

+ (NSString *)mnz_stringWithoutUnitOfComponents:(NSArray *)componentsSeparatedByStringArray;
+ (NSString *)mnz_stringWithoutCountOfComponents:(NSArray *)componentsSeparatedByStringArray;

- (NSString*)mnz_stringBetweenString:(NSString*)start andString:(NSString*)end;
+ (NSString*)mnz_stringByFiles:(NSInteger)files andFolders:(NSInteger)folders;

+ (NSString *)chatStatusString:(MEGAChatStatus)onlineStatus;
- (BOOL)mnz_isValidEmail;

@end
