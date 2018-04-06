//
//  ShareLinkHeaderCell.swift
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 4/8/15.
//

/*
Copyright (C) 2017, ownCloud GmbH.
This code is covered by the GNU Public License Version 3.
For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
You should have received a copy of this license
along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*/

import UIKit

class ShareLinkHeaderCell:UITableViewCell {
    
    let switchCornerRadious: CGFloat = 17.0
    
    @IBOutlet weak var titleSection: UILabel!
    @IBOutlet weak var switchSection: UISwitch!
    @IBOutlet weak var addButtonSection: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setup()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }

    fileprivate func setup(){
        
        switchSection.backgroundColor = UIColor.white
        switchSection.layer.cornerRadius = switchCornerRadious
        
        self.contentView.backgroundColor = UIColor.ofNavigationBar()
        titleSection.textColor = UIColor.ofNavigationTitle()
        
        addButtonSection.setTitleColor(UIColor.ofNavigationTitle(), for: .normal)
    }
    
}
