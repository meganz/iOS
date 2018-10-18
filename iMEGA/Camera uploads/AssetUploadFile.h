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

@property (strong, nonatomic) NSString *fileName;

@property (strong, nonatomic) NSString *fingerprint;
@property (strong, nonatomic) NSString *originalFingerprint;

@property (strong, nonatomic) NSURL *fileURL;
@property (nonatomic, readonly) NSURL *encryptedURL;

@property (strong, nonatomic) NSString *uploadURLStringSuffix;
@property (strong, nonatomic) NSString *uploadURLString;
@property (nonatomic, readonly) NSURL *uploadURL;

@end

NS_ASSUME_NONNULL_END
