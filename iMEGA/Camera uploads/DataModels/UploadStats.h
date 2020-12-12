
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UploadStats : NSObject

@property (nonatomic) NSUInteger totalFilesCount;
@property (nonatomic) NSUInteger finishedFilesCount;
@property (readonly) NSUInteger pendingFilesCount;
@property (nonatomic) float progress;

- (instancetype)initWithFinishedCount:(NSUInteger)finishedCount totalCount:(NSUInteger)totalCount;

@end

NS_ASSUME_NONNULL_END
