//
//  GameViewController.swift
//  Try3
//
//  Created by Zicheng on 2021/12/6.
//

import Foundation
import UIKit
import SpriteKit

class GameViewController:UIViewController {
    
    @IBOutlet weak var GameSKView: SKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //
        //setup game scene
        let scene = GameScene(size: GameSKView.bounds.size)
        
        GameSKView.showsFPS = true // show FPS
        GameSKView.showsNodeCount = true // show number of objects
        GameSKView.ignoresSiblingOrder = true // Ignore the order of the objects
        scene.scaleMode = .resizeFill
        GameSKView.presentScene(scene)
        
    }

}
