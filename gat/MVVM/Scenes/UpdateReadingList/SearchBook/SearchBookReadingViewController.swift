//
//  SearchBookReadingViewController.swift
//  gat
//
//  Created by jujien on 1/17/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SearchBookReadingViewController: BaseViewController {
    
    class var segueIdentifier: String { return "showSearchBookReading" }
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    private let searchBooks = PublishSubject<String>()
    
    private var viewModelSearch: SearchBookViewModel!
    private var books: [Book] = []
    // Use this variable to block call API during get data
    private var canSearch: Bool = true
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.searchBar.becomeFirstResponder()
        
        // Init View
        self.setupCollectionView()
        self.searchBar.placeholder = Gat.Text.SEARCH_PLACEHOLDER.localized()
        
        // Init ViewModel
        self.bindViewModel()
        
        //setOnSeach
        self.searchBar.delegate = self
        
        self.searchBar.rx.cancelButtonClicked.asObservable().subscribe(onNext: { [weak self] (_) in
            self?.navigationController?.popViewController(animated: true)
        }).disposed(by: self.disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set on event bus listener
        self.onAddBookToReadingEvent()
        self.openBookDetailEvent()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        SwiftEventBus.unregister(self)
    }
    
    // MARK: - UI
    fileprivate func setupCollectionView() {
        self.collectionView.register(UINib.init(nibName: BookSuggestReadingCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: BookSuggestReadingCollectionViewCell.identifier)
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
    }
    
    private func bindViewModel() {
        let useCase = Application.shared.networkUseCaseProvider
        viewModelSearch = SearchBookViewModel(useCaseSearch: useCase.makeSearchBooksUseCase())
        let input = SearchBookViewModel.Input(searchBooks: searchBooks)
        let output = viewModelSearch.transform(input)
        
        output.books.subscribe(onNext: { result in
            print("can get réult search")
            self.canSearch = true
            guard let it = result.books else { return }
            print("can get size: \(it.count)")
            self.books = it
            self.collectionView.reloadData()
        }).disposed(by: disposeBag)
        
        output.error
        .drive(rx.error)
        .disposed(by: disposeBag)
    }
    
    private var booksBinding: Binder<SearchBookResponse> {
        return Binder(self, binding: { (vc, result) in
            self.canSearch = true
            guard let it = result.books else { return }
            self.books = it
            self.collectionView.reloadData()
        })
    }
    
    private func onAddBookToReadingEvent() {
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
                    it.startDate, it.completeDate
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
        _ completeDate: String) {
        
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
        popupVC.delegate = self
        let navigation = PopupNavigationController(rootViewController: popupVC)
        navigation.navigationBar.isHidden = true
        present(navigation, animated: true, completion: nil)
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
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER {
            let vc = segue.destination as? BookDetailViewController
            vc?.bookInfo.onNext(sender as! BookInfo)
        }
    }
}

extension SearchBookReadingViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.books.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BookSuggestReadingCollectionViewCell.identifier, for: indexPath) as! BookSuggestReadingCollectionViewCell
        if !books.isEmpty && indexPath.row < books.count {
            books[indexPath.row].author = books[indexPath.row].authorName
            (cell as! BookSuggestReadingCollectionViewCell).book.accept(books[indexPath.row])
        }
        cell.sizeCell.accept(self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: indexPath))
        return cell
    }
}

extension SearchBookReadingViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: collectionView.frame.width, height: 85.0)
    }
}

extension SearchBookReadingViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            self.books = []
            self.collectionView.reloadData()
        } else {
            if canSearch {
                print("Keyword search: \(searchText)")
                self.searchBooks.onNext(searchText)
                canSearch = false
            }
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("Keyword click search")
        let keyword = searchBar.text
        guard let it = keyword else { return }
        if !it.isEmpty {
            if canSearch {
                print("Keyword search: \(keyword)")
                self.searchBooks.onNext(keyword!)
                canSearch = false
            }
        }
    }
}

extension SearchBookReadingViewController: ReadingProcessDelegate {
    func update(post: Post) {
    }
    
    func readingProcess(readingProcess: ReviewProcessViewController, open post: Post) {
        readingProcess.navigationController?.dismiss(animated: true, completion: nil)
        let storyboard = UIStoryboard(name: "PostDetail", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: PostDetailViewController.className) as! PostDetailViewController
        vc.presenter = SimplePostDetailPresenter(post: post, imageUsecase: DefaultImageUsecase(), router: SimplePostDetailRouter(viewController: vc))
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
