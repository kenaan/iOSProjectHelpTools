//
//  CreateIconsTool.m
//  iOSProjectHelpTools
//
//  Created by 刘杰cjs on 15/4/29.
//  Copyright (c) 2015年 com.cjs.lj. All rights reserved.
//

#import "CreateIconsTool.h"
#import <AppKit/AppKit.h>
#import "NSImage+LJNSImage.h"
@implementation CreateIconsTool
+ (void) exec{
    //源图片
    NSString * sourceImgPath=@"/Users/jerry/Desktop/1.png";
    //生成图片放置的目标目录
    NSString * targetDirectoryPath = @"/Users/jerry/Desktop/11";
    NSArray * imgSizesArr=@[@(29),@(58),@(87),@(80),@(120),@(57),@(114),@(120),@(180)];
    
    
    
    NSFileManager * fileManager= [NSFileManager defaultManager];
    [fileManager createDirectoryAtPath:targetDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    //要生成的图片的分辨率
    NSString * extension= [sourceImgPath pathExtension];
    NSString * sourceFileNameWithOutExtension = [sourceImgPath lastPathComponent];
    if (extension && extension.length>0) {
        sourceFileNameWithOutExtension =[sourceFileNameWithOutExtension stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@".%@",extension] withString:@""];
    }
    NSImage * sourceImg= [[ NSImage alloc]initWithContentsOfFile:sourceImgPath];
    for (NSNumber * sizeObj in imgSizesArr) {
        CGFloat size = [sizeObj floatValue];
        //这里的单位是 ‘点’ 所以要除2 才能生成对应分辨率的图片
     //   NSImage * targetImg=[sourceImg scaleToSize:CGSizeMake(size/2, size/2)];
        
        NSString * targetFileName = [NSString stringWithFormat:@"%@_%.0f.png",sourceFileNameWithOutExtension,size];
        if(extension && extension.length>0){
            targetFileName = [NSString stringWithFormat:@"%@_%.0f.%@",sourceFileNameWithOutExtension,size,extension];
        }
        
        NSString * targetFilePath = [targetDirectoryPath stringByAppendingPathComponent:targetFileName];
//        [UIImagePNGRepresentation(targetImg) writeToFile:targetFilePath atomically:YES];
//        
        [sourceImg writePNGToURL:[[NSURL alloc]initFileURLWithPath:targetFilePath] outputSizeInPixels:NSMakeSize(size, size) error:nil];
    }
}
@end
