//
//  HeaderLabelStackController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 6/8/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class HeaderLabelStackController: UIViewController {
    
    typealias TextStyle = (font:UIFont?, color:UIColor)
    
    let labelStackView:UIStackView
    let labels:[UILabel]
    
    init(numberOfLabels:Int) {
        var labels = [UILabel]()
        let mainDetailLabelStyle:TextStyle = (UIFont(name: ThemeHelper.defaultFontNameBold, size: ThemeHelper.defaultFontSize - 1), ThemeHelper.defaultFontColor)
        let subDetailLabelStyle:TextStyle = (ThemeHelper.smallFontForStyle(.Normal), UIColor.lightGrayColor())
        func createLabel(labelNumber:Int) -> UILabel {
            let textStyle = labelNumber == 0 ? mainDetailLabelStyle : subDetailLabelStyle
            let label = UILabel()
            label.font = textStyle.font
            label.textColor = textStyle.color
            label.textAlignment = .Center
            return label
        }
        
        for i in 0..<numberOfLabels {
            labels.append(createLabel(i))
        }
        
        self.labels = labels
        
        labelStackView = UIStackView(arrangedSubviews: labels)
        labelStackView.axis = .Vertical
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = labelStackView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

}
