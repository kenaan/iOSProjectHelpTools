//
//  NSImage+LJNSImage.m
//  iOSProjectHelpTools
//
//  Created by 刘杰cjs on 15/4/29.
//  Copyright (c) 2015年 com.cjs.lj. All rights reserved.
//

#import "NSImage+LJNSImage.h"

@implementation NSImage (LJNSImage)
- (BOOL)writePNGToURL:(NSURL*)URL outputSizeInPixels:(NSSize)outputSizePx error:(NSError*__autoreleasing*)error
{
    BOOL result = YES;
    NSImage* scalingImage = [NSImage imageWithSize:[self size] flipped:[self isFlipped] drawingHandler:^BOOL(NSRect dstRect) {
        [self drawAtPoint:NSMakePoint(0.0, 0.0) fromRect:dstRect operation:NSCompositeSourceOver fraction:1.0];
        return YES;
    }];
    NSRect proposedRect = NSMakeRect(0.0, 0.0, outputSizePx.width, outputSizePx.height);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    CGContextRef cgContext = CGBitmapContextCreate(NULL, proposedRect.size.width, proposedRect.size.height, 8, 4*proposedRect.size.width, colorSpace, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    NSGraphicsContext* context = [NSGraphicsContext graphicsContextWithGraphicsPort:cgContext flipped:NO];
    CGContextRelease(cgContext);
    CGImageRef cgImage = [scalingImage CGImageForProposedRect:&proposedRect context:context hints:nil];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)(URL), kUTTypePNG, 1, NULL);
    CGImageDestinationAddImage(destination, cgImage, nil);
    if(!CGImageDestinationFinalize(destination))
    {
        NSDictionary* details = @{NSLocalizedDescriptionKey:@"Error writing PNG image"};
        [details setValue:@"ran out of money" forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:@"SSWPNGAdditionsErrorDomain" code:10 userInfo:details];
        result = NO;
    }
    CFRelease(destination);
    return result;
}
@end
