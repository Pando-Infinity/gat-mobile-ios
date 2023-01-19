//
//  NewBookstopTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 22/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

protocol NewBookstopCellDelegate: class {
    func showViewController(identifier: String, sender: Any?)
}

class NewBookstopTableViewCell: UITableViewCell {
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var bookstopImageView: UIImageView!
    @IBOutlet weak var bookstopNameLabel: UILabel!
    @IBOutlet weak var addressNameLabel: UILabel!
    @IBOutlet weak var numberBookLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var aboutLabel: UILabel!
    @IBOutlet weak var imagePageControl: UIPageControl!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var containerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerWidthConstraint: NSLayoutConstraint!
    
    weak var delegate: NewBookstopCellDelegate?
    
    fileprivate var images: [BookstopImage] = []
    fileprivate var currentIndex = 0
    fileprivate let disposeBag = DisposeBag()
    fileprivate var timer: Timer!
    fileprivate var bookstop: Bookstop!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.setupUI()
        self.event()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.setupBox()
        self.setupCollectionView()
    }
    
    fileprivate func setupBox() {
        self.containerView.cornerRadius(radius: 6.0)
        self.containerView.dropShadow(offset: .zero, radius: 6.0, opacity: 0.5, color: #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1))
    }

    func setup(bookstop: Bookstop) {
        self.bookstop = bookstop
        self.layoutIfNeeded()
        self.setupProfile(bookstop.profile!)
        self.setupDistance(bookstop.distance)
        self.setupAbout(bookstop.profile!.about)
        self.setupTotalBook(in: bookstop)
        self.loadImage(in: bookstop)
        self.currentIndex = 0
    }
    
    fileprivate func setupProfile(_ profile: Profile) {
        self.bookstopImageView.sd_setImage(with: URL.init(string: AppConfig.sharedConfig.setUrlImage(id: profile.imageId)), placeholderImage: DEFAULT_USER_ICON)
        self.bookstopImageView.layer.borderColor = #colorLiteral(red: 0.262745098, green: 0.5725490196, blue: 0.7333333333, alpha: 1)
        self.bookstopImageView.layer.borderWidth = 1.0
        self.bookstopImageView.circleCorner()
        self.bookstopNameLabel.text = profile.name
        self.addressNameLabel.text = profile.address
    }
    
    fileprivate func setupAbout(_ about: String) {
        self.aboutLabel.text = about
        self.aboutLabel.adjustsFontSizeToFitWidth = true
    }
    
    fileprivate func setupDistance(_ distance: Double) {
        if distance >= 1000 {
            self.distanceLabel.text = String(format: "%.2f km", distance / 1000)
        } else {
            self.distanceLabel.text = String(format: "%.1f m", distance)
        }
    }
    
    fileprivate func setupTotalBook(in bookstop: Bookstop) {
        if bookstop.profile?.userTypeFlag == .organization {
            self.numberBookLabel.text = "\((bookstop.kind as? BookstopKindOrganization)?.totalEdition ?? 0)"
        } else {
            self.numberBookLabel.text = "\((bookstop.kind as? BookstopKindPulic)?.sharingBook ?? 0)"
        }
    }
    
    fileprivate func loadImage(in bookstop: Bookstop) {
        if bookstop.images.count >= 5 {
            self.images = bookstop.images[0..<5].map { $0 }
        } else {
            self.images = bookstop.images
        }
        
        self.imagePageControl.numberOfPages = self.images.count
        self.collectionView.reloadData()
    }
    
    fileprivate func setupCollectionView() {
        self.registerCell()
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.isUserInteractionEnabled = false
        self.autoChangeImage()
    }
    
    fileprivate func registerCell() {
        let nib = UINib.init(nibName: "ImageCollectionViewCell", bundle: nil)
        self.collectionView.register(nib, forCellWithReuseIdentifier: "imageCollectionCell")
    }
    
    fileprivate func autoChangeImage() {
        self.timer = Timer.scheduledTimer(timeInterval: 4.0, target: self, selector: #selector(timerChange(timer:)), userInfo: self, repeats: true)
    }
    
    fileprivate func animation() {
        self.layoutIfNeeded()
        UIView.animate(withDuration: 0.1, animations: { [weak self] in
            self?.containerWidthConstraint.constant = -3.0
            self?.containerHeightConstraint.constant = -3.0
            self?.layoutIfNeeded()
        }) { [weak self] (completed) in
            guard completed else {
                return
            }
            UIView.animate(withDuration: 0.1, animations: { [ weak self] in
                self?.containerWidthConstraint.constant = 0.0
                self?.containerHeightConstraint.constant = 0.0
                self?.layoutIfNeeded()
            }) { [weak self] (completed) in
                guard let bookstop = self?.bookstop else {
                    return
                }
                if bookstop.profile?.userTypeFlag == .organization {
                    self?.delegate?.showViewController(identifier: "showBookstopOrganization", sender: bookstop)
                } else {
                    self?.delegate?.showViewController(identifier: Gat.Segue.SHOW_BOOKSTOP_IDENTIFIER, sender: bookstop)
                }
            }
        }
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.containerView.rx
            .tapGesture()
            .when(.recognized)
            .bind { [weak self] (_) in
                self?.animation()
            }
            .disposed(by: self.disposeBag)
        
        self.containerView.rx
            .longPressGesture(configuration: { (recognized, _) in
                recognized.minimumPressDuration = 0.1
            })
            .when(.began, .ended)
            .bind { [weak self] (gesture) in
                self?.layoutIfNeeded()
                if gesture.state == .began {
                    UIView.animate(withDuration: 0.1, animations: { [ weak self] in
                        self?.containerWidthConstraint.constant = -3.0
                        self?.containerHeightConstraint.constant = -3.0
                        self?.layoutIfNeeded()
                    })
                } else if gesture.state == .ended {
                    UIView.animate(withDuration: 0.1, animations: { [ weak self] in
                        self?.containerWidthConstraint.constant = 0.0
                        self?.containerHeightConstraint.constant = 0.0
                        self?.layoutIfNeeded()
                    })
                }
            }
            .disposed(by: self.disposeBag)
    }
    
    @objc fileprivate func timerChange(timer: Timer) {
        guard !self.images.isEmpty else {
            return
        }
        if self.currentIndex == self.images.count - 1 {
            self.currentIndex = 0
        } else {
            self.currentIndex += 1
        }
        self.imagePageControl.currentPage = self.currentIndex
        self.collectionView.scrollToItem(at: .init(row: self.currentIndex, section: 0), at: .right, animated: true)
    }
}

extension NewBookstopTableViewCell: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCollectionCell", for: indexPath) as! ImageCollectionViewCell
        cell.imageView.sd_setImage(with: URL(string: self.images[indexPath.row].url))
        return cell
    }
}

extension NewBookstopTableViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
}



