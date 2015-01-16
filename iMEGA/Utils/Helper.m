#import "Helper.h"
#import "MEGASdkManager.h"

@implementation Helper

+ (UIImage *)imageForNode:(MEGANode *)node {
    
    NSDictionary *dictionary = @{@"3ds":@"3D",
                                 @"3dm":@"3D",
                                 @"3fr":@"raw",
                                 @"3g2":@"video",
                                 @"3gp":@"video",
                                 @"7z":@"compressed",
                                 @"aac":@"audio",
                                 @"ac3":@"audio",
                                 @"accdb":@"database",
                                 @"aep":@"aftereffects",
                                 @"aet":@"aftereffects",
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
                                 @"c":@"sourcecode",
                                 @"cc":@"sourcecode",
                                 @"cdr":@"vector",
                                 @"cgi":@"web_lang",
                                 @"class":@"java",
                                 @"com":@"executable",
                                 @"cpp":@"sourcecode",
                                 @"cr2":@"raw",
                                 @"css":@"web_data",
                                 @"cxx":@"sourcecode",
                                 @"dcr":@"raw",
                                 @"db":@"database",
                                 @"dbf":@"database",
                                 @"dhtml":@"html",
                                 @"dll":@"sourcecode",
                                 @"dng":@"raw",
                                 @"doc":@"word",
                                 @"docx":@"word",
                                 @"dotx":@"word",
                                 @"dwg":@"cad",
                                 @"dwt":@"dreamweaver",
                                 @"dxf":@"cad",
                                 @"eps":@"vector",
                                 @"exe":@"executable",
                                 @"fff":@"raw",
                                 @"fla":@"flash",
                                 @"flac":@"audio",
                                 @"flv":@"flash_video",
                                 @"fnt":@"font",
                                 @"fon":@"font",
                                 @"gadget":@"executable",
                                 @"gif":@"graphic",
                                 @"gpx":@"gis",
                                 @"gsheet":@"spreadsheet",
                                 @"gz":@"compressed",
                                 @"h":@"sourcecode",
                                 @"hpp":@"sourcecode",
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
                                 @"key":@"generic",
                                 @"kml":@"gis",
                                 @"log":@"text",
                                 @"m":@"sourcecode",
                                 @"mm":@"sourcecode",
                                 @"m3u":@"playlist",
                                 @"m4a":@"audio",
                                 @"max":@"3D",
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
                                 @"numbers":@"spreadsheet",
                                 @"nef":@"raw",
                                 @"obj":@"3D",
                                 @"odp":@"generic",
                                 @"ods":@"spreadsheet",
                                 @"odt":@"text",
                                 @"ogv":@"video",
                                 @"otf":@"font",
                                 @"ots":@"spreadsheet",
                                 @"orf":@"raw",
                                 @"pages":@"text",
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
                                 @"sh":@"sourcecode",
                                 @"shtml":@"web_data",
                                 @"sitx":@"compressed",
                                 @"sql":@"database",
                                 @"srf":@"raw",
                                 @"srt":@"video_subtitles",
                                 @"stl":@"3D",
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
    
    MEGANodeType nodeType = [node type];
    
    switch (nodeType) {
        case MEGANodeTypeFolder: {
            if ([[MEGASdkManager sharedMEGASdk] isSharedNode:node])
                return [UIImage imageNamed:@"folder_shared"];
            else
                return [UIImage imageNamed:@"folder"];
            }
                
        case MEGANodeTypeRubbish:
            return [UIImage imageNamed:@"folder"];
            
        case MEGANodeTypeFile: {
            NSString *im = [dictionary valueForKey:[node name].lowercaseString.pathExtension];
            if (im && im.length>0) {
                return [UIImage imageNamed:im];
            }
        }
            
        default:
            return [UIImage imageNamed:@"generic"];
    }
    
}

+ (NSString *)pathForNode:(MEGANode *)node searchPath:(NSSearchPathDirectory)path directory:(NSString *)directory {
    
    NSString *destinationPath = [NSSearchPathForDirectoriesInDomains(path, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *fileName = [node base64Handle];
    NSString *destinationFilePath = nil;
    destinationFilePath = [directory isEqualToString:@""] ? [destinationPath stringByAppendingPathComponent:fileName]
    :[[destinationPath stringByAppendingPathComponent:directory] stringByAppendingPathComponent:fileName];
    
    return destinationFilePath;
}

+ (NSString *)pathForNode:(MEGANode *)node searchPath:(NSSearchPathDirectory)path {
    return [self pathForNode:node searchPath:path directory:@""];
}

+ (NSString *)pathForUser:(MEGAUser *)user searchPath:(NSSearchPathDirectory)path directory:(NSString *)directory {
    
    NSString *destinationPath = [NSSearchPathForDirectoriesInDomains(path, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *fileName = [[user email] stringByAppendingString:@""];
    NSString *destinationFilePath = nil;
    destinationFilePath = [directory isEqualToString:@""] ? [destinationPath stringByAppendingPathComponent:fileName]
    :[[destinationPath stringByAppendingPathComponent:directory] stringByAppendingPathComponent:fileName];
    
    return destinationFilePath;
}

@end
