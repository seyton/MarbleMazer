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
    var cameraNode: SCNNode!
    var cameraFollowNode: SCNNode!
    var lightFollowNode: SCNNode!
    
    var game = GameHelper.sharedInstance
    var motion = CoreMotionHelper()
    var motionForce = SCNVector3Zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScene()
        setupNodes()
        setupSounds()
        
        resetGame()
    }
    
    func setupScene() {
        
        scnView = view as! SCNView
        scnView.delegate = self
//        scnView.allowsCameraControl = true
//        scnView.showsStatistics = true
        
        scnScene = SCNScene(named: "art.scnassets/game.scn")
        scnView.scene = scnScene
        scnScene.physicsWorld.contactDelegate = self
    }
    
    func setupNodes() {
        
        ballNode = scnScene.rootNode.childNodeWithName("ball", recursively: true)
        ballNode.physicsBody?.contactTestBitMask = CollisionCategoryPillar | CollisionCategoryCrate | CollisionCategoryPearl
        
        cameraNode = scnScene.rootNode.childNodeWithName("camera", recursively: true)
        
        let constraint = SCNLookAtConstraint(target: ballNode)
        cameraNode.constraints = [constraint]
        constraint.gimbalLockEnabled = true

        cameraFollowNode = scnScene.rootNode.childNodeWithName("follow_camera", recursively: true)

        cameraNode.addChildNode(game.hudNode)
        
        lightFollowNode = scnScene.rootNode.childNodeWithName("follow_light", recursively: true)
        
    }
    
    func setupSounds() {
        
        game.loadSound("GameOver", fileNamed: "GameOver.wav")
        game.loadSound("Powerup", fileNamed: "Powerup.wav")
        game.loadSound("Reset", fileNamed: "Reset.wav")
        game.loadSound("Bump", fileNamed: "Bump.wav")
    }
    
    //MARK: - Game Play Loop
    func playGame() {
        
        game.state = GameStateType.Playing
        cameraFollowNode.eulerAngles.y = 0
        cameraFollowNode.position = SCNVector3Zero
        replenishLife()
    }
    
    func resetGame() {
        
        game.state = .TapToPlay
        game.playSound(ballNode, name: "Reset")
        ballNode.physicsBody?.velocity = SCNVector3Zero
        ballNode.position = SCNVector3(x: 0, y: 10, z: 0)
        cameraFollowNode.position = ballNode.position
        lightFollowNode.position = ballNode.position
        scnView.playing = true
        game.reset()
    }
    
    func testForGameOver() {
        
        if ballNode.presentationNode.position.y < -5 {
            
            game.state = .GameOver
            game.playSound(ballNode, name: "GameOver")
            ballNode.runAction(SCNAction.waitForDurationThenRunBlock(5, block: { (node) in
                self.resetGame()
            }))
        }
    }
    
    func replenishLife() {
        
        let material = ballNode.geometry!.firstMaterial!
        
        SCNTransaction.begin()
        SCNTransaction.setAnimationDuration(1.0)
        
        material.emission.intensity = 1.0
        
        SCNTransaction.commit()
        
        game.score += 1
        game.playSound(ballNode, name: "Powerup")
    }
    
    func diminishLife() {
        
        let material = ballNode.geometry!.firstMaterial!
        
        if material.emission.intensity > 0 {
            material.emission.intensity -= 0.001
        }
        else {
            resetGame()
        }
    }
    
    func updateHUD() {
        
        switch game.state {
            
        case .Playing:
            game.updateHUD()
            
        case .GameOver:
            game.updateHUD("-GAME OVER-")
            
        case .TapToPlay:
            game.updateHUD("-TAP TO PLAY-")
        }
    }
    
    //MARK: - Game Control
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        if game.state == .TapToPlay {
            playGame()
        }
    }
    
    func updateMotionControl() {
        
        if game.state == .Playing {
            
            motion.getAccelerometerData(0.1, closure: { (x, y, z) in
                self.motionForce = SCNVector3(x: Float(x) * 0.05, y: 0, z: Float(y + 0.8) * -0.05)
            })
        }
        ballNode.physicsBody?.velocity += motionForce
    }
    
    func updateCameraAndLights() {
        
        let lerpX = (ballNode.presentationNode.position.x - cameraFollowNode.position.x) * 0.01
        let lerpY = (ballNode.presentationNode.position.y - cameraFollowNode.position.y) * 0.01
        let lerpZ = (ballNode.presentationNode.position.z - cameraFollowNode.position.z) * 0.01
        
        cameraFollowNode.position.x += lerpX
        cameraFollowNode.position.y += lerpY
        cameraFollowNode.position.z += lerpZ
        
        lightFollowNode.position = cameraFollowNode.position
        
        if game.state == .TapToPlay {
            cameraFollowNode.eulerAngles.y += 0.005
        }
    }
}

//MARK: - SCNSceneRendererDelegate
extension GameViewController: SCNSceneRendererDelegate {
    
    func renderer(renderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        
        updateMotionControl()
        updateCameraAndLights()
        updateHUD()
        
        if game.state == .Playing {
            testForGameOver()
            diminishLife()
        }
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
            
            replenishLife()
        }
        
        if contactNode.physicsBody?.categoryBitMask == CollisionCategoryPillar ||
            contactNode.physicsBody?.categoryBitMask == CollisionCategoryCrate {
            
            game.playSound(ballNode, name: "Bump")
        }
    }
}