//
//  UIImage+WebP.m
//  webPDemo
//
//  Created by 李坤坤 on 2019/12/5.
//  Copyright © 2019 李坤坤. All rights reserved.
//

#import "UIImage+WebP.h"
#import <Accelerate/Accelerate.h>
#import <libwebp/libwebp-umbrella.h>

static void FreeImageData(void *info, const void *data, size_t size) {
    free((void *)data);
}

@implementation UIImage (WebP)



- (NSData *)webPData{
    double compressionQuality = 0.75;
    NSData *webpData;
    CGImageRef imageRef = self.CGImage;
    if (!imageRef) {
        return nil;
    }
    
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    if (width == 0 || width > WEBP_MAX_DIMENSION) {
        return nil;
    }
    if (height == 0 || height > WEBP_MAX_DIMENSION) {
        return nil;
    }
    
    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    CGImageAlphaInfo alphaInfo = bitmapInfo & kCGBitmapAlphaInfoMask;
    CGBitmapInfo byteOrderInfo = bitmapInfo & kCGBitmapByteOrderMask;
    BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                      alphaInfo == kCGImageAlphaNoneSkipFirst ||
                      alphaInfo == kCGImageAlphaNoneSkipLast);
    BOOL byteOrderNormal = NO;
    switch (byteOrderInfo) {
        case kCGBitmapByteOrderDefault: {
            byteOrderNormal = YES;
        } break;
        case kCGBitmapByteOrder32Little: {
        } break;
        case kCGBitmapByteOrder32Big: {
            byteOrderNormal = YES;
        } break;
        default: break;
    }
    CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
    if (!dataProvider) {
        return nil;
    }
    CFDataRef dataRef = CGDataProviderCopyData(dataProvider);
    if (!dataRef) {
        return nil;
    }
    
    uint8_t *rgba = NULL;
    if (byteOrderNormal && ((alphaInfo == kCGImageAlphaNone) || (alphaInfo == kCGImageAlphaLast))) {
        rgba = (uint8_t *)CFDataGetBytePtr(dataRef);
    } else {
        vImageConverterRef convertor = NULL;
        vImage_Error error = kvImageNoError;
        
        vImage_CGImageFormat srcFormat = {
            .bitsPerComponent = (uint32_t)CGImageGetBitsPerComponent(imageRef),
            .bitsPerPixel = (uint32_t)CGImageGetBitsPerPixel(imageRef),
            .colorSpace = CGImageGetColorSpace(imageRef),
            .bitmapInfo = bitmapInfo
        };
        vImage_CGImageFormat destFormat = {
            .bitsPerComponent = 8,
            .bitsPerPixel = hasAlpha ? 32 : 24,
            .colorSpace = CGColorSpaceCreateDeviceRGB(),
            .bitmapInfo = hasAlpha ? kCGImageAlphaLast | kCGBitmapByteOrderDefault : kCGImageAlphaNone | kCGBitmapByteOrderDefault
        };
        
        convertor = vImageConverter_CreateWithCGImageFormat(&srcFormat, &destFormat, NULL, kvImageNoFlags, &error);
        if (error != kvImageNoError) {
            CFRelease(dataRef);
            return nil;
        }
        
        vImage_Buffer src = {
            .data = (uint8_t *)CFDataGetBytePtr(dataRef),
            .width = width,
            .height = height,
            .rowBytes = bytesPerRow
        };
        vImage_Buffer dest;
        
        error = vImageBuffer_Init(&dest, height, width, destFormat.bitsPerPixel, kvImageNoFlags);
        if (error != kvImageNoError) {
            vImageConverter_Release(convertor);
            CFRelease(dataRef);
            return nil;
        }
        
        
        error = vImageConvert_AnyToAny(convertor, &src, &dest, NULL, kvImageNoFlags);
        vImageConverter_Release(convertor);
        if (error != kvImageNoError) {
            CFRelease(dataRef);
            return nil;
        }
        
        rgba = dest.data;
        bytesPerRow = dest.rowBytes;
        CFRelease(dataRef);
        dataRef = NULL;
    }
    
    uint8_t *data = NULL;
    float qualityFactor = compressionQuality * 100; // WebP quality is 0-100
    size_t size;
    if (hasAlpha) {
        size = WebPEncodeRGBA(rgba, (int)width, (int)height, (int)bytesPerRow, qualityFactor, &data);
    } else {
        size = WebPEncodeRGB(rgba, (int)width, (int)height, (int)bytesPerRow, qualityFactor, &data);
    }
    if (dataRef) {
        CFRelease(dataRef);
        dataRef = NULL;
    } else {
        free(rgba);
        rgba = NULL;
    }
    
    if (size) {
        webpData = [NSData dataWithBytes:data length:size];
    }
    if (data) {
        WebPFree(data);
    }
    
    return webpData;
}

+ (instancetype)imageWithWebPData:(NSData *)data{
    if (!data) {
        return nil;
    }
    WebPData webpData;
    WebPDataInit(&webpData);
    webpData.bytes = data.bytes;
    webpData.size = data.length;
    WebPDemuxer *demuxer = WebPDemux(&webpData);
    if (!demuxer) {
        return nil;
    }
    WebPIterator iter;
    if (!WebPDemuxGetFrame(demuxer, 1, &iter)) {
        WebPDemuxReleaseIterator(&iter);
        WebPDemuxDelete(demuxer);
        return nil;
    }
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    WebPDecoderConfig config;
    if (!WebPInitDecoderConfig(&config)) {
           return nil;
       }
    if (WebPGetFeatures(webpData.bytes, webpData.size, &config.input) != VP8_STATUS_OK) {
        return nil;
    }
    BOOL hasAlpha = config.input.has_alpha;
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
    bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
    config.options.use_threads = 1;
    config.output.colorspace = MODE_bgrA;
    if (WebPDecode(webpData.bytes, webpData.size, &config) != VP8_STATUS_OK) {
        return nil;
    }
    int width = config.input.width;
    int height = config.input.height;
    if (config.options.use_scaling) {
        width = config.options.scaled_width;
        height = config.options.scaled_height;
    }
    CGDataProviderRef provider =
    CGDataProviderCreateWithData(NULL, config.output.u.RGBA.rgba, config.output.u.RGBA.size, FreeImageData);
    size_t bitsPerComponent = 8;
    size_t bitsPerPixel = 32;
    size_t bytesPerRow = config.output.u.RGBA.stride;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpace, bitmapInfo, provider, NULL, NO, renderingIntent);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:1 orientation:UIImageOrientationUp];

    CGImageRelease(imageRef);
    WebPDemuxReleaseIterator(&iter);
    WebPDemuxDelete(demuxer);
    return image;
}


@end

