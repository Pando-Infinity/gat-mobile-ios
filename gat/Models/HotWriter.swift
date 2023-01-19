//
//  HotWriter.swift
//  gat
//
//  Created by macOS on 11/6/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation

class HotWriter {
    var profile:Profile
    var articles: [Post]
    
    init(profile:Profile, articles:[Post]){
        self.profile = profile
        self.articles = articles
    }
}
