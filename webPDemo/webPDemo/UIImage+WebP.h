//
//  UIImage+WebP.h
//  webPDemo
//
//  Created by 李坤坤 on 2019/12/5.
//  Copyright © 2019 李坤坤. All rights reserved.
//




#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (WebP)

@property(nonatomic,strong,readonly,nullable) NSData *webPData;

+ (nullable instancetype)imageWithWebPData:(NSData *)webPdata;

@end

NS_ASSUME_NONNULL_END
