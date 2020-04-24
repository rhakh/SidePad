//
//  ConnectionControllerCell.swift
//  SidePad
//
//  Created by Роман Гах on 24.04.2020.
//  Copyright © 2020 Роман Гах. All rights reserved.
//

import UIKit

class ConnectionControllerCell: UITableViewCell {

    @IBOutlet weak var candidateName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func update(with candidate: ConnectCandidate) {
        candidateName.text = "💻 " + candidate.name
    }

}
