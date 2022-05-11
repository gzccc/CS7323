//
//  SelectDataViewController.swift
//  HTTPSwiftExample
//
//  Created by M on 2022/5/8.
//  Copyright © 2022 Eric Larson. All rights reserved.
//

import UIKit

class SelectDataViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {

    var dsidArray = [NSDictionary]()
    var selectDsidReturn:((String)->(Void))?
    
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return dsidArray.count
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.dismiss(animated: true)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let model = dsidArray[indexPath.row]
        cell.textLabel?.text = "DSID: \(model["dsid"]!)"
        //cell.detailTextLabel?.text = "Label:\(model["label"] as! String)"
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let model = dsidArray[indexPath.row]
        selectDsidReturn!("\(model["dsid"]!)")
        self.dismiss(animated: true)
    }
    
}
