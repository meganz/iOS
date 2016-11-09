#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MEGAChatErrorType) {
    MEGAChatErrorTypeOk      = 0,
    MEGAChatErrorTypeUnknown = -1,
    MEGAChatErrorTypeArgs    = -2,
    MEGAChatErrorTypeAccess  = -9,
    MEGAChatErrorTypeNoEnt   = -11,
    MegaChatErrorTypeExist   = -12
};

@interface MEGAChatError : NSObject

@property (readonly, nonatomic) MEGAChatErrorType type;

@property (readonly, nonatomic) NSString *name;

- (instancetype)clone;

@end
