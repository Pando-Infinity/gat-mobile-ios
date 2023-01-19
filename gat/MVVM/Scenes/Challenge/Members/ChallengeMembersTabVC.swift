//
//  ChallengeMembersTabVC.swift
//  gat
//
//  Created by Frank Nguyen on 1/19/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class ChallengeMembersTabVC: UIViewController {
    
    var isShowHeader: Bool = false
    
    private let tableViewMembers = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initView()
        
        print("Run ChallengeMembersTabVC")
        //view.backgroundColor = .blue
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func initView() {
        
        
        let nib = UINib.init(nibName: "ChallengeMemberCell", bundle: nil)
        self.tableViewMembers.register(nib, forCellReuseIdentifier: "ChallengeMemberCell")
        
        
        tableViewMembers.dataSource = self
        tableViewMembers.delegate = self
        tableViewMembers.allowsSelection = false
        
        //tableViewMembers.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        view.addSubview(tableViewMembers)
        self.tableViewMembers.snp.makeConstraints({ (make) in
            make.edges.equalToSuperview()
        })
    }
}

extension ChallengeMembersTabVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        10
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 76
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChallengeMemberCell", for: indexPath) as! ChallengeMemberCell
 
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if isShowHeader {
            let label = UILabel()
            label.frame = CGRect.init(x: 5, y: 5, width: tableViewMembers.frame.width, height: 50)
            label.text = "Notification Times"
            label.backgroundColor = .white
            //label.font = UIFont().futuraPTMediumFont(16) // my custom font
            return label
        } else {
            return nil
        }
    }
}
