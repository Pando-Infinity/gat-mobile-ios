//
//  GaT+Image.swift
//  gat
//
//  Created by HungTran on 6/12/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation

extension Gat {
    /**Image: Lưu ảnh của App*/
    struct Image {
        // MARK: - Default Image
        static let defaultUserAvatar = #imageLiteral(resourceName: "default_user_avatar")
        static let defaultBookCover = #imageLiteral(resourceName: "default_book_cover")
        
        // MARK: - Gif
        static let gifLoading = "loading"
        
        // MARK: - Icon
        static let iconMapMarker = #imageLiteral(resourceName: "IconCurrentLocation")
        static let iconWhiteCheck = #imageLiteral(resourceName: "IconSmallWhiteCheck")
        static let iconWhiteCancel = #imageLiteral(resourceName: "IconSmallWhiteCancel")
        static let iconGrayEmail = #imageLiteral(resourceName: "email_gray-icon")
        static let iconGrayUser = #imageLiteral(resourceName: "user-icon")
        static let iconGrayLock = #imageLiteral(resourceName: "lock-icon")
        static let iconFacebookHighlight = #imageLiteral(resourceName: "facebook_highlight-icon")
        static let iconFacebookGray = #imageLiteral(resourceName: "facebook_gray-icon")
        static let iconTwitterHighlight = #imageLiteral(resourceName: "twitter_highlight-icon")
        static let iconTwitterGray = #imageLiteral(resourceName: "twitter_gray-icon")
        static let iconGoogleHighlight = #imageLiteral(resourceName: "gplus_highlight-icon")
        static let iconGoogleGray = #imageLiteral(resourceName: "gplus_gray-icon")
        static let iconLogoutGray = #imageLiteral(resourceName: "logout-icon")
        static let iconCheckDisabled = #imageLiteral(resourceName: "IconCheck_Disabled")
        static let iconCheckEnabled = #imageLiteral(resourceName: "IconCheck_Enabled")
        
        static let MARKER_USER_ICON = #imageLiteral(resourceName: "markeruser-icon")
    }
}
