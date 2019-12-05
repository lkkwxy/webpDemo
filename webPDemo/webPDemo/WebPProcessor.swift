//
//  WebpProc.swift
//  webPDemo
//
//  Created by 李坤坤 on 2019/12/5.
//  Copyright © 2019 李坤坤. All rights reserved.
//

import Foundation
import Kingfisher
public struct WebPProcessor: ImageProcessor {
    
    public static let `default` = WebPProcessor()
    
    public let identifier = "WebPProcessor"
    
    public init() {}

    public func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            return image
        case .data(let data):
            return UIImage(webPData: data)
        }
    }
}


