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
        scnScene.physicsWorld.contactDelegate = self
    }
    
    func setupNodes() {
        
        ballNode = scnScene.rootNode.childNodeWithName("ball", recursively: true)
        ballNode.physicsBody?.contactTestBitMask = CollisionCategoryPillar | CollisionCategoryCrate | CollisionCategoryPearl
    }
    
    func setupSounds() {
        
    }
}

//MARK: - SCNSceneRendererDelegate
extension GameViewController: SCNSceneRendererDelegate {
    
    func renderer(renderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        
    }
}

//MARK: - SCNPhysicsContactDelegate
extension GameViewController: SCNPhysicsContactDelegate {
    
    func physicsWorld(world: SCNPhysicsWorld, didBeginContact contact: SCNPhysicsContact) {
        
        var contactNode: SCNNode
        
        if contact.nodeA.name == "ball" {
            contactNode = contact.nodeB
        }
        else {
            contactNode = contact.nodeA
        }
        
        if contactNode.physicsBody?.categoryBitMask == CollisionCategoryPearl {
            
            contactNode.hidden = true
            contactNode.runAction(SCNAction.waitForDurationThenRunBlock(30, block: { (node) in
                node.hidden = false
            }))
        }
        
        if contactNode.physicsBody?.categoryBitMask == CollisionCategoryPillar ||
            contactNode.physicsBody?.categoryBitMask == CollisionCategoryCrate {
            

        }
    }
}