//
//  Gat+Segue.swift
//  gat
//
//  Created by HungTran on 6/12/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation

extension Gat {
    /**Segue: Lưu các segue identifier*/
    struct Segue {
        
        //MARK: - ForgotPassword.storyboard
        static let openEnterNewPassword = "open_enter_new_password"
        static let openConfirmPassword = "open_confirm_password"
        static let openForgetPassword = "open_forget_password"
        
        /**Điều hướng tới màn nhập mật khẩu mới sau khi đã xác thực xong với Social*/
        static let openSetNewPasswordBySocial = "open_set_new_password_from_social"
        static let openReceiveBookLocation = "open_receive_book_location"
        
        static let openRegisterView = "open_register_view"
        static let openLoginView = "open_login_view"
        static let openBookDetail = "showBookDetail"
        
        static let closeTableFilter = "close_table_filter"
        static let openFavoriteCategory = "open_favorite_category"
        static let openVisitorPage = "open_visitor_page"
        
        //MARK: - Setting
        static let openAddEmailPassword = "open_add_email_password"
        static let openEditUserInfo = "open_edit_user_info"
        static let openChangePassword = "open_change_password"
        static let openSocialNetworkSetting = "open_socialnetwork_setting_view"
        
        static let openRequestDetailOwner = "open_request_detail_o"
        static let openRequestDetailBorrower = "open_request_detail_s"
        
        //MẢK: - Filter Data
        static let openLendingBookFilter = "open_lending_book_filter"
        static let openReadingBookFilter = "open_reading_book_filter"
        static let openBorrowingBookRequestFilter = "open_borrowing_book_request_filter"
        
        static let SHOW_BOOK_DETAIL_IDENTIFIER = "showBookDetail"
        static let FILTER_SUGGESTION_IDENTIFIER = "showFilterSuggestion"
        static let NEARBY_USER_IDENTIFIER = "pushNearByUser"
        static let SHOW_USERPAGE_IDENTIFIER = "showUserPage"
        static let SHOW_SEARCH_IDENTIFIER = "showSearch"
        static let SHOW_SEARCH_BOOK_IDENTIFIER = "showSearchBook"
        static let SHOW_SEARCH_AUTHOR_IDENTIFIER = "showSearchAuthor"
        static let SHOW_SEARCH_USER_IDENTIFIER = "showSearchUser"
        static let SHOW_BOOKSTOP_IDENTIFIER = "showBookStop"
        static let BACK_HOME_IDENTIFIER = "backHomeUnwind"
        static let SHOW_ADD_IDENTIFIER = "showAdd"
        static let SHOW_STATUS_BOOK_IDENTIFIER = "showStatusBook"
        static let SHOW_LIST_IDENTIFIER = "showList"
        static let SHOW_COMMENT_IDENTIFIER = "showComment"
        static let UNWIND_STATUS_IDENTIFIER = "unwindStatus"
        static let UNWIND_COMMENT_IDENTIFIER = "unwindComment"
        static let UNWIND_ADD_IDENTIFIER = "unwindAdd"
        static let BOOK_DETAIL_IDENTIFIER = "bookDetail"
        static let COMMENT_IDENTIFIER = "comment"
        static let DETAIL_COMMENT_IDENTIFIER = "detailComment"
        static let SHOW_REQUEST_DETAIL_S_IDENTIFIER = "showRequestDetail_S"
        static let SHOW_REQUEST_DETAIL_O_IDENTIFIER = "showRequestDetail_O"
        static let SHOW_BARCODE_IDENTIFIER = "showBarCode"
        static let SHOW_GROUP_MESSAGES_IDENTIFIER = "showGroupMessage"
        static let SHOW_MESSAGE_IDENTIFIER = "showMessage"
        static let SHOW_REQUEST_DETAIL_BORROWER_INDETIFIER = "showRequestDetailBorrower"
        static let SHOW_GROUP_MESSAGE_IDENTIFIER = "showGroupMessage"
        static let SHOW_BOOK_LOAN_IDENTIFIER = "showBookLoan"
        static let SHOW_MAP_LOCATION_IDENTIFIER = "showMapCurrentLocation"
        static let SHOW_FAVOURITE_CATEGORY_IDENTIFIER = "showFavouriteCategory"
    }
}
