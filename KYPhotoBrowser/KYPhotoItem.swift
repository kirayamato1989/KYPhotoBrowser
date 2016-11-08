//
//  KYPhotoItem.swift
//  KYPhotoBrowser
//
//  Created by 郭帅 on 2016/11/8.
//  Copyright © 2016年 郭帅. All rights reserved.
//

import UIKit
import Kingfisher

/// 照片模型类
public class KYPhotoItem: KYPhotoSource {
    public var url: URL?
    public var placeholder: UIImage?
    public var image: UIImage?
    public var des: String?
    
    init(url: URL?, placeholder: UIImage?, image: UIImage?, des: String?) {
        self.image = image
        self.url = url
        self.placeholder = placeholder
        self.des = des
    }
    
    public func loadIfNeed(progress: ((KYPhotoSource, Int64, Int64) -> ())?, complete: ((KYPhotoSource, UIImage?, Error?) -> ())?) {
        if image == nil, let _ = url {
            if url!.isFileURL {
                let localImage = UIImage(contentsOfFile: url!.path)
                var error: Error?
                if localImage == nil {
                    error = NSError()
                }
                image = localImage
                complete?(self, localImage, error)
            }
            else {
                // 抓取image
                KingfisherManager.shared.retrieveImage(with: url!, options: [.preloadAllGIFData], progressBlock: { [weak self](current, total) in
                    if let _ = self {
                        progress?(self!, current, total)
                    }
                    }, completionHandler: {[weak self](image, error, cacheType, url) in
                        if let _ = self {
                            self!.image = image
                            complete?(self!, image, error)
                        }
                })
            }
        }
        else {
            let error: Error? = image == nil ? NSError() : nil
            complete?(self, image, error)
        }
    }
    
    public func releaseImage() {
        self.image = nil
    }
}
