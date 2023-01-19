//
//  Gat+Color.swift
//  gat
//
//  Created by HungTran on 6/12/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation

extension Gat {
    /**Color: Lưu màu sắc của App*/
    struct Color {
        //MARK: - Common Color
        static let buttonShadow = UIColor("#1e6b93")
        static let userBoldText = UIColor("#5396b9")
        
        //MARK: - Filter Popup Color
        static let filterItemSelected = UIColor("#8ec3df")
        static let filterItemDeselected = UIColor("#d7d7d7")
        static let filterItemTabSelected = UIColor("#ffffff")
        static let filterItemTabDeselected = UIColor("#f1f1f1")
        static let filterItemTabTextSelected = UIColor("#202020")
        static let filterItemTabTextDeselected = UIColor("#919191")
        
        //MARK: - Popup Color
        static let popupShadowBackground = UIColor("#2F4753")
        
        //MARK: - Borrowing Book Request Color
        
        //Action Button (Các nút quyết định trạng thái mượn sách)
        static let requestActionButtonPrimaryActive = UIColor("#5396b9")
        static let requestActionButtonPrimaryNormal = UIColor("#8ec3df")
        static let requestActionButtonSuccessActive = UIColor("#7cc576")
        static let requestActionButtonSuccessNormal = UIColor("#b6edb1")
        static let requestActionButtonErrorActive = UIColor("#ed1c24")
        static let requestActionButtonErrorNormal = UIColor("#ff7f84")
        
        //Check Button (Icon nho nhỏ phía bên trái của Action Button)
        static let requestActionCheckButtonNormal = UIColor("#d7d7d7")
        
        //MARK: - Setting
        static let settingItemTextColor = UIColor("#919191")
        static let settingItemDangerText = UIColor("#ee1414")
        
        //MARK: - User Profile
        static let subTabBarItemSelected = UIColor("#F6F6F6")
        static let subTabBarItemDeselected = UIColor.white
        static let userAvatarBorder = UIColor("#8ec3df")
        
        static let subTabBarSharingBookBadgeItem = UIColor("#7cc576")
        static let subTabBarReadingBookBadgeItem = UIColor("#f69679")
        static let subTabBarBorrowingRequestBadgeItem = UIColor("#8ec3df")
        
        //MARK: - Visitor Page
        static let visitorWaitBorrowing = #colorLiteral(red: 0.4862745098, green: 0.7725490196, blue: 0.462745098, alpha: 1)
        static let visitorBorrowingBook = #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)
    }
}

extension UIColor {
    static let fadedBlue = #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1)
    static let brownGrey = #colorLiteral(red: 0.6078431373, green: 0.6078431373, blue: 0.6078431373, alpha: 1)
    static let brownGreyTwo = #colorLiteral(red: 0.5647058824, green: 0.5647058824, blue: 0.5647058824, alpha: 1)
    static let brownGreyThree = #colorLiteral(red: 0.5921568627, green: 0.5921568627, blue: 0.5921568627, alpha: 1)
    static let iceBlueTwo = #colorLiteral(red: 0.9137254902, green: 0.9490196078, blue: 0.968627451, alpha: 1)
    static let paleBlue = #colorLiteral(red: 0.8823529412, green: 0.8980392157, blue: 0.9019607843, alpha: 1)
    static let paleGrey = #colorLiteral(red: 0.9450980392, green: 0.9607843137, blue: 0.968627451, alpha: 1)
    static let veryLightPink50 = #colorLiteral(red: 0.7647058824, green: 0.7647058824, blue: 0.7647058824, alpha: 1)
    static let veryLightPink18 = #colorLiteral(red: 0.8470588235, green: 0.8470588235, blue: 0.8470588235, alpha: 1)
    static let navy = #colorLiteral(red: 0, green: 0.1019607843, blue: 0.2235294118, alpha: 1)
    static let greyBlue = #colorLiteral(red: 0.4, green: 0.4705882353, blue: 0.5411764706, alpha: 1)
    static let apricot = #colorLiteral(red: 0.9960784314, green: 0.7764705882, blue: 0.4156862745, alpha: 1)
    static let paleBlueTwo = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    static let grapefruit = #colorLiteral(red: 0.9568627451, green: 0.3529411765, blue: 0.3529411765, alpha: 1)
}
