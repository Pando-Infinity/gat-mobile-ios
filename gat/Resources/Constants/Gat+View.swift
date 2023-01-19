//
//  Gat+View.swift
//  gat
//
//  Created by HungTran on 6/15/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation

extension Gat {
    /**Storyboard: Lưu Id của các ViewController con trong Storyboard*/
    struct View {
        static let LoginNavigationController = "LoginNavigationController"
        static let RegisterNavigationController = "RegisterNavigationController"
        static let HomeNavigationController = "Home"
        static let MapViewController = "Register_SelectLocationView"
        
        // MARK: - View
        static let CarouselItemUIView = "CarouselItemUIView"
        static let MessageViewController = "MessageViewController"
        
        static let SHARE_TABLE_CELL =  "ShareTableViewCell"
        static let BOOK_TABLE_CELL = "BookTableViewCell"
        static let HEADER = "HeaderSearch"
        static let USER_COLLECTION_CELL = "UserCollectionViewCell"
        static let PERSON_CONTROLLER = "PersonController"
        static let BARCODE_CONTROLLER = "Barcode"
        static let MAP = "MapView"
        static let RESULT_SEARCH_TABLE_CELL = "ResultTableViewCell"
        static let HISTORY_SEARCH_TABLE_CELL = "HistoryTableViewCell"
        static let BOOK_COLLECTION = "BookCollectionViewCell"
        static let ALERT = "AlertView"
        static let LIST_MESSAGE_CONTROLLER = "ListMessageViewController"
        static let REQUEST_DETAIL_O_CONTROLLER = "request_detail_o"
        static let REQUEST_DETAIL_S_CONTROLLER = "request_detail_s"
        static let NEARBY_USER_CONTROLLER = "NearByUserController"
        static let ALERT_CUSTOM_CONTROLLER = "AlertCustomViewController"
        static let CONNECT_POPUP_CONTROLLER = "ConnectPopupViewController"
        static let EZ_TAB_ITEM = "EZTabItemView"
        static let REGISTER_SELECT_LOCATION_CONTROLLER = "Register_SelectLocationView"
        static let FAVOURITE_CATEGORY_CONTROLLER = "FavoriteCategoryViewController"
        static let BOOKDETAIL = "BookDetailView"
        static let BOOKDETAIL_CONTROLLER = "BookDetailViewController"
        static let REVIEW = "ReviewView"
    }
}
