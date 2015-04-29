//
//  NSImage+LJNSImage.h
//  iOSProjectHelpTools
//
//  Created by 刘杰cjs on 15/4/29.
//  Copyright (c) 2015年 com.cjs.lj. All rights reserved.
//


#import <AppKit/AppKit.h>
@interface NSImage (LJNSImage)
- (BOOL)writePNGToURL:(NSURL*)URL outputSizeInPixels:(NSSize)outputSizePx error:(NSError*__autoreleasing*)error;
@end
