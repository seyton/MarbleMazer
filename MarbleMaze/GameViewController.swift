//
//  GameViewController.swift
//  MarbleMaze
//
//  Created by Wesley Matlock on 4/5/16.
//  Copyright (c) 2016 insoc.net. All rights reserved.
//

import UIKit
import SceneKit

class GameViewController: UIViewController {

    let CollisionCategoryBall   = 1
    let CollisionCategoryStone  = 2
    let CollisionCategoryPillar = 4
    let CollisionCategoryCrate  = 8
    let CollisionCategoryPearl  = 16
    
    var scnView: SCNView!
    var scnScene: SCNScene!
    var ballNode: SCNNode!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScene()
        setupNodes()
        setupSounds()
    }
    
    func setupScene() {
        
        scnView = view as! SCNView
        scnView.delegate = self
        scnView.allowsCameraControl = true
        scnView.showsStatistics = true
        
        scnScene = SCNScene(named: "art.scnassets/game.scn")
        scnView.scene = scnScene
    }
    
    func setupNodes() {
        
        ballNode = scnScene.rootNode.childNodeWithName("ball", recursively: true)
        ballNode.physicsBody?.contactTestBitMask = CollisionCategoryPillar | CollisionCategoryCrate | CollisionCategoryPearl
    }
    
    func setupSounds() {
        
    }
}

extension GameViewController: SCNSceneRendererDelegate {
    
    func renderer(renderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        
    }
}
