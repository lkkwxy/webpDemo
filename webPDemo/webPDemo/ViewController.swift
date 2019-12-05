//
//  ViewController.swift
//  webPDemo
//
//  Created by 李坤坤 on 2019/12/5.
//  Copyright © 2019 李坤坤. All rights reserved.
//

import UIKit
import Kingfisher

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        if let url = URL(string:"http://q21556z4z.bkt.clouddn.com/123.webp?e=1575537931&token=7n8bncOpnUSrN4mijeEAJRdVXnC-jm-mk5qTjKjR:L1_MWy3xugv9ct6PD294CHzwiSE=&attname=") {
            imageView.kf.setImage(
                with: url,
                options: [.processor(WebPProcessor.default), .cacheSerializer(WebPCacheSerializer.default)]
            )
        }
        
        
        

//        let path = Bundle.main.url(forResource: "111.webp", withExtension: "")
//        let data = try! Data(contentsOf: path!)
//        let image = UIImage(webPData: data)
//        imageView.image = image;

    }


}

