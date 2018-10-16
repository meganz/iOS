//
//  AssetUploadFile.h
//  MEGA
//
//  Created by Simon Wang on 16/10/18.
//  Copyright © 2018 MEGA. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AssetUploadFile : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSURL *fileURL;
@property (nonatomic, readonly) NSURL *encryptedURL;
@property (strong, nonatomic, nullable) NSString *uploadURLStringSuffix;
@property (strong, nonatomic, nullable) NSString *uploadURLString;
@property (nonatomic, readonly, nullable) NSURL *uploadURL;

- (instancetype)initWithName:(NSString *)name URL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
