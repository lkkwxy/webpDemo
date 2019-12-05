# Kingfisher源码解析之Processor和CacheSerializer
本篇文章主要介绍Processor和CacheSerializer的基本定义和调用时机，以及利用二者扩展Kingfisher以支持webp格式的图片
### Processor
##### Processor介绍
Kingfisher中Processor是一个协议，定义了对原始数据进行加工处理转换成UIImage的能力（Kingfisher缓存的是处理成功之后的UIImage，根据options的值来决定是否缓存原始数据）。
这里的原始数据是指ImageProcessItem，它是一个枚举类型。Processor和ImageProcessItem定义如下，都是特别简单

```
public enum ImageProcessItem {
    case image(KFCrossPlatformImage)
    case data(Data)
}
public protocol ImageProcessor {
    //标识符，在缓存的时候用到，用于区分原始数据和处理加工之后的数据的
    var identifier: String { get }
    //交给具体的实现类去实现，ImageProcessItem，最终返回一个UIImage
    func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage?
}
```
##### 关于Processor的两个问题
如果你了解过Kingfisher，请尝试回答下这2个问题
1. ImageProcessor.process都在什么时候调用呢？
2. ImageProcessItem关联了2种类型，一种是Data，另一种是UIImage，那么这2种类型分别什么时候会用到呢？

ImageProcessor.process在什么时候调用，在调用的时候会传递什么类型的数据？
1. 当从网络上下载图片成功之后，会调用process把下载成功的data加工处理成我们需要的UIImage。很明显这种情况下传递的是Data类型。
2. 当source是ImageDataProvider时，从source中获取到Data之后，会调用process把data加工处理成我们需要的UIImage。很明显这种情况下传递的也是Data类型。
3. 当读取缓存失败，但读取原始数据缓存成功之后，会调用process把原始数据加工处理成我们需要的UIImage。这种情况会先把读取到的data使用cacheSerializer反序列化为UIImage，然后传递UIImage类型

### CacheSerializer
##### CacheSerializer介绍
Kingfisher中CacheSerializer定义了图片序列化和反序列化的能力，也是一个协议

```
public protocol CacheSerializer {
    func data(with image: KFCrossPlatformImage, original: Data?) -> Data?
    func image(with data: Data, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage?
}
```
##### CacheSerializer的调用时机
1. 当需要磁盘缓存时，会调用`func data(with image: KFCrossPlatformImage, original: Data?) -> Data?`把image序列化成data，以便写入文件
2. 当从磁盘读取数据时，会调用`func image(with data: Data, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage?`把data反序列化为UIImage

### 使用Processor和CacheSerializer扩展Kingfisher，使Kingfisher支持webP格式的图片
Kingfisher本身是不支持webp格式的图片，但是可以利用Processor和CacheSerializer对Kingfisher进行扩展，让Kingfisher支持webP格式的图片

> WebP 标准是 Google 定制的，迄今为止也只有 Google 发布的 libwebp 实现了该的编解码 。 所以这个库也是该格式的事实标准。

因此要想支持webp格式的图片，需要依赖libwebp库，用来实现图片的编码和解码，对于这块的代码我是从[SDWebImageWebPCoder](https://github.com/SDWebImage/SDWebImageWebPCoder)复制过来的，并且去掉了对动图的支持和一些SD配置的代码，如果你对这块感兴趣，请参考源码，由于SD是OC写的，所以这部分我用的也是OC，最终给UIImage添加了一个分类，提供了下面2个方法

```
@interface UIImage (WebP)
//序列化为Data
@property(nonatomic,strong,readonly,nullable) NSData *webPData;
//通过data反序列化为UIImage
+ (nullable instancetype)imageWithWebPData:(NSData *)webPdata;
+ 
@end
```

##### 实现Processor
在process判断item的类型，若是image则直接返回，若是data则反序列化为UIImage
```
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
```
##### CacheSerializer

```
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
```

##### 使用

```
if let url = URL(string:"http://q21556z4z.bkt.clouddn.com/123.webp?e=1575537931&token=7n8bncOpnUSrN4mijeEAJRdVXnC-jm-mk5qTjKjR:L1_MWy3xugv9ct6PD294CHzwiSE=&attname=") {
    imageView.kf.setImage(
        with: url,
        options: [.processor(WebPProcessor.default), .cacheSerializer(WebPCacheSerializer.default)]
    )
}
```
### 补充
虽说上面的代码都比较简单，但是我感觉Kingfisher的这个设计真的挺好的，可扩展支持任意类型的图片，并且Processor是用来加工处理图片的，能做的还有其他方面，比如Kingfisher中提供了多种实现类，比如圆角的RoundCornerImageProcessor，显示高清图的DownsamplingImageProcessor，组装多种Processor的GeneralProcessor。
### 参考
[SDWebImageWebPCoder](https://github.com/SDWebImage/SDWebImageWebPCoder)    
[移动端图片格式调研](https://blog.ibireme.com/2015/11/02/mobile_image_benchmark/)    
[libwebp](https://developers.google.com/speed/webp/)    
