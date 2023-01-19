//
//  Exploration.swift
//  gat
//
//  Created by Vũ Kiên on 05/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation

enum Exploration {
    
    case GAT
    case profile
    case bookstop
    case social
    case draftPost
    case createPost
    case item(Bookstop)
    
    var image: UIImage {
        switch self {
        case .profile:
            return #imageLiteral(resourceName: "21207Path5Path7Mask")
        case .bookstop:
            return #imageLiteral(resourceName: "2136802")
        case .social:
            return #imageLiteral(resourceName: "2136802Copy")
        case .item( _):
            return #imageLiteral(resourceName: "group11")
        case .GAT:
            return #imageLiteral(resourceName: "maskGroup")
        case .draftPost:
            return UIImage.init(named: "draftPost")!
        case .createPost:
            return UIImage.init(named: "createPost")!
        }
    }
    
    var icon: UIImage {
        switch self {
        case .profile: return #imageLiteral(resourceName: "profile_explore")
        case .bookstop: return #imageLiteral(resourceName: "bookstop_organization_explore")
        case .social: return #imageLiteral(resourceName: "social_explore")
        case .item(_): return #imageLiteral(resourceName: "group8")
        case .GAT: return UIImage()
        case .draftPost: return UIImage()
        case .createPost:
            return UIImage()
        }
    }
    
    var title: String {
        switch self {
        case .profile:
            return Gat.Text.Home.PROFILE_EXPLORATION.localized()
        case .bookstop:
            return Gat.Text.Home.BOOKSTOP_EXPLORATION.localized()
        case .social:
            return Gat.Text.Home.FAN_PAGE_EXPLORATION.localized()
        case .item(let bookstop): return bookstop.profile!.name
        case .GAT:
            return "JOIN_TRAM_GAT".localized()
        case .draftPost: return "DRAFT_POST_TITLE".localized()
        case .createPost:
            return "CREATE_ARTICLES_TITLE".localized()
        }
    }
    
}
