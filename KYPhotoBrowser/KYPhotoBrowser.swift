//
//  PhotoBrowserController.swift
//  FEAlbum
//
//  Created by YamatoKira on 2016/9/23.
//  Copyright © 2016年 feeling. All rights reserved.
//

import Foundation
import KYCircularProgress


/// actions
///
/// - oneTap: 单击了图片
/// - longPress: 长按了图片
/// - dismiss: 浏览器调用了dismiss方法
/// - displayPageChanged: 展示的图片改变
public enum KYPhotoBrowserEvent {
    case oneTap(index: Int)
    case longPress(index: Int)
    case dismiss
    case displayPageChanged(index: Int)
    
    var index: Int {
        switch self {
        case .oneTap(index: let idx):
            return idx
        case .longPress(index: let idx):
            return idx
        case .displayPageChanged(index: let idx):
            return idx
        default:
            return 0
        }
    }
}

public typealias KYPhotoBrowserEventMonitor = ((_ browser: KYPhotoBrowser, _ action: KYPhotoBrowserEvent) -> Void)


/// 图片浏览器
public class KYPhotoBrowser: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    
    // MARK: public properties
    
    /// 浏览器的行为监视
    public var eventMonitor: KYPhotoBrowserEventMonitor?
    
    // public properties
    
    /// 图片间距
    public var spacing: CGFloat = 20 {
        // change layout
        didSet {
            _updateCollectionViewLayout()
        }
    }
    
    
    /// 当前图片索引
    public var currentPage: Int {
        return storedCurrentPage
    }
    
    
    /// 当前图片
    public var currentPhoto: KYPhotoSource {
        return storedPhotos[currentPage]
    }
    
    
    /// 总共有多少图片
    public var numberOfPhoto: Int {
        return storedPhotos.count
    }
    
    /// 是否隐藏完成按钮
    public var doneButtonHide: Bool {
        set {
            doneButton.isHidden = newValue
        }
        get {
            return doneButton.isHidden
        }
    }
    
    // MARK: private properties
    /// 记录当前在第几个图片
    fileprivate var storedCurrentPage: Int = 0 {
        didSet {
            eventMonitor?(self, .displayPageChanged(index: storedCurrentPage))
        }
    }
    
    
    /// 图片数据源
    fileprivate var storedPhotos: [KYPhotoSource] = []
    
    
    private var layout: UICollectionViewFlowLayout!
    private var collectionView: UICollectionView!
    private let doneButton: UIButton = UIButton()
    
    // MARK: initialize
    public init(photos: [KYPhotoSource], initialIndex: Int) {
        super.init(nibName: nil, bundle: nil)
        
        storedPhotos += photos
        storedCurrentPage = initialIndex
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: lifeCycle
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIApplication.shared.isStatusBarHidden = false
        navigationController?.navigationBar.isHidden = false
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        _initUI()
    }
    
    override public func didReceiveMemoryWarning() {
        for i in 0..<storedPhotos.count {
            let p = storedPhotos[i]
            
            var needRelease = true
            
            if i == currentPage || i == currentPage - 1 || i == currentPage + 1 {
                needRelease = false
            }
            
            if needRelease {
                p.releaseImage()
            }
        }
    }
    
    // MARK: override
    override public func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // 移动到当前索引页
        _scrollTo(index: currentPage, animated: false)
    }
    
    // MARK: public method
    
    
    /// 根据索引获取Photo实体
    ///
    /// - Parameter index: 索引
    /// - Returns: 数据源
    public func photoAtIndex(_ index: Int) -> KYPhotoSource? {
        guard index > 0 , index < storedPhotos.count else {
            return nil
        }
        return storedPhotos[index]
    }
    
    
    /// 删除某个图片
    ///
    /// - parameter index: 索引
    public func removePhoto(at index: Int) {
        storedPhotos.remove(at: index)
        collectionView?.deleteItems(at: [IndexPath(item: index, section: 0)])
        
        // 防止最后一个被删除时崩溃
        if storedCurrentPage >= storedPhotos.count {
            storedCurrentPage = storedPhotos.count > 0 ? storedCurrentPage - 1 : 0
        }
    }
    
    // MARK: UICollectionViewDelegate
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return storedPhotos.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let c = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! PhotoBrowserCell
        
        c.oneTapClosure = { [weak self](source, cell) in
            if let _ = self {
                self!.eventMonitor?(self!, .oneTap(index: indexPath.row))
            }
        }
        
        c.longPressClosure = { [weak self](source, cell) in
            if let _ = self {
                self!.eventMonitor?(self!, .longPress(index: indexPath.row))
            }
        }
        
        let photo = storedPhotos[indexPath.row]
        c.source = photo
        
        return c
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let containerW = scrollView.bounds.size.width
        
        if containerW <= 0 {return}
        
        let contentOffset = scrollView.contentOffset
        
        let newIndex = Int((contentOffset.x + containerW / 2) / containerW)
        
        if newIndex != storedCurrentPage {
            storedCurrentPage = newIndex
        }
    }
    
    // MARK: private method
    private func _initUI() {
        //
        view.backgroundColor = .white
        automaticallyAdjustsScrollViewInsets = false

        //
        layout = UICollectionViewFlowLayout()
        layout?.scrollDirection = .horizontal
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout!)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView?.register(PhotoBrowserCell.self, forCellWithReuseIdentifier: "cell")
        collectionView?.backgroundColor = .black
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.isPagingEnabled = true
        collectionView?.showsVerticalScrollIndicator = false
        collectionView?.showsHorizontalScrollIndicator = false
        view.addSubview(collectionView!)
        
        
        //
        _updateCollectionViewLayout()
        
        //
        if navigationController == nil {
            // 添加一个返回按钮
            doneButton.frame = CGRect(x: 10, y: 10, width: 60, height: 44)
            doneButton.setTitle("Done", for: .normal)
            doneButton.setTitleColor(.lightGray, for: .normal)
            view.addSubview(doneButton)
            
            doneButton.addTarget(self, action: #selector(KYPhotoBrowser._dismiss), for: .touchUpInside)
        }
    }
    
    
    /// 更新collectionView的布局
    private func _updateCollectionViewLayout() {
        let spacing = max(self.spacing, 0)
        
        // 左右偏移是为了解决分页的问题
        collectionView?.frame = CGRect(x: -spacing / 2.0, y: 0, width: view.frame.width + spacing, height: view.frame.height)
        
        // 注意这里设置minimumInteritemSpacing是不起作用的，因为是horizon布局
        layout?.minimumLineSpacing = spacing
        layout?.sectionInset = UIEdgeInsetsMake(0, spacing / 2.0, 0, spacing / 2.0)
        layout?.itemSize = UIScreen.main.bounds.size
        
        collectionView?.reloadData()
    }
    
    
    /// 滑动到某个索引
    ///
    /// - Parameters:
    ///   - index: 目标索引
    ///   - animated: 是否动画
    private func _scrollTo(index: Int, animated: Bool) {
        if let _ = collectionView {
            let contentOffsetX = collectionView!.bounds.size.width * CGFloat(index)
            UIView.animate(withDuration: animated ? 0.4 : 0.0) {
                self.collectionView?.contentOffset = CGPoint(x: contentOffsetX, y: 0)
            }
        }
    }
    
    
    /// 更新title
    private func _updateTitle() {
        // 置nil
        if storedPhotos.count < 2 {
            title = nil
            return
        }
        
        // change title
        title = String(format: "%i / %i", currentPage + 1, storedPhotos.count)
    }
    
    private func _hideOrShowNavbarAndToolbar() {
        let hidden = UIApplication.shared.isStatusBarHidden
        
        UIApplication.shared.isStatusBarHidden = !hidden
        if let nav = self.navigationController {
            nav.setNavigationBarHidden(!hidden, animated: true)
        }
    }
    
    @objc private func _dismiss() {
        self.dismiss(animated: true, completion: nil)
    }
    
    deinit {
        // 释放所有的大图
        storedPhotos.forEach { (p) in
            p.releaseImage()
        }
    }
}


/// 用于显示照片的cell

fileprivate typealias PhotoBrowserCellActionClosure = ((KYPhotoSource?, UICollectionViewCell) -> Void)

fileprivate class PhotoBrowserCell: UICollectionViewCell, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    // 外层用于放大缩小的scrollView
    
    fileprivate let scrollWrapper: UIScrollView = UIScrollView()
    
    let imageView: UIImageView = UIImageView()
    
    var oneTapClosure: PhotoBrowserCellActionClosure?
    
    var doubleTapClosure: PhotoBrowserCellActionClosure?
    
    var longPressClosure: PhotoBrowserCellActionClosure?
    
    let progressView: KYCircularProgress = {
        let view = KYCircularProgress(frame: CGRect(x: 0, y: 0, width: 44, height: 44), showGuide: true)
        view.colors = [.gray]
        view.guideColor = .white
        view.guideLineWidth = 3
        view.lineWidth = 3
        view.startAngle = -.pi/2
        view.endAngle = 3 * .pi/2
        return view
    }()
    
    //
    var source: KYPhotoSource? {
        didSet{
            displaySource()
            
            if source?.image == nil {
                source?.loadIfNeed(progress: { [weak self](source, current, total) in
                    if let _ = self, self?.source?.url == source.url {
                        self?.progressView.progress = Double(current) / Double(total)
                    }
                    }, complete: { [weak self](source, image, error) in
                        if let _ = self, self?.source?.url == source.url {
                            self?.displaySource()
                        }
                    })
            }
        }
    }
    
    // MARK: init
    override init(frame: CGRect) {
        super.init(frame: frame)
        initUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initUI()
    }
    
    // MARK: override
    override func prepareForReuse() {
        super.prepareForReuse()
        source = nil
        imageView.image = nil
        progressView.isHidden = true
        progressView.progress = 0
    }
    
    // MARK: public method

    
    // MARK: UIScrollViewDelegate
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if scrollView == scrollWrapper {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }
    
    // MARK: override
    override func layoutSubviews() {
        super.layoutSubviews()
        
        scrollWrapper.layoutSubviews()
        
        // make center
        let centerX = max(scrollWrapper.frame.width, scrollWrapper.contentSize.width) / 2.0
        
        let centerY = max(scrollWrapper.frame.height, scrollWrapper.contentSize.height) / 2.0
        
        imageView.center = CGPoint(x: centerX, y: centerY)
    }
    
    // MARK: UIGesture
    @objc private func oneTap(sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            oneTapClosure?(source, self)
        }
    }
    
    @objc private func doubleTap(sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            // scale
            if scrollWrapper.zoomScale == scrollWrapper.maximumZoomScale {
                scrollWrapper.setZoomScale(scrollWrapper.minimumZoomScale, animated: true)
            }
            else {
                let point = sender.location(in: imageView)
                scrollWrapper.zoom(to: CGRect(x: point.x, y: point.y, width: 1, height: 1), animated: true)
            }
            
            doubleTapClosure?(source, self)
        }
    }
    
    @objc private func longPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            
            longPressClosure?(source, self)
        }
    }
    
    // MARK: private method
    private func initUI() {
        
        scrollWrapper.maximumZoomScale = 1.5
        scrollWrapper.showsVerticalScrollIndicator = false
        scrollWrapper.showsHorizontalScrollIndicator = false
        scrollWrapper.delegate = self
        scrollWrapper.backgroundColor = self.backgroundColor
        scrollWrapper.frame = contentView.bounds
        scrollWrapper.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        contentView.addSubview(scrollWrapper)
        
        //
        imageView.frame = scrollWrapper.bounds
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        scrollWrapper.addSubview(imageView)
        
        //
        progressView.center = CGPoint(x: imageView.bounds.width / 2, y: imageView.bounds.height / 2)
        progressView.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin, .flexibleBottomMargin]
        imageView.addSubview(progressView)
        
        // tap
        let oneTap = UITapGestureRecognizer(target: self, action: #selector(PhotoBrowserCell.oneTap(sender:)))
        oneTap.numberOfTapsRequired = 1
        oneTap.delegate = self
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(PhotoBrowserCell.doubleTap(sender:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(PhotoBrowserCell.longPress(sender:)))
        
        oneTap.require(toFail: doubleTap)
        doubleTap.require(toFail: longPress)
        
        addGestureRecognizer(oneTap)
        addGestureRecognizer(doubleTap)
        addGestureRecognizer(longPress)
    }
    
    // 显示当前源
    private func displaySource() {
        if let _ = source {
            scrollWrapper.maximumZoomScale = 1
            scrollWrapper.minimumZoomScale = 1
            scrollWrapper.zoomScale = 1
            
            progressView.isHidden = false
            
            if let image = source?.image {
                // 隐藏
                progressView.isHidden = true
                
                imageView.image = image
                
                let imageSize = image.size
                
                var imageViewFrame: CGRect = .zero
                imageViewFrame.size = imageSize
                
                scrollWrapper.contentSize = imageSize
                
                imageView.frame = imageViewFrame
                
                setMaxMinScale()
            }
            else if let holder = source?.placeholder {
                imageView.image = holder
                imageView.frame = scrollWrapper.bounds
                scrollWrapper.contentSize = scrollWrapper.bounds.size
            }
        }
        
        layoutIfNeeded()
    }
    
    private func setMaxMinScale() {
        if let image = source?.image {
            let imageSize = image.size
            
            let xScale = scrollWrapper.bounds.width / imageSize.width
            let yScale = scrollWrapper.bounds.height / imageSize.height
            
            let minScale = min(xScale, yScale)
            
            let maxScale = max(yScale, 2 * minScale)
            
            // caculate fullScreen scale
            let fullScreenScale = scrollWrapper.bounds.width / imageSize.width
            
            scrollWrapper.minimumZoomScale = minScale
            scrollWrapper.maximumZoomScale = maxScale
            
            scrollWrapper.zoomScale = fullScreenScale
            
            // 如果是高图，默认置顶
            scrollWrapper.contentOffset = .zero
            
            // reset position
            imageView.frame.origin.x = 0
            imageView.frame.origin.y = 0
            
            setNeedsLayout()
        }
    }
}
