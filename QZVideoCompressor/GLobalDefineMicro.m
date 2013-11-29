//
//  GLobalDefineMicro.m
//  QZAssetsPicker
//
//  Created by vectorcai on 13-11-25.
//  Copyright (c) 2013年 vectorcai. All rights reserved.
//

#import "GLobalDefineMicro.h"

@implementation QZDeviceSystem

+ (BOOL) DeviceSystemIsIOS7
{
    static BOOL __ios7__ = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
            __ios7__ = YES;
        }
    });
    return __ios7__;
}

@end
