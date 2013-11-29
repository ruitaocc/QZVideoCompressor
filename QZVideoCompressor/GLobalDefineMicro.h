//
//  GLobalDefineMicro.h
//  QZAssetsPicker
//
//  Created by vectorcai on 13-11-25.
//  Copyright (c) 2013年 vectorcai. All rights reserved.
//

#import <Foundation/Foundation.h>

#define isIOS7 ([QZDeviceSystem DeviceSystemIsIOS7])
#define IOS7_OFFSET_FIX ((isIOS7)? 64:0)

@interface QZDeviceSystem : NSObject
+ (BOOL) DeviceSystemIsIOS7;
@end
