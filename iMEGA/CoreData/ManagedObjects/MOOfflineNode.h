/**
 * @file MOOfflineNode.h
 * @brief This entity deals with downloaded nodes information
 *
 * (c) 2013-2015 by Mega Limited, Auckland, New Zealand
 *
 * This file is part of the MEGA SDK - Client Access Engine.
 *
 * Applications using the MEGA API must present a valid application key
 * and comply with the the rules set forth in the Terms of Service.
 *
 * The MEGA SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * @copyright Simplified (2-clause) BSD License.
 *
 * You should have received a copy of the license along with this
 * program.
 */

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface MOOfflineNode : NSManagedObject

@property (nonatomic, retain) NSString * base64Handle;
@property (nonatomic, retain) NSString * localPath;
@property (nonatomic, retain) NSString * parentBase64Handle;
@property (nonatomic, retain) NSString * fingerprint;

@end
