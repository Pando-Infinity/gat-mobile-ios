//
//  Gat+Storyboard.swift
//  gat
//
//  Created by HungTran on 6/12/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation

extension Gat {
    /**Storyboard: Lưu tên của storyboard*/
    struct Storyboard {
        // MARK: - Views
        static let Main = "Main"
        
        // MARK: - Views/AuthenticationView
        static let Login = "Login"
        static let Register = "Register"
        static let Message = "Message"
        
        //MARK: - Maps
        static let MapUserCurrentLocation = "MapUserCurrentLocation"
        
        static let PERSON = "PersonalProfile"
        static let BARCODE = "Barcode"
        static let MESSAGE = "Message"
        static let REQUEST_DETAIL_O = "RequestDetail_O"
        static let REQUEST_DETAIL_S = "RequestDetail_S"
        static let NEARBY_USER = "NearByUser"
        static let ALERT = "Alert"
        static let POPUP = "PopupSecond"
        static let CURRENT_MAP = "MapUserCurrentLocation"
        static let USER_FAVOURITE_CATEGORY = "UserFavoriteCategory"
        static let BOOK_DETAIL = "BookDetail"
    }
}
