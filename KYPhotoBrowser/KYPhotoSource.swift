//
//  KYPhotoSource.swift
//  KYPhotoBrowser
//
//  Created by 郭帅 on 2016/11/8.
//  Copyright © 2016年 郭帅. All rights reserved.
//

import UIKit

public protocol KYPhotoSource {
    var url: URL? {get}
    var image: UIImage? {get}
    var placeholder: UIImage? {get}
    var des: String? {get}
    
    func loadIfNeed(progress: ((_ source: KYPhotoSource, _ current: Int64, _ total: Int64) -> ())?, complete: ((_ source: KYPhotoSource, _ image: UIImage?, _ error: Error?) -> ())?)
    
    func releaseImage()
}
