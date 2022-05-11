//
//  GameScene.swift
//  Try3
//
//  Created by Zicheng on 2021/12/6.
//

import Foundation
import SpriteKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: Raw Motion Functions
    let motion = CMMotionManager()
    let motionModel = {
        return MotionModel.sharedInstance()
    }()
    
    private let GAME_COST = 1 // takes 1 coin to input 1 rock
    
    func startMotionUpdates(){
        // if device's motion is available, start updating the device motion
        if self.motion.isDeviceMotionAvailable{
            self.motion.deviceMotionUpdateInterval = 0.2
            self.motion.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: self.handleMotion )
        }
    }
    
    func handleMotion(_ motionData:CMDeviceMotion?, error:Error?){
        // make gravity in the game as the simulator gravity
        if let gravity = motionData?.gravity {
            self.physicsWorld.gravity = CGVector(dx: CGFloat(9.8*gravity.x), dy: CGFloat(9.8*gravity.y))
            let action = SKAction.moveBy(x: gravity.x * 200, y: 0, duration: 0.5)
            spinBlock.run(action)
//            }
        }
    }
    
    
    // MARK: View Hierarchy Functions
    // this is like out "View Did Load" function
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        backgroundColor = SKColor.white
        
        // start motion for gravity
        self.startMotionUpdates()
        
        // make sides to the screen
        self.addSides()
        
        // add a spinning block
        self.addEggAtPoint(CGPoint(x: size.width * 0.5, y: size.height * 0.25))
        
        // add a rock
        self.addRock()
        
        
        // add a scorer
        self.addScore()
        
        // add currency
        self.addCurrency()
        
        // update a special watched property for score
        self.score = 0
    }
    
    // MARK: Create Sprites Functions
    let spinBlock = SKSpriteNode(imageNamed: "egg2")
    let scoreLabel = SKLabelNode(fontNamed: "Arial")
    let currencyLable = SKLabelNode(fontNamed: "Arial")
    var score:Int = 0 {
        willSet(newValue){
            DispatchQueue.main.async{
                self.scoreLabel.text = "Score: \(newValue)"
            }
        }
    }
    var currency:Int = 0 {
        willSet(newValue){
            DispatchQueue.main.async {
                self.currencyLable.text = "Coin: \(newValue)"
            }
        }
    }
    
    func addScore(){
        //adds score into scene
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = SKColor.black
        scoreLabel.position = CGPoint(x: frame.maxX-80, y: frame.maxY-100)
        
        addChild(scoreLabel)
    }
    
    func addCurrency(){
        //adds currency into scene
        self.motionModel.setUpCurrency()
        self.currency = motionModel.getCurrency()
        print("currency: \(self.currency)")
        
        currencyLable.text = "Coin: \(self.currency)"
        currencyLable.fontSize = 20
        currencyLable.fontColor = SKColor.black
        currencyLable.position = CGPoint(x: frame.minX+80, y: frame.maxY-100)
        
        addChild(currencyLable)
    }
    
    func addRock(){
        //adds rock into scene
        if false == self.motionModel.updateCurrency(number: -1) {
            return
        } else {
            self.currency = self.motionModel.getCurrency()
        }
        
        let rock = SKSpriteNode(imageNamed: "rock1")
        
        rock.size = CGSize(width:size.width*0.2,height:size.height * 0.1)
        
        let randNumber = random(min: CGFloat(0.1), max: CGFloat(0.9))
        rock.position = CGPoint(x: size.width * randNumber, y: size.height * 0.75)
        
        rock.physicsBody = SKPhysicsBody(rectangleOf:rock.size)
        rock.physicsBody?.restitution = random(min: CGFloat(1), max: CGFloat(4))
        rock.physicsBody?.isDynamic = true
        spinBlock.physicsBody?.mass = 3
        // for collision detection we need to setup these masks
        rock.physicsBody?.contactTestBitMask = 0x00000001
        rock.physicsBody?.collisionBitMask = 0x00000001
        rock.physicsBody?.categoryBitMask = 0x00000001
        

        
        self.addChild(rock)
    }
    
    func addEggAtPoint(_ point:CGPoint){
        //adds egg into scene, to be cracked by the rocks
        spinBlock.color = UIColor.green
        spinBlock.size = CGSize(width:size.width*0.2,height:size.height * 0.1)
        spinBlock.position = point
        
        spinBlock.physicsBody = SKPhysicsBody(rectangleOf: spinBlock.size)
        spinBlock.physicsBody?.contactTestBitMask = 0x00000001
        spinBlock.physicsBody?.collisionBitMask = 0x00000001
        spinBlock.physicsBody?.categoryBitMask = 0x00000001
        spinBlock.physicsBody?.isDynamic = true
        spinBlock.physicsBody?.affectedByGravity = true
        spinBlock.physicsBody?.allowsRotation = true
        spinBlock.physicsBody?.angularDamping = 0.4
        spinBlock.physicsBody?.mass = 5
        spinBlock.physicsBody?.restitution = random(min: CGFloat(0.5), max: CGFloat(3.5))

        self.addChild(spinBlock)

    }
    
    func addSides(){
        let left = SKSpriteNode(imageNamed: "wall_texture")
        let right = SKSpriteNode(imageNamed: "wall_texture")
        let top = SKSpriteNode(imageNamed: "wall_texture")
        let bottom = SKSpriteNode(imageNamed: "wall_texture")
        
        left.size = CGSize(width:size.width*0.15,height:size.height)
        left.position = CGPoint(x:0, y:size.height*0.5)
        
        right.size = CGSize(width:size.width*0.15,height:size.height)
        right.position = CGPoint(x:size.width, y:size.height*0.5)
        
        top.size = CGSize(width:size.width+50,height:size.height*0.1)
        top.position = CGPoint(x:size.width*0.5, y:size.height)
        
        bottom.size = CGSize(width:size.width,height:size.height*0.1)
        bottom.position = CGPoint(x:size.width*0.5+25, y:0)
        
        for obj in [left,right,top,bottom]{
            obj.color = UIColor.green
            obj.physicsBody = SKPhysicsBody(rectangleOf:obj.size)
            obj.physicsBody?.isDynamic = false
            obj.physicsBody?.pinned = true
            obj.physicsBody?.allowsRotation = false
            obj.physicsBody?.contactTestBitMask = 0x00000001
            obj.physicsBody?.collisionBitMask = 0x00000001
            obj.physicsBody?.categoryBitMask = 0x00000001
            self.addChild(obj)
        }
    }
    
    // MARK: =====Delegate Functions=====
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.addRock()
    }
    
    // here is our collision function
    func didBegin(_ contact: SKPhysicsContact) {
        // increase the score every time rock hits the egg
        if contact.bodyA.node == spinBlock || contact.bodyB.node == spinBlock {
            spinBlock.physicsBody?.velocity.dy = 0
            self.score += 1
        }
        
        
        // TODO: How might we add additional scoring mechanisms?
    }
    
    // MARK: Utility Functions (thanks ray wenderlich!)
    // generate some random numbers for cor graphics floats
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / Float(Int.max))
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
}
