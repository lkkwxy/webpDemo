//
//  WebPCacheSerializer.swift
//  webPDemo
//
//  Created by 李坤坤 on 2019/12/5.
//  Copyright © 2019 李坤坤. All rights reserved.
//

import Foundation
import Kingfisher
public struct WebPCacheSerializer: CacheSerializer {
    
    public static let `default` = WebPCacheSerializer()

    private init() {}
    
    public func data(with image: KFCrossPlatformImage, original: Data?) -> Data? {
        return image.webPData;
    }
    
    public func image(with data: Data, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        return UIImage(webPData: data);
    }
}
