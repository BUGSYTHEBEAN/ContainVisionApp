//
//  ContentView.swift
//  contain
//
//  Created by Andrei Freund on 3/25/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
import CoreData

struct ContentView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isPlaying = true
    @State private var resetGame = false
    @State private var subs: [EventSubscription] = []
    @State private var exampleBall: Entity?
    @State private var nextExampleBall: Entity?
    @State private var exampleBalls: [Entity] = []
    @State private var floorEntity: Entity?
    @State private var balls: [Entity] = []
    @State private var addBall = 0
    @State private var addBallIndex = 0
    @State private var replaceBallA: Entity?
    @State private var replaceBallB: Entity?
    @State private var xDropStart: Float = 0
    @State private var xDrop: Float = 0
    @State private var yDropStart: Float = 0
    @State private var yDrop: Float = 0
    @State private var score: Int = 0
    @State private var highScore: Int = 0
    @State private var isDragging = false
    @State private var collisionAudio: AudioResource?
    private let OUT_OF_BOUNDS_ENTITY_NAME = "OutOfBoundsFloor"
    private let BALL_ENTITY_NAMES = [
        "Ball",
        "Ball02",
        "Ball05",
        "Ball1",
        "Ball2",
        "Ball3",
        "Ball4",
        "Ball5",
    ]
    private let EXAMPLE_BALL_ENTITY_NAMES = [
        "ExampleBall",
        "ExampleBall02",
        "ExampleBall05",
        "ExampleBall1"
    ]
    
    var body: some View {
        RealityView { content in
            // Get saved game data
            highScore = getHighScore()
            // Load box for the game
            if let box = try? await Entity(named: "Scene", in: realityKitContentBundle) {
                content.add(box)
                floorEntity = box
                updateBoxColors(color: .darkGray)
            }
            // Example ball that moves with the sliders
            for exampleBallName in EXAMPLE_BALL_ENTITY_NAMES {
                if let ball = try? await Entity(named: exampleBallName, in: realityKitContentBundle) {
                    exampleBalls.append(ball)
                }
            }
            exampleBall = exampleBalls[0]
            exampleBall?.isEnabled = true
            exampleBall?.position.z = 0.20
            updateEntityOpacity(e: exampleBall, opacity: 0.5)
            content.add(exampleBall!)
            // Get the balls in order of size
            for ballName in BALL_ENTITY_NAMES {
                if let ball = try? await Entity(named: ballName, in: realityKitContentBundle) {
                    balls.append(ball)
                }
            }
            if let audio = try? AudioFileResource.load(named: "/RootScene/CollisionSound1_mp3", from: "Scene.usda", in: realityKitContentBundle) {
               collisionAudio = audio
            }
            self.subs.append(content.subscribe(to: CollisionEvents.Began.self) { ce in
                if (ce.entityA.name == OUT_OF_BOUNDS_ENTITY_NAME && ce.entityB.name.contains("Sphere")) {
                    isPlaying = false
                    // Save potential new high score
                    if (score > highScore) {
                        saveHighScore()
                        highScore = score
                    }
                    // Change box tint to red
                    updateBoxColors(color: .red)
                }
                // Combine balls of equal size
                if (ce.entityA.name == ce.entityB.name) {
                    replaceBallA = ce.entityA
                    replaceBallB = ce.entityB
                    score += 5 * ((balls.firstIndex(where: { e in e.name == ce.entityA.name }) ?? 0) + 1)
                    if (score > highScore) {
                        saveHighScore()
                        highScore = score
                    }
                }
                addBall = 0
            })
        } update: { content in
            if (resetGame && xDrop == 0 && yDrop == 0 && addBall == 0) {
                resetGameEntities(content: content)
                exampleBall!.isEnabled = true
                content.add(exampleBall!)
                return
            }
            if (replaceBallA != nil && replaceBallB != nil && replaceBallA!.isEnabled && replaceBallB!.isEnabled) {
                let ballClone = getNextSizeBallClone(ball: replaceBallA!)
                ballClone.position = getReplacementPos(ball1: replaceBallA!, ball2: replaceBallB!)
                clearReplacementBalls(ball1: replaceBallA!, ball2: replaceBallB!)
                content.add(ballClone)
                ballClone.playAudio(collisionAudio!)
                return
            }
            if (isPlaying && addBall > 0) {
                let ballClone = balls[addBallIndex].clone(recursive: true)
                // Add randomness so balls don't stack
                let x = xDrop / 70.0 + Float.random(in: -0.005...0.005)
                let y = Float.random(in: -0.02...0.02)
                let z = yDrop / 70.0 + Float.random(in: -0.005...0.005) + 0.20 // World offset
                ballClone.position = SIMD3(x, y, z)
                content.add(ballClone)
            }
            if (exampleBall != nil && !exampleBall!.isEnabled) {
                exampleBall!.isEnabled = true
                content.add(exampleBall!)
            }
            let x = xDrop / 70.0
            let z = yDrop / 70.0 + 0.20
            
            exampleBall?.position.x = x
            exampleBall?.position.z = z
            if (isDragging) {
                updateEntityOpacity(e: exampleBall, opacity: 1.0)
            } else {
                updateEntityOpacity(e: exampleBall, opacity: 0.5)
            }
        }
        // Drop ball on tap anywhere
        .gesture(SpatialTapGesture().targetedToAnyEntity().onEnded({_ in dropBall()}))
        // Drag to reposition example ball
        // x,yDrop are the current position of the example ball
        // x,yDropStart are the position of the example ball before the drag gesture started
        // These are required so that there isn't a visual jump when the gesture starts
        .gesture(DragGesture().targetedToAnyEntity().onChanged({action in
            xDrop = xDropStart + Float(action.translation3D.x.scaled(by: 0.05))
            yDrop = yDropStart + Float(action.translation3D.z.scaled(by: 0.05))
            addBall = 0
            if (xDrop > 10) {
                xDrop = 10
            } else if (xDrop < -10) {
                xDrop = -10
            }
            if (yDrop > 10) {
                yDrop = 10
            } else if (yDrop < -10) {
                yDrop = -10
            }
            isDragging = true
        }).onEnded({action in
            xDropStart = xDrop
            yDropStart = yDrop
            isDragging = false
        }))
        .toolbar {
            ToolbarItemGroup(placement: .bottomOrnament) {
                HStack (spacing: 12) {
                    Text("Score: \(score)").font(.title2).frame(minWidth: 140, alignment: .leading)
                    Text("High: \(highScore)").font(.title2).frame(minWidth: 140, alignment: .leading)
                    Button("Reset Game", systemImage: "arrow.counterclockwise", action: resetGameStates)
                        .labelStyle(.iconOnly).font(.title3)
                    Button("Info", systemImage: "info.circle", action: {openWindow(id: "info-window")})
                        .labelStyle(.iconOnly).font(.title)
                }.padding(.horizontal, 12)
            }
        }
    }
    
    func dropBall() {
        if (!isPlaying) {
            return
        }
        resetGame = false
        addBall+=1
        addBallIndex = (exampleBalls.firstIndex(where: { e in e.name == exampleBall?.name }) ?? 0)
        exampleBall?.removeFromParent()
        let next = getNextBallForDrop()
        next.isEnabled = false
        exampleBall = next
    }
    
    func clearReplacementBalls(ball1: Entity, ball2: Entity) {
        ball1.removeFromParent()
        ball1.isEnabled = false
        ball2.removeFromParent()
        ball2.isEnabled = false
    }
    
    func getReplacementPos(ball1: Entity, ball2: Entity) -> SIMD3<Float> {
        // Need to use relative to a static object or it only counts relative to where the entity spawned
        let x = (ball1.position(relativeTo: floorEntity).x + ball2.position(relativeTo: floorEntity).x) / 2
        let y = (ball1.position(relativeTo: floorEntity).y + ball2.position(relativeTo: floorEntity).y) / 2
        let z = (ball1.position(relativeTo: floorEntity).z + ball2.position(relativeTo: floorEntity).z) / 2
        return SIMD3(x, y, z)
    }
    
    func getNextSizeBallClone(ball: Entity) -> Entity {
        guard let cur = balls.firstIndex(where: { e in e.name == ball.name }) else { return balls[1].clone(recursive: true) }
        
        // Max size combine replaces with one max size entity
        return balls.count > cur+1 ? balls[cur+1].clone(recursive: true) : balls[cur].clone(recursive: true)
    }
    
    func saveHighScore() -> Void {
        let fetchData = NSFetchRequest<NSFetchRequestResult>(entityName: "ScoreEntity")
        if let result = try? viewContext.fetch(fetchData) as? [ScoreEntity] {
            if (!result.isEmpty) {
                if (Int(result[0].highScore) > score) {
                    return
                }
                result[0].setValue(Int32(score), forKey: "highScore")
            } else {
                let scoreEntity = ScoreEntity(context: viewContext)
                scoreEntity.highScore = Int32(score)
            }
        }
        do {
            try viewContext.save()
        } catch {}
    }
    
    func getHighScore() -> Int {
        let fetchData = NSFetchRequest<NSFetchRequestResult>(entityName: "ScoreEntity")
        if let result = try? viewContext.fetch(fetchData) as? [ScoreEntity] {
            if (!result.isEmpty) {
                return Int(result[0].highScore)
            }
        }
        return 0
    }
    
    func getNextBallForDrop() -> Entity {
        let rand = Int.random(in: 0...100)
        switch rand {
            case 0..<40: return exampleBalls[0]
            case 40..<70: return exampleBalls[1]
            case 70..<91: return exampleBalls[2]
            case 91..<101: return exampleBalls[3]
            default: return exampleBalls[0]
        }
    }
    
    func resetGameStates() -> Void {
        resetGame = true
        isPlaying = true
        addBall = 0
        replaceBallA = nil
        score = 0
        xDrop = 0
        yDrop = 0
        exampleBall = getNextBallForDrop()
        updateBoxColors(color: .darkGray)
    }
    
    func resetGameEntities(content: RealityViewContent) -> Void {
        // Clear all entities except box
        // TODO: Add particles???
        content.entities.removeAll(where: {e -> Bool in e.name != "RootScene"})
    }
    
    func updateBoxColors(color: UIColor) -> Void {
        for e in floorEntity!.children.first!.children {
            if e.name.contains("Front") {
                continue
            }
            var model = e.components[ModelComponent.self]
            if var material = model?.materials.first as? PhysicallyBasedMaterial {
                material.baseColor.tint = color
                model!.materials = [material]
                e.components.set(model!)
            }
        }
    }
    
    func updateEntityOpacity(e: Entity?, opacity: Float) -> Void {
        if (e == nil) {
            return
        }
        e!.components[OpacityComponent.self] = .init(opacity: opacity)
    }
}

#Preview(windowStyle: .volumetric) {
    ContentView()
}
