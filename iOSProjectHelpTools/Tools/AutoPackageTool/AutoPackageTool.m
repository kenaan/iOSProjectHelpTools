//
//  MainBusiness.m
//  AutoPackageConsol
//
//  Created by 刘杰cjs on 15/4/28.
//  Copyright (c) 2015年 com.cjs.lj. All rights reserved.
//

#import "AutoPackageTool.h"
#import <AppKit/AppKit.h>
#import "NSImage+LJNSImage.h"
#import "NSDate+LJ.h"
@implementation AutoPackageTool

+ (void) exec{

    NSFileManager * fm = [NSFileManager defaultManager];
    /*----------------- 说明  ------------------*/
    //渠道打包元数据信息所在目录的路径 参考项目中的 metadatas 文件夹
   /*
    该目录下需要以下资源文件:
        icon.png ： 尺寸必须大于512x512 的 app icon 图片
        toPackageChannels.plist : 要打包的渠道信息配置文件 （在项目中的 示例模板/toPackageChannels.plist 查看配置的模板）
        masterEP.xcarchive : 母归档包(该包使用企业签名打包的) 用于导出各个渠道的ipa包
    */
    
    /*----------------- 配置  start ------------------*/
    NSString * metadatasDirPath = @"/Users/jerry/Desktop/批量打渠道包配置";
    
    NSString * bundleID = @"com.sz.estay.EstayEP";
    NSString * version = @"1.3.6";
    NSString * subtitle =@"一呆公寓-高品质度假公寓预定平台";
    NSString * title = @"一呆公寓";
    //产品名称ID
    NSString * productID = @"ydgy";//一呆公寓 （ydgy 或 djb）
    //服务器文件下载根目录的URI
    NSString * downloadRootUrl = @"http://app.estay.com/";
    /*----------------- 配置  end ------------------*/
    
    
    
    //源 icon 路径
    NSString * iconPath = [metadatasDirPath stringByAppendingPathComponent:@"icon.png"];
    //渠道信息配置文件
    NSString * channelConfigFilePath = [metadatasDirPath stringByAppendingPathComponent:@"toPackageChannels.plist"];
    //xcarchive 包位置
    NSString * basicArchivePath = [metadatasDirPath stringByAppendingPathComponent:@"masterEP.xcarchive"];
    //检查元信息资源文件
    if (![fm fileExistsAtPath:metadatasDirPath]) {
        NSLog(@"ERROR:元信息资源缺失-元信息资源目录不存在");
        return;
    }
    if (![fm fileExistsAtPath:iconPath]) {
        NSLog(@"ERROR:元信息资源缺失-icon.png 不存在");
        return;
    }
    if (![fm fileExistsAtPath:channelConfigFilePath]) {
        NSLog(@"ERROR:元信息资源缺失-toPackageChannels.plist 渠道配置信息不存在");
        return;
    }
    if (![fm fileExistsAtPath:basicArchivePath]) {
        NSLog(@"ERROR:元信息资源缺失-masterEP.xcarchive 母归档包不存在");
        return;
    }
    
    /*----------------- 输出的资源路径 ----------------- */
    //输出目录
    NSString * outPutDir = [metadatasDirPath stringByAppendingPathComponent:@"输出"];
    //日志文件存放目录
    NSString * logsDir =[metadatasDirPath stringByAppendingPathComponent:@"日志"];
    //存放ipa下载路径的txt
    NSString * ipaDownLoadDescriptionFilePath = [metadatasDirPath stringByAppendingPathComponent:@"渠道ipa包下载地址.txt"];
    
    /*----------------- 开始 ----------------- */
    //清空 日志 目录下的内容
    [fm removeItemAtPath:logsDir error:nil];
    //创建日志输出文件夹
    if (![fm fileExistsAtPath:logsDir]) {
        BOOL  isSuc = [fm createDirectoryAtPath:logsDir withIntermediateDirectories:YES attributes:nil error:nil];
        if (!isSuc) {
            NSLog(@"ERROR-创建 日志输出目录 失败");
        }
    }
    
    //清空 输出 目录下的内容
    NSError * rerr ;
    BOOL isRmSuc = [fm removeItemAtPath:outPutDir error:&rerr];
    if ([fm fileExistsAtPath:outPutDir] &&( !isRmSuc || rerr )) {
        NSLog(@"ERROR-清空输出目录失败 error:%@",rerr);
        return;
    }
    //创建 输出 目录
    if (![fm fileExistsAtPath:outPutDir]) {
        NSError  *err;
        BOOL isCreateSuc = [fm createDirectoryAtPath:outPutDir withIntermediateDirectories:YES attributes:nil error:&err];
        if (!isCreateSuc || err) {
            NSLog(@"ERROR-创建输出目录失败 error:%@",err);
        }
    }
    
    //删除 ipa 下载描述文件
    [fm removeItemAtPath:ipaDownLoadDescriptionFilePath error:nil];
    //创建 ipa 下载描述文件
    if (![fm fileExistsAtPath:ipaDownLoadDescriptionFilePath ]) {
        NSError  *err;
        BOOL isCreateSuc = [fm createFileAtPath:ipaDownLoadDescriptionFilePath contents:nil attributes:nil];
        if (!isCreateSuc || err) {
            NSLog(@"ERROR-渠道ipa包下载地址.txt error:%@",err);
        }
    }
    /*** 从渠道配置文件 遍历渠道信息 ***/
    //ipa 下载路径的描述 用于写入 渠道ipa包下载地址.txt
    NSMutableString * ipaDownloadUrlDescriptions = [NSMutableString string];
    NSArray * channelInfosArr = [NSArray arrayWithContentsOfFile:channelConfigFilePath];
    //需要打包的渠道个数
    NSInteger needsPackageCount = 0;
    for (NSDictionary * dic in channelInfosArr) {
        if ([dic[@"IsValid"] boolValue]) {
            needsPackageCount++;
        }
    }
    //已经打包的渠道数 在打包执行完毕后+1
     __block NSInteger packagedCount = 0;
    [channelInfosArr enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        NSDictionary * channelDic = obj;
        BOOL isValid = [channelDic[@"IsValid"] boolValue];
        if (!isValid) {
            return;
        }
       
        NSString * channelID = channelDic[@"ChannelID"];
        NSString * channelName =channelDic[@"ChannelName"];
  
        /******************** 定义渠道信息文件夹中各项资源的路径 **********************/
        //新建渠道文件夹 (命名：productID_channelID)
        NSString * channelDirPath = [outPutDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@",productID,channelID]];
        //ipa包的路径
        NSString * channelResource_ipaPath = [channelDirPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@.ipa",productID,channelID]];
        //icon 512 的路径
        NSString * channelResource_icon512Path = [channelDirPath stringByAppendingPathComponent:@"icon_512.png"];
        //icon 57 的路径
        NSString * channelResource_icon57Path = [channelDirPath stringByAppendingPathComponent:@"icon_57.png"];
        //mainfest.plist 路径
        NSString * channelResource_mainfestPlistPath = [channelDirPath stringByAppendingPathComponent:@"mainfest.plist"];
        //down.html 路径
        NSString * channelResource_downHtmlPath = [channelDirPath stringByAppendingPathComponent:@"down.html"];
        //导出 archive 为 ipa时的正常日志
        NSString * exportArchiveLogFile_path =[ logsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_exportArchive_Log",channelID]];
        //导出 archive 为 ipa时的错误日志
        NSString * exportArchiveErrorLogFile_path =[ logsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_exportArchive_ERROR_Log",channelID]];
        
        //ipa 包的下载路径
        NSString * channelResource_ipaUrl = [AutoPackageTool getChannelResourceDownloadUrlWithChannelDirPath:channelDirPath resourcePath:channelResource_ipaPath serverDownloadRootUrl:downloadRootUrl];
        //icon 512 的下载路径
        NSString * channelResource_icon512Url = [AutoPackageTool getChannelResourceDownloadUrlWithChannelDirPath:channelDirPath resourcePath:channelResource_icon512Path serverDownloadRootUrl:downloadRootUrl];
        //icon 57 的下载路径
        NSString * channelResource_icon57Url = [AutoPackageTool getChannelResourceDownloadUrlWithChannelDirPath:channelDirPath resourcePath:channelResource_icon57Path serverDownloadRootUrl:downloadRootUrl];
        //mainfest.plist 下载路径
        NSString * channelResource_mainfestPlistUrl = [AutoPackageTool getChannelResourceDownloadUrlWithChannelDirPath:channelDirPath resourcePath:channelResource_mainfestPlistPath serverDownloadRootUrl:downloadRootUrl];
        //down.html 下载路径
        NSString * channelResource_downHtmlUrl =[AutoPackageTool getChannelResourceDownloadUrlWithChannelDirPath:channelDirPath resourcePath:channelResource_downHtmlPath serverDownloadRootUrl:downloadRootUrl];
        
        /******************** 生成渠道信息资源 **********************/
        if (![channelResource_mainfestPlistUrl containsString:@"https://"]) {
            channelResource_mainfestPlistUrl = [channelResource_mainfestPlistUrl stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
        }
        NSString * linkStr = [NSString stringWithFormat:@"itms-services://?action=download-manifest&url=%@",channelResource_mainfestPlistUrl];
        //添加ipa下载描述
        [ipaDownloadUrlDescriptions appendFormat:@"%@ %@: \n    %@\n    %@\n\n",channelID,channelName, channelResource_downHtmlUrl,linkStr];
        
        //创建渠道文件夹
        NSError * err;
        BOOL isSucc = [fm createDirectoryAtPath:channelDirPath withIntermediateDirectories:YES attributes:nil error:&err];
        if (!isSucc || err) {
            NSLog(@"ERROR-建立渠道文件夹失败 error:%@",err);
            return ;
        }
        
        //将xarchive 文件 拷贝到 渠道文件夹中
        NSString * tmpArcFilePath = [channelDirPath stringByAppendingPathComponent:@"tmp.xcarchive"] ;
        NSError * err2;
        BOOL isCopySuc = [fm copyItemAtPath:basicArchivePath toPath:tmpArcFilePath error:&err2];
        if (!isCopySuc || err2) {
            NSLog(@"ERROR-拷贝 xarchive 至渠道文件夹中时出错 error:%@",err2);
            return ;
        }
        //修改 xarchive bundle 中 渠道配置信息文件
        NSString * bundlePath = [AutoPackageTool getBundelPathInXArchivePath:tmpArcFilePath];
        NSString * bundelChannelCnfPath = [bundlePath stringByAppendingPathComponent:@"DownLoadChannleInfoForEnterprise.plist"];
        if (![fm fileExistsAtPath:bundelChannelCnfPath]) {
            NSLog(@"ERROR-在 项目 Bundle 中未找到 渠道信息配置 文件");
            return;
        }
        NSMutableDictionary * channelInfoDic =  [NSMutableDictionary dictionaryWithContentsOfFile:bundelChannelCnfPath];
        [channelInfoDic setObject:channelID forKey:@"ChannelID"];
        [channelInfoDic setObject:channelName forKey:@"ChannelName"];
        BOOL isWriteSuc = [channelInfoDic writeToFile:bundelChannelCnfPath atomically:YES];
        if (!isWriteSuc) {
            NSLog(@"ERROR-更新渠道信息配置文件时出错");
            return;
        }
        
        
        
        //执行 导出ipa包 脚本
        NSTask * task = [[NSTask alloc]init];
        
        if (![fm fileExistsAtPath:exportArchiveLogFile_path]) {
            BOOL  isSuc = [fm createFileAtPath:exportArchiveLogFile_path contents:nil attributes:nil];
            if (!isSuc) {
                NSLog(@"ERROR-创建 exportArchiveLog 文件失败");
            }
        }
        if (![fm fileExistsAtPath:exportArchiveErrorLogFile_path]) {
            BOOL  isSuc = [fm createFileAtPath:exportArchiveErrorLogFile_path contents:nil attributes:nil];
            if (!isSuc) {
                NSLog(@"ERROR-创建 exportArchiveErrorLog 文件失败");
            }
        }
        task.standardOutput = [NSFileHandle fileHandleForWritingAtPath:exportArchiveLogFile_path];
        task.standardError = [NSFileHandle fileHandleForWritingAtPath:exportArchiveErrorLogFile_path];
        task.terminationHandler = ^ void (NSTask * task){
            //删除 tmpArcFilePath
            NSError * err;
            BOOL isDelSuc = [fm removeItemAtPath:tmpArcFilePath error:&err];
            if (!isDelSuc || err) {
                NSLog(@"ERROR-删除 tmpArcFilePath 失败 error:%@",err);
            }
            NSLog(@"渠道 %@ 导出ipa结束",channelID);
            //已打包个数+1
            ++packagedCount;
        };
        task.arguments=@[@"-exportArchive",
                         @"-exportFormat",@"IPA",
                         @"-archivePath",tmpArcFilePath,
                         @"-exportPath",channelResource_ipaPath,
                         @"-exportProvisioningProfile",@"estay_EP_inHouse_ppf"
                         ];
        task.launchPath = @"/usr/bin/xcodebuild";
        [task launch];
        
        //在 渠道信息 文件夹内 生成 512x512 尺寸的icon
        NSImage * iconImg = [[NSImage alloc]initWithContentsOfFile:iconPath];
        NSError * er3;
        BOOL isCreateImg_512_Suc = [iconImg writePNGToURL:[[NSURL alloc]initFileURLWithPath:channelResource_icon512Path] outputSizeInPixels:NSMakeSize(512, 512) error:&er3];

        if (!isCreateImg_512_Suc || er3) {
            NSLog(@"ERROR-生成 icon 512 图标时出错 error:%@",er3);
            return;
        }
        
        //在 渠道信息 文件夹内 生成  57x57 尺寸的icon
        NSError * er4;
        BOOL isCreateImg_57_Suc = [iconImg writePNGToURL:[[NSURL alloc]initFileURLWithPath:channelResource_icon57Path] outputSizeInPixels:NSMakeSize(57, 57) error:&er4];
        
        if (!isCreateImg_57_Suc || er4) {
            NSLog(@"ERROR-生成 icon 57 图标时出错 error:%@",er4);
            return;
        }
        //创建 mainfest.plist
        BOOL isCreateMainfestSuc = [self createMainfestPlistWithIpaUrl:channelResource_ipaUrl icon512Url:channelResource_icon512Url icon57Url:channelResource_icon57Url bundleID:bundleID version:version subtitle:subtitle title:title toPath:channelResource_mainfestPlistPath];
        if (!isCreateMainfestSuc) {
            NSLog(@"ERROR:创建渠道 manifest.plist 失败");
            return;
        }
        //创建 down.html 用户提供下载页面
        [self createDownHtmlWithMainfestPlistUrl:channelResource_mainfestPlistUrl toPath:channelResource_downHtmlPath];
    }];
    while (packagedCount < needsPackageCount) {
        [NSThread sleepForTimeInterval:0.2];
        NSLog(@"正在导出 ipa 包，总共需要导出 %d 个 , 已经导出 %d 个",needsPackageCount,packagedCount);
        //打包完毕 写入下载信息
        if (packagedCount>=needsPackageCount) {
            [[ipaDownloadUrlDescriptions dataUsingEncoding:NSUTF8StringEncoding] writeToFile:ipaDownLoadDescriptionFilePath atomically:YES];
        }
    }
}
+ (void) blockRunloop{
    CFRunLoopRun();
}
+ (void) stopRunloop{
    CFRunLoopRef runLoopRef = CFRunLoopGetCurrent();
    CFRunLoopStop(runLoopRef);
}
#pragma mark ------------------------- 内部业务 -------------------------
#pragma mark 根据渠道信息获取渠道内资源的下载路径
/*
   根据 渠道目录路径、渠道资源路径、网站下载根目录的url 计算出资源的下载路径
 渠道目录 放在网站下载根目录
 */
+ (NSString * ) getChannelResourceDownloadUrlWithChannelDirPath:(NSString * )channelDirPath resourcePath:(NSString * )resourcePath serverDownloadRootUrl:(NSString *) downloadRootUrl{
    //渠道文件夹 所在目录的路径
    NSString * channelDirFatherDirPath = [channelDirPath stringByDeletingLastPathComponent];
    //渠道文件夹相对于所在目录的路径
    NSString * channelDirRelativePath =[channelDirPath stringByReplacingOccurrencesOfString:channelDirFatherDirPath withString:@""];
    //资源文件相对于渠道文件夹的路径
    NSString * resourceRelativeChannelDirPath =[resourcePath stringByReplacingOccurrencesOfString:channelDirPath withString:@""];
    //渠道文件夹的下载路径
    NSString * channelDirUrl = [downloadRootUrl stringByAppendingPathComponent:channelDirRelativePath];
    
    //资源文件的下载路径
    NSString * channelResourceUrl =[channelDirUrl stringByAppendingPathComponent:resourceRelativeChannelDirPath];
    
    channelResourceUrl = [channelResourceUrl stringByReplacingOccurrencesOfString:@"http:/" withString:@"http://"];
    
    NSLog(@"%@",channelResourceUrl);
    return channelResourceUrl;
}
#pragma mark 根据 archive Path 返回 archive中 .app文件的路径
+ (NSString *) getBundelPathInXArchivePath:(NSString * )xarchivePath{
    return [xarchivePath stringByAppendingPathComponent:@"/Products/Applications/EstayEP.app"];
}
#pragma mark 创建 用于下载的html 文件
+ (void) createDownHtmlWithMainfestPlistUrl:(NSString * )mainfestUrl toPath:(NSString *)toPath{
    if (![mainfestUrl containsString:@"https://"]) {
        mainfestUrl = [mainfestUrl stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
    }
    NSString * linkStr = [NSString stringWithFormat:@"itms-services://?action=download-manifest&url=%@",mainfestUrl];
    NSMutableString * htmlStr=[NSMutableString string];
    [htmlStr appendString:@"<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">"];
    [htmlStr appendString:@"<html xmlns=\"http://www.w3.org/1999/xhtml\">"];
    [htmlStr appendString:@"<head><script type=\"text/javascript\">"];
    [htmlStr appendFormat:@"window.location.href = \"%@\";",linkStr];
    [htmlStr appendString:@"</script></head><body></body></html>"];
    NSError * err;
    BOOL isSuc = [htmlStr writeToFile:toPath atomically:YES encoding:NSUTF8StringEncoding error:&err];
    if (!isSuc || err) {
        NSLog(@"ERROR-创建下载html文件失败 error:%@",err);
        return;
    }
}
#pragma mark 创建用于ipa下载的 mainfest.plist
+ (BOOL) createMainfestPlistWithIpaUrl:(NSString *)ipaUrl icon512Url:(NSString *)icon512Url icon57Url:(NSString *)icon57Url bundleID:(NSString *)bundleID version:(NSString *)version subtitle:(NSString *)subtitle title:(NSString *)title toPath:(NSString *)toPath{
    NSString * tsStr=  [[NSDate date] stringWithFormat:@"yyyyMMddHHmmss"];
    NSDictionary * dic = @{
                           @"items":@[@{
                                          @"assets":@[
                                                  @{
                                                      @"kind":@"software-package",
                                                      @"url":ipaUrl
                                                      },
                                                  
                                                  @{
                                                      @"kind":@"full-size-image",
                                                      @"needs-shine":@(NO),
                                                      @"url":icon512Url
                                                      },
                                                  @{
                                                      @"kind":@"display-image",
                                                      @"needs-shine":@(NO),
                                                      @"url":icon57Url
                                                      },
                                                  ],
                                          @"metadata":@{
                                                  @"bundle-identifier":[bundleID stringByAppendingString:tsStr],//解决ios8 BUG
                                                  @"bundle-version":version,
                                                  @"kind":@"software",
                                                  @"subtitle":subtitle,
                                                  @"title":title
                                                  }
                                          }]
                           };
    return [dic writeToFile:toPath atomically:YES];
}
@end
