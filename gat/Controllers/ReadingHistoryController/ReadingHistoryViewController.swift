//
//  ReadingHistoryViewController.swift
//  gat
//
//  Created by jujien on 1/9/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import HMSegmentedControl
import RxSwift
import RxCocoa

class ReadingHistoryViewController: BaseViewController {
    
    class var segueIdentifier: String { return "showReadingHistory" }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    
    fileprivate let readings: BehaviorRelay<[Reading]> = .init(value: [])
    fileprivate var status: SearchState = .new
    
    private var page: Int = 1
    private var canLoadMore: Bool = true
    
    private var viewModelReadings: ReadingHistoryViewModel!
    
    private let loadData = PublishSubject<UserReadingPut>()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.text = "READING_HISTORY_TITLE".localized()
        // Init collection
        self.setupCollectionView()
        
        // Init ViewModel
        self.bindViewModel()
        
        // Set on detect event bus
//        self.onAddBookToReadingEvent()
        self.openBookDetailEvent()
        self.updateReadingEvent()
        self.event()
    }
    
    private func bindViewModel() {
        let useCase = Application.shared.networkUseCaseProvider
        viewModelReadings = ReadingHistoryViewModel(useCaseReadings: useCase.makeReadingsUseCase())
        let input = ReadingHistoryViewModel.Input(
            loadTrigger: loadData
        )
        let output = viewModelReadings.transform(input)
        
        output.readings.subscribe(onNext: { result in
            print("Mapped Sequence: \(result.readings?.count)")
            if let it = result.readings, it.count > 0 {
                self.readings.accept(self.readings.value + it)
            } else {
                self.canLoadMore = false
            }
        }).disposed(by: disposeBag)
        
        output.error
            .drive(rx.error)
            .disposed(by: disposeBag)
        
        output.indicator
        .drive(rx.isLoading)
        .disposed(by: disposeBag)
        
        loadData.onNext(UserReadingPut(readingStatus: Reading.ReadingStatus.all, pageNum: page, pageSize: 10))
    }
    
    fileprivate func setupCollectionView() {
        self.collectionView.register(UINib(nibName: ReadingBookCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: ReadingBookCollectionViewCell.identifier)
        let sizeCell = CGSize.init(width: UIScreen.main.bounds.width, height: 95.0)
        if let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.sectionInset = .zero
            layout.itemSize = sizeCell
            layout.minimumLineSpacing = .zero
            layout.minimumInteritemSpacing = .zero
        }
        
        self.collectionView.rx.itemSelected.withLatestFrom(self.readings.asObservable()) { (indexPath, items) -> Reading in
            return items[indexPath.row]
        }
        .subscribe(onNext: { [weak self] (readingBook) in
            self?.openReadingProgessPopup(readingBook.edition?.editionId ?? 0, readingBook.readingId, readingBook.pageNum, readingBook.readPage, readingBook.startDate, readingBook.completeDate, readingBook.edition?.title ?? "", readingBook.readingStatusId)
        }).disposed(by: self.disposeBag)
        
        self.readings
            .bind(to: self.collectionView.rx.items(cellIdentifier: ReadingBookCollectionViewCell.identifier, cellType: ReadingBookCollectionViewCell.self)) { (index, reading, cell) in
                cell.readingBook.accept(reading)
                cell.sizeCell.accept(sizeCell)
            }
            .disposed(by: self.disposeBag)
        
        
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.backEvent()
        self.loadmoreEvent()
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier ==  ReadingBookDetailViewController.segueIdentifier {
            let vc = segue.destination as! ReadingBookDetailViewController
            vc.readingDetail = ReadingBookDetailViewModel(reading: sender as! ReadingBook)
        } else if segue.identifier == Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER {
            let vc = segue.destination as? BookDetailViewController
            vc?.bookInfo.onNext(sender as! BookInfo)
        }
    }
    
    fileprivate func backEvent() {
        self.backButton.rx.tap.asObservable().subscribe(onNext: { [weak self] (_) in
            self?.navigationController?.popViewController(animated: true)
            //self?.dismiss(animated: true, completion: nil)
        }).disposed(by: self.disposeBag)
    }
    
//    private func onAddBookToReadingEvent() {
//        SwiftEventBus.onMainThread(
//            self,
//            name: AddBookToReadingEvent.EVENT_NAME
//        ) { result in
//            print("Received event ")
//            let data : AddBookToReadingEvent? = result?.object as? AddBookToReadingEvent
//            if let it = data {
//                self.openReadingProgessPopup(
//                    it.bookId, it.readingId,
//                    it.numPage, it.currentPage,
//                    it.startDate, it.completeDate,
//                    it.bookName, 1
//                )
//            }
//        }
//    }
    
    private func openReadingProgessPopup(
        _ editionId: Int,
        _ readingId: Int?,
        _ numPage: Int,
        _ curentPage: Int,
        _ startDate: String,
        _ completeDate: String,
        _ bookTitle: String,
        _ readingStatusId: Int) {
        if readingStatusId == 1 {
            guard let popupVC = self.getViewControllerFromStorybroad(
                       storybroadName: "ReadingProcessView",
                       identifier: "ReadingProcessVC"
                   ) as? ReadingProcessVC else { return }
                   //popupVC.readingBook = self.viewModel.reading(index: row)
                   popupVC.editionId = editionId
                   popupVC.readingId = readingId
                   popupVC.maxSlider = numPage
                   popupVC.current = curentPage
                   popupVC.startDate = startDate
                   popupVC.completeDate = completeDate
                   popupVC.bookTitle = bookTitle
                   popupVC.delegate = self
                   let navigation = PopupNavigationController(rootViewController: popupVC)
                   navigation.navigationBar.isHidden = true
                   present(navigation, animated: true, completion: nil)
        } else {
             guard let popupVC = self.getViewControllerFromStorybroad(
                 storybroadName: "ReadingProcessView",
                 identifier: ReviewProcessViewController.className
             ) as? ReviewProcessViewController else { return }
            let book = BookInfo()
            book.editionId = editionId
            book.title = bookTitle
            popupVC.book.accept(book)
            popupVC.delegate = self
            let navigation = PopupNavigationController(rootViewController: popupVC)
            navigation.navigationBar.isHidden = true
            present(navigation, animated: true, completion: nil)
        }
    }
    
    private func openBookDetailEvent() {
        SwiftEventBus.onMainThread(
            self,
            name: OpenBookDetailEvent.EVENT_NAME
        ) { result in
            print("Received event ")
            let data : OpenBookDetailEvent? = result?.object as? OpenBookDetailEvent
            if let it = data {
                self.performSegue(withIdentifier: Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER, sender: it.bookInfo)
            }
        }
    }
    
    private func updateReadingEvent() {
        SwiftEventBus.onMainThread(
            self,
            name: UpdateReadingEvent.EVENT_NAME
        ) { result in
            print("Received event update data in UpdateReadingListViewController")
            if self.page > 1 {
                self.page = 1
            }
            self.readings.accept([])
            let useCase = Application.shared.networkUseCaseProvider
            self.viewModelReadings = ReadingHistoryViewModel(useCaseReadings: useCase.makeReadingsUseCase())
            let input = ReadingHistoryViewModel.Input(
                loadTrigger: self.loadData
            )
            let output = self.viewModelReadings.transform(input)

            output.readings.subscribe(onNext: { result in
                print("Mapped Sequence: \(result.readings?.count)")
                if let it = result.readings, it.count > 0 {
                    self.readings.accept(self.readings.value)
                } else {
                    self.canLoadMore = false
                }
            }).disposed(by: self.disposeBag)

            output.error
                .drive(self.rx.error)
                .disposed(by: self.disposeBag)

            output.indicator
                .drive(self.rx.isLoading)
                .disposed(by: self.disposeBag)

            self.loadData.onNext(UserReadingPut(readingStatus: Reading.ReadingStatus.all, pageNum: self.page, pageSize: 10))
        }
    }

    private func loadmoreEvent() {
        self.collectionView.rx.willBeginDecelerating.asObservable().compactMap { [weak self] _ in self?.collectionView }
            .filter({ (collectionView) -> Bool in
                return collectionView.contentOffset.y >= (collectionView.contentSize.height - collectionView.frame.height)
            })
            .filter({ (collectionView) -> Bool in
                let translation = collectionView.panGestureRecognizer.translation(in: collectionView.superview)
                return translation.y < -70.0
            })
        .subscribe(onNext: { [weak self] (_) in
            // call api this here
                self?.page += 1
                self?.loadData.onNext(UserReadingPut(readingStatus: Reading.ReadingStatus.all, pageNum: self?.page ?? 1, pageSize: 10))
        }).disposed(by: self.disposeBag)
    }

}

extension ReadingHistoryViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension ReadingHistoryViewController: ReadingProcessDelegate {
    func readingProcess(readingProcess: ReviewProcessViewController, open post: Post) {
        readingProcess.navigationController?.dismiss(animated: true, completion: nil)
        let step = StepCreateArticleViewController()

        let storyboard = UIStoryboard(name: "CreateArticle", bundle: nil)
        let createArticle = storyboard.instantiateViewController(withIdentifier: CreatePostViewController.className) as! CreatePostViewController
        createArticle.presenter = SimpleCreatePostPresenter(post: post, imageUsecase: DefaultImageUsecase(), router: SimpleCreatePostRouter(viewController: createArticle, provider: step))
        step.add(step: .init(controller: createArticle, direction: .forward))
        self.navigationController?.pushViewController(step, animated: true)
    }
    
    func update(post: Post) {}
}
