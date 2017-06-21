
#import "UIImageView+MNZCategory.h"

#import "Helper.h"
#import "MEGASdkManager.h"
#import "MEGAStore.h"
#import "UIImage+GKContact.h"

@implementation UIImageView (MNZCategory)

- (void)mnz_setImageForUserHandle:(uint64_t)userHandle {
    self.layer.cornerRadius = self.frame.size.width / 2;
    self.layer.masksToBounds = YES;
    
    NSString *base64Handle = [MEGASdk base64HandleForUserHandle:userHandle];
    NSString *avatarFilePath = [[Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"] stringByAppendingPathComponent:base64Handle];
    if ([[NSFileManager defaultManager] fileExistsAtPath:avatarFilePath]) {
        self.image = [UIImage imageWithContentsOfFile:avatarFilePath];
    } else {
        NSString *colorString = [MEGASdk avatarColorForBase64UserHandle:base64Handle];
        MOUser *user = [[MEGAStore shareInstance] fetchUserWithUserHandle:userHandle];
        NSString *initialsForAvatar = nil;
        if (user) {
            if (user.email.length) {
                initialsForAvatar = user.email.uppercaseString;
            } else {
                initialsForAvatar = [NSString stringWithFormat:@"%@ %@", user.firstname, user.lastname];
            }
        } else {
            initialsForAvatar = @"?";
        }
        UIImage *avatar = [UIImage imageForName:initialsForAvatar size:self.frame.size backgroundColor:[UIColor colorFromHexString:colorString] textColor:[UIColor whiteColor] font:[UIFont mnz_SFUIRegularWithSize:(self.frame.size.width/2.0f)]];
        self.image = avatar;
        
        [[MEGASdkManager sharedMEGASdk] getAvatarUserWithEmailOrHandle:base64Handle destinationFilePath:avatarFilePath delegate:self];
    }
}

- (void)mnz_setImageForExtension:(NSString *)extension {
    NSDictionary *fileTypesDictionary = @{@"3ds":@"3d",
                                @"3dm":@"3d",
                                @"3fr":@"raw",
                                @"3g2":@"video",
                                @"3gp":@"video",
                                @"7z":@"compressed",
                                @"aac":@"audio",
                                @"ac3":@"audio",
                                @"accdb":@"database",
                                @"aep":@"after_effects",
                                @"aet":@"after_effects",
                                @"ai":@"illustrator",
                                @"aif":@"audio",
                                @"aiff":@"audio",
                                @"ait":@"illustrator",
                                @"ans":@"text",
                                @"apk":@"executable",
                                @"app":@"executable",
                                @"arw":@"raw",
                                @"as":@"fla_lang",
                                @"asc":@"fla_lang",
                                @"ascii":@"text",
                                @"asf":@"video",
                                @"asp":@"web_lang",
                                @"aspx":@"web_lang",
                                @"asx":@"playlist",
                                @"avi":@"video",
                                @"bay":@"raw",
                                @"bmp":@"graphic",
                                @"bz2":@"compressed",
                                @"c":@"source_code",
                                @"cc":@"source_code",
                                @"cdr":@"vector",
                                @"cgi":@"web_lang",
                                @"class":@"java",
                                @"com":@"executable",
                                @"cpp":@"source_code",
                                @"cr2":@"raw",
                                @"css":@"web_data",
                                @"cxx":@"source_code",
                                @"dcr":@"raw",
                                @"db":@"database",
                                @"dbf":@"database",
                                @"dhtml":@"html",
                                @"dll":@"source_code",
                                @"dng":@"raw",
                                @"doc":@"word",
                                @"docx":@"word",
                                @"dotx":@"word",
                                @"dwg":@"cad",
                                @"dwt":@"dreamweaver",
                                @"dxf":@"cad",
                                @"dmg":@"dmg",
                                @"eps":@"vector",
                                @"exe":@"executable",
                                @"fff":@"raw",
                                @"fla":@"flash",
                                @"flac":@"audio",
                                @"flv":@"video",
                                @"fnt":@"font",
                                @"fon":@"font",
                                @"gadget":@"executable",
                                @"gif":@"graphic",
                                @"gpx":@"gis",
                                @"gsheet":@"spreadsheet",
                                @"gz":@"compressed",
                                @"h":@"source_code",
                                @"hpp":@"source_code",
                                @"htm":@"html",
                                @"html":@"html",
                                @"iff":@"audio",
                                @"inc":@"web_lang",
                                @"indd":@"indesign",
                                @"jar":@"java",
                                @"java":@"java",
                                @"jpeg":@"image",
                                @"jpg":@"image",
                                @"js":@"web_data",
                                @"key":@"keynote",
                                @"kml":@"gis",
                                @"log":@"text",
                                @"m":@"source_code",
                                @"mm":@"source_code",
                                @"m3u":@"playlist",
                                @"m4v":@"video",
                                @"m4a":@"audio",
                                @"max":@"3d",
                                @"mdb":@"database",
                                @"mef":@"raw",
                                @"mid":@"midi",
                                @"midi":@"midi",
                                @"mkv":@"video",
                                @"mov":@"video",
                                @"mp3":@"audio",
                                @"mp4":@"video",
                                @"mpeg":@"video",
                                @"mpg":@"video",
                                @"mrw":@"raw",
                                @"msi":@"executable",
                                @"nb":@"spreadsheet",
                                @"numbers":@"numbers",
                                @"nef":@"raw",
                                @"obj":@"3d",
                                @"odp":@"generic",
                                @"ods":@"spreadsheet",
                                @"odt":@"text",
                                @"ogv":@"video",
                                @"otf":@"font",
                                @"ots":@"spreadsheet",
                                @"orf":@"raw",
                                @"pages":@"pages",
                                @"pcast":@"podcast",
                                @"pdb":@"database",
                                @"pdf":@"pdf",
                                @"pef":@"raw",
                                @"php":@"web_lang",
                                @"php3":@"web_lang",
                                @"php4":@"web_lang",
                                @"php5":@"web_lang",
                                @"phtml":@"web_lang",
                                @"pl":@"web_lang",
                                @"pls":@"playlist",
                                @"png":@"graphic",
                                @"ppj":@"premiere",
                                @"pps":@"powerpoint",
                                @"ppt":@"powerpoint",
                                @"pptx":@"powerpoint",
                                @"prproj":@"premiere",
                                @"psb":@"photoshop",
                                @"psd":@"photoshop",
                                @"py":@"web_lang",
                                @"ra":@"real_audio",
                                @"ram":@"real_audio",
                                @"rar":@"compressed",
                                @"rm":@"real_audio",
                                @"rtf":@"text",
                                @"rw2":@"raw",
                                @"rwl":@"raw",
                                @"sh":@"source_code",
                                @"shtml":@"web_data",
                                @"sitx":@"compressed",
                                @"sketch":@"sketch",
                                @"sql":@"database",
                                @"srf":@"raw",
                                @"srt":@"subtitles",
                                @"stl":@"3d",
                                @"svg":@"vector",
                                @"svgz":@"vector",
                                @"swf":@"swf",
                                @"tar":@"compressed",
                                @"tbz":@"compressed",
                                @"tga":@"graphic",
                                @"tgz":@"compressed",
                                @"tif":@"graphic",
                                @"tiff":@"graphic",
                                @"torrent":@"torrent",
                                @"ttf":@"font",
                                @"txt":@"text",
                                @"vcf":@"vcard",
                                @"vob":@"video_vob",
                                @"wav":@"audio",
                                @"webm":@"video",
                                @"wma":@"audio",
                                @"wmv":@"video",
                                @"wpd":@"text",
                                @"wps":@"word",
                                @"xhtml":@"html",
                                @"xlr":@"spreadsheet",
                                @"xls":@"excel",
                                @"xlsx":@"excel",
                                @"xlt":@"excel",
                                @"xltm":@"excel",
                                @"xml":@"web_data",
                                @"zip":@"compressed"};
    
    extension = extension.lowercaseString;;
    UIImage *image;
    if ([extension isEqualToString:@"jpg"] || [extension isEqualToString:@"jpeg"]) {
        image = [UIImage imageNamed:@"info_image"];
    } else {
        NSString *filetypeImage = [fileTypesDictionary valueForKey:extension];
        if (filetypeImage && filetypeImage.length > 0) {
            image = [UIImage imageNamed:[NSString stringWithFormat:@"info_%@", filetypeImage]];
        } else {
            image = [UIImage imageNamed:@"info_generic"];
        }
    }
    self.image = image;
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type != MEGAErrorTypeApiOk) {
        return;
    }
    
    if (request.type == MEGARequestTypeGetAttrUser) {
        self.image = [UIImage imageWithContentsOfFile:request.file];
    }
}

@end
