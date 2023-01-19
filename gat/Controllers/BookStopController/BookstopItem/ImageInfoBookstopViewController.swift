//
//  ImageInfoBookstopViewController.swift
//  gat
//
//  Created by Vũ Kiên on 29/09/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ImageInfoBookstopViewController: UIViewController {
    
    @IBOutlet weak var bookstopImageView: UIImageView!
    @IBOutlet weak var nameBookstopLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var bigImageCollectionView: UICollectionView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var smallImageCollectionView: UICollectionView!
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    let selected: BehaviorSubject<BookstopImage> = .init(value: BookstopImage())
    let bookstop: BehaviorSubject<Bookstop> = .init(value: Bookstop())
    fileprivate let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.setupUI()
        self.event()
    }
    
    //MARK: - UI
    fileprivate func setupUI() {
        self.bookstop
            .map { $0.images.count }
            .subscribe(onNext: { [weak self] (total) in
                self?.pageControl.numberOfPages = total
            })
            .disposed(by: self.disposeBag)
        self.setupImage()
        self.setupBigImageCollectionView()
        self.setupSmallImageCollectionView()
    }
    
    fileprivate func setupImage() {
        self.bookstop
            .subscribe(onNext: { [weak self] (bookstop) in
                self?.view.layoutIfNeeded()
                self?.bookstopImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: bookstop.profile!.imageId, size: .b))!, placeholderImage: DEFAULT_USER_ICON)
                self?.bookstopImageView.circleCorner()
                self?.bookstopImageView.layer.borderColor = #colorLiteral(red: 0.8117647059, green: 0.9333333333, blue: 1, alpha: 1)
                self?.bookstopImageView.layer.borderWidth = 1.5
                self?.nameBookstopLabel.text = bookstop.profile?.name
            })
            .disposed(by: self.disposeBag)
        
    }
    
    fileprivate func setupBigImageCollectionView() {
        self.bookstop
            .map { $0.images }
            .bind(to: self.bigImageCollectionView.rx.items(cellIdentifier: "imageCollectionCell", cellType: ImageCollectionViewCell.self))
            { [weak self] (row, image, cell) in
                cell.imageView.sd_setImage(with: URL(string: image.url))
                self?.descriptionLabel.text = image.caption
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupSmallImageCollectionView() {
        self.bookstop
            .map { $0.images }
            .bind(to: self.smallImageCollectionView.rx.items(cellIdentifier: "imageCollectionCell", cellType: ImageCollectionViewCell.self))
            { (row, image, cell) in
                cell.imageView.sd_setImage(with: URL(string: image.url))
            }
            .disposed(by: self.disposeBag)
    }
    
    //MARK: - Event
    fileprivate func event() {
        self.backEvent()
        self.smallCollectionViewEvent()
        self.scrollToImage()
    }
    
    fileprivate func backEvent() {
        self.backButton
            .rx
            .controlEvent(.touchUpInside)
            .bind { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func scrollToImage() {
        Observable<(BookstopImage, [BookstopImage])>
            .combineLatest(self.selected, self.bookstop.map { $0.images }, resultSelector: { ($0, $1) })
            .map { (selected, images) -> Int? in
                return images.index(where: { $0 === selected})
            }
            .filter { $0 != nil }
            .map { $0! }
            .do(onNext: { [weak self] (index) in
                self?.bigImageCollectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: false)
            })
            .subscribe(self.pageControl.rx.currentPage)
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func smallCollectionViewEvent() {
        self.smallImageCollectionView
            .rx
            .modelDeselected(BookstopImage.self)
            .subscribe(self.selected)
            .disposed(by: self.disposeBag)
    }
}

extension ImageInfoBookstopViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let row = collectionView.indexPathsForVisibleItems.first?.row else {
            return
        }
        self.pageControl.currentPage = row
    }
}

extension ImageInfoBookstopViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView.tag == 100 {
            return collectionView.frame.size
        } else {
            return CGSize(width: 47 * collectionView.frame.width / 150, height: 47 * collectionView.frame.width / 150)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if collectionView.tag == 100 {
            return UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        } else {
            return UIEdgeInsets(top: 15.0, left: 15.0, bottom: 15.0, right: 15.0)
        }
    }
}
