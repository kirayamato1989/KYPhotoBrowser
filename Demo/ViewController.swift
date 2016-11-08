//
//  ViewController.swift
//  KYPhotoBrowser
//
//  Created by 郭帅 on 2016/11/8.
//  Copyright © 2016年 郭帅. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @IBAction func tap(_ sender: Any) {
        let path1 = Bundle.main.path(forResource: "1", ofType: "jpg")
        let path2 = Bundle.main.path(forResource: "2", ofType: "jpg")
        
        let photoItems = [path1!, path2!].map { (path) -> KYPhotoItem in
            let item = KYPhotoItem(url: URL(fileURLWithPath: path), placeholder: nil, image: nil, des: nil)
            return item
        }
        
        let vc = KYPhotoBrowser(photos: photoItems, initialIndex: 1)
        vc.eventMonitor = {
            let event = $1
            _ = $0
            switch event {
            case .oneTap:
                print("单击了\(event.index)")
                break
            case .longPress:
                print("长按了\(event.index)")
                break
            case .displayPageChanged:
                print("图片改变\(event.index)")
                break
            default:
                break
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: 2), execute: {
            self.present(vc, animated: true, completion: nil)
        })
    }

}

