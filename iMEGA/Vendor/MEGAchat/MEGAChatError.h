#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MEGAChatErrorType) {
    MEGAChatErrorTypeOk = 0,
    MEGAChatErrorTypeUnknown = -1,
    MEGAChatErrorTypeArgs = -2,
    MEGAChatErrorTypeAccess = -3,
    MEGAChatErrorTypeNoEnt = -4
};

@interface MEGAChatError : NSObject

@property (readonly, nonatomic) MEGAChatErrorType type;

@property (readonly, nonatomic) NSString *name;

- (instancetype)clone;

@end
