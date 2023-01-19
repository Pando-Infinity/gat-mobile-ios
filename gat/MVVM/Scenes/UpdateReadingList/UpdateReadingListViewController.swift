//
//  UpdateReadingListViewController.swift
//  gat
//
//  Created by jujien on 1/17/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources
import RxCocoa

class UpdateReadingListViewController: BaseViewController {
    
    class var segueIdentifier: String { return "showUpdateReadingList" }
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var searchButton: UIButton!
    
    private var viewModelReadings: UpdateReadingsViewModel!
    fileprivate var datasource: RxCollectionViewSectionedReloadDataSource<SectionModel<String, Any>>!
    
    private var booksNum: Int = 0
    private var page: Int = 1
    private var canLoadMore: Bool = true
    private let useCase = Application.shared.networkUseCaseProvider
    private var input: UpdateReadingsViewModel.Input!
    private var output: UpdateReadingsViewModel.Output!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Init ViewModel
        viewModelReadings = UpdateReadingsViewModel(
            useCaseBooks: useCase.makeBooksUseCase(),
            useCaseReadings: useCase.makeReadingsUseCase())
        
        self.loadData()
        self.bindViewModel()
        
        self.setupUI()
        self.event()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set on event bus listener
        self.onAddBookToReadingEvent()
        self.updateReadingEvent()
        self.onOpenSearchBookEvent()
        self.openBookDetailEvent()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        SwiftEventBus.unregister(self)
    }
    
    private func loadData() {
        input = UpdateReadingsViewModel.Input(pageBooks: page)
        output = viewModelReadings.transform(input)
    }
    
    private func bindViewModel() {
        viewModelReadings.canLoadMore.subscribe(onNext: {
            print($0)
            self.canLoadMore = $0
        }).disposed(by: disposeBag)
        
        output.error
            .drive(rx.error)
            .disposed(by: disposeBag)
        
        output.indicator
        .drive(rx.isLoading)
        .disposed(by: disposeBag)
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.titleLabel.text = "UPDATE_READING_LIST".localized()
        self.setupCollectionView()
    }
    
    fileprivate func setupCollectionView() {
        self.registerCell()
        self.collectionView.delegate = self
        self.datasource = .init(configureCell: { [weak self] (datasource, collectionView, indexPath, element) -> UICollectionViewCell in
            //var cell: UICollectionViewCell? = nil
            guard let size = self?.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: indexPath) else { fatalError() }
            if let value = element as? Int, value == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EmptyReadingCollectionViewCell.identifier, for: indexPath) as! EmptyReadingCollectionViewCell
                cell.sizeCell.accept(size)
                return cell
            } else if let reading = element as? Reading {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReadingBookCollectionViewCell.identifier, for: indexPath) as! ReadingBookCollectionViewCell
                cell.sizeCell.accept(size)
                cell.readingBook.accept(reading)
                return cell
            } else if let book = element as? Book {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BookSuggestReadingCollectionViewCell.identifier, for: indexPath) as! BookSuggestReadingCollectionViewCell
                cell.book.accept(book)
                cell.sizeCell.accept(size)
                return cell
            }
            fatalError()
            //return cell!
        }, configureSupplementaryView: { [weak self] (datasource, collectionView, kind, indexPath) -> UICollectionReusableView in
            guard let action = self?.viewModelReadings.action.value else { fatalError() }
            if kind == UICollectionView.elementKindSectionHeader {
                let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HeaderReadingListCollectionReusableView.identifier, for: indexPath) as! HeaderReadingListCollectionReusableView
                view.seperateView.isHidden = indexPath.section == 0
                view.titleLabel.text = datasource[indexPath.section].identity
                view.descriptionLabel.text = indexPath.section == 0 ? String(format: "TOTAL_READING_BOOK".localized(), self?.viewModelReadings.numberReadingBook ?? 0) : ""
                view.descriptionLabel.isHidden = datasource[indexPath.section].items.isEmpty
                return view
            } else if kind == UICollectionView.elementKindSectionFooter {
                let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: FooterReadingListCollectionReusableView.identifier, for: indexPath) as! FooterReadingListCollectionReusableView
                switch action {
                case .collapse:
                    view.titleLabel.text = "SHOW_MORE".localized()
                    view.imageView.image = #imageLiteral(resourceName: "down")
                case .expand:
                    view.titleLabel.text = "SHOW_LESS".localized()
                    view.imageView.image = #imageLiteral(resourceName: "up")
                }
                view.actionHandle = self?.viewModelReadings.toggleAction
                return view
            }
            fatalError()
        })
        self.viewModelReadings.items.bind(to: self.collectionView.rx.items(dataSource: self.datasource)).disposed(by: self.disposeBag)
    }
    
    fileprivate func registerCell() {
        self.collectionView.register(UINib(nibName: ReadingBookCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: ReadingBookCollectionViewCell.identifier)
        self.collectionView.register(UINib.init(nibName: BookSuggestReadingCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: BookSuggestReadingCollectionViewCell.identifier)
    }
    
    //MARK: - Event
    fileprivate func event() {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.backButton.rx.tap.asObservable().subscribe(onNext: { [weak self] (_) in
            self?.navigationController?.popViewController(animated: true)
        }).disposed(by: self.disposeBag)
        self.searchButton.rx.tap.asObservable().subscribe(onNext: { [weak self] (_) in
            self?.performSegue(withIdentifier: SearchBookReadingViewController.segueIdentifier, sender: nil)
        }).disposed(by: self.disposeBag)
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

    private func onAddBookToReadingEvent() {
        self.collectionView.rx.itemSelected.withLatestFrom(self.viewModelReadings.items.asObservable()) { (indexPath, items) -> Reading? in
            return items[indexPath.section].items[indexPath.row] as? Reading
        }.compactMap { $0 }
            .subscribe(onNext: { [weak self] (readingBook) in
                self?.openReadingProgessPopup(readingBook.edition?.editionId ?? 0, readingBook.readingId, readingBook.pageNum, readingBook.readPage, readingBook.startDate, readingBook.completeDate, readingBook.edition?.title ?? "", readingBook.readingStatusId)
            }).disposed(by: self.disposeBag)
        
        SwiftEventBus.onMainThread(
            self,
            name: AddBookToReadingEvent.EVENT_NAME
        ) { result in
            print("Received event ")
            let data : AddBookToReadingEvent? = result?.object as? AddBookToReadingEvent
            if let it = data {
                self.openReadingProgessPopup(
                    it.bookId, it.readingId,
                    it.numPage, it.currentPage,
                    it.startDate, it.completeDate,
                    it.bookName, it.readingStatusId
                )
            }
        }
    }
    
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
            self.loadData()
        }
    }
    
    private func onOpenSearchBookEvent() {
        SwiftEventBus.onMainThread(self, name: OpenSearchBookEvent.EVENT_NAME) { result in
            print("Can receive event onOpenSearchBookEvent")
            self.performSegue(withIdentifier: SearchBookReadingViewController.segueIdentifier, sender: nil)
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
            if self!.canLoadMore {
                self?.page += 1
                self?.loadData()
            }
        }).disposed(by: self.disposeBag)
    }
}

extension UpdateReadingListViewController: ReadingProcessDelegate {
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

extension UpdateReadingListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 {
            if self.viewModelReadings.numberReadingBook == 0 {
                return EmptyReadingCollectionViewCell.size(in: collectionView)
            } else {
                return .init(width: collectionView.frame.width, height: 95.0)
            }
        } else {
            return .init(width: collectionView.frame.width, height: 85.0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0 {
            return .init(width: collectionView.frame.width, height: 58.0)
        } else {
            return .init(width: collectionView.frame.width, height: 62.0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if section == 0 {
            if self.viewModelReadings.numberReadingBook <= 3 {
                return .zero
            } else {
                return .init(width: collectionView.frame.width, height: 48.0)
            }
        } else {
            return .zero
        }
    }
}

extension UpdateReadingListViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
