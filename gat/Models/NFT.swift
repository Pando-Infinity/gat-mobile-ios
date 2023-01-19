//
//  NFT.swift
//  gat
//
//  Created by jujien on 07/12/2022.
//  Copyright © 2022 GaTBook. All rights reserved.
//

import Foundation

struct NFT {
    var id: String
    var name: String
    var description: String
    var image: String
    var date: Date
}

extension NFT {
    static let data: [NFT] = [
        .init(id: "12345", name: "PFP NFT Name", description: "Lorem ipsum dolor sit amet consectetur. Dignissim sed at habitant dui quis. Est est tempus in egestas. Tempus mollis tellus blandit aliquet morbi mollis nam eu odio. ", image: "nft_1", date: .init(timeIntervalSince1970: 1669363990)),
        .init(id: "12345", name: "PFP NFT Name", description: "Lorem ipsum dolor sit amet consectetur. Dignissim sed at habitant dui quis. Est est tempus in egestas. Tempus mollis tellus blandit aliquet morbi mollis nam eu odio. ", image: "nft_2", date: .init(timeIntervalSince1970: 1669363990)),
        .init(id: "12345", name: "PFP NFT Name", description: "Lorem ipsum dolor sit amet consectetur. Dignissim sed at habitant dui quis. Est est tempus in egestas. Tempus mollis tellus blandit aliquet morbi mollis nam eu odio. ", image: "nft_3", date: .init(timeIntervalSince1970: 1669363990)),
        .init(id: "12345", name: "PFP NFT Name", description: "Lorem ipsum dolor sit amet consectetur. Dignissim sed at habitant dui quis. Est est tempus in egestas. Tempus mollis tellus blandit aliquet morbi mollis nam eu odio. ", image: "nft_4", date: .init(timeIntervalSince1970: 1669363990)),
        .init(id: "12345", name: "PFP NFT Name", description: "Lorem ipsum dolor sit amet consectetur. Dignissim sed at habitant dui quis. Est est tempus in egestas. Tempus mollis tellus blandit aliquet morbi mollis nam eu odio. ", image: "nft_1", date: .init(timeIntervalSince1970: 1669363990)),
        .init(id: "12345", name: "PFP NFT Name", description: "Lorem ipsum dolor sit amet consectetur. Dignissim sed at habitant dui quis. Est est tempus in egestas. Tempus mollis tellus blandit aliquet morbi mollis nam eu odio. ", image: "nft_2", date: .init(timeIntervalSince1970: 1669363990)),
        .init(id: "12345", name: "PFP NFT Name", description: "Lorem ipsum dolor sit amet consectetur. Dignissim sed at habitant dui quis. Est est tempus in egestas. Tempus mollis tellus blandit aliquet morbi mollis nam eu odio. ", image: "nft_3", date: .init(timeIntervalSince1970: 1669363990)),
        .init(id: "12345", name: "PFP NFT Name", description: "Lorem ipsum dolor sit amet consectetur. Dignissim sed at habitant dui quis. Est est tempus in egestas. Tempus mollis tellus blandit aliquet morbi mollis nam eu odio. ", image: "nft_4", date: .init(timeIntervalSince1970: 1669363990)),
        .init(id: "12345", name: "PFP NFT Name", description: "Lorem ipsum dolor sit amet consectetur. Dignissim sed at habitant dui quis. Est est tempus in egestas. Tempus mollis tellus blandit aliquet morbi mollis nam eu odio. ", image: "nft_1", date: .init(timeIntervalSince1970: 1669363990)),
        .init(id: "12345", name: "PFP NFT Name", description: "Lorem ipsum dolor sit amet consectetur. Dignissim sed at habitant dui quis. Est est tempus in egestas. Tempus mollis tellus blandit aliquet morbi mollis nam eu odio. ", image: "nft_2", date: .init(timeIntervalSince1970: 1669363990)),
        .init(id: "12345", name: "PFP NFT Name", description: "Lorem ipsum dolor sit amet consectetur. Dignissim sed at habitant dui quis. Est est tempus in egestas. Tempus mollis tellus blandit aliquet morbi mollis nam eu odio. ", image: "nft_3", date: .init(timeIntervalSince1970: 1669363990)),
        .init(id: "12345", name: "PFP NFT Name", description: "Lorem ipsum dolor sit amet consectetur. Dignissim sed at habitant dui quis. Est est tempus in egestas. Tempus mollis tellus blandit aliquet morbi mollis nam eu odio. ", image: "nft_4", date: .init(timeIntervalSince1970: 1669363990)),
        .init(id: "12345", name: "PFP NFT Name", description: "Lorem ipsum dolor sit amet consectetur. Dignissim sed at habitant dui quis. Est est tempus in egestas. Tempus mollis tellus blandit aliquet morbi mollis nam eu odio. ", image: "nft_1", date: .init(timeIntervalSince1970: 1669363990)),
        .init(id: "12345", name: "PFP NFT Name", description: "Lorem ipsum dolor sit amet consectetur. Dignissim sed at habitant dui quis. Est est tempus in egestas. Tempus mollis tellus blandit aliquet morbi mollis nam eu odio. ", image: "nft_2", date: .init(timeIntervalSince1970: 1669363990))
    ]
}
