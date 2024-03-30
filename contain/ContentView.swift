//
//  ContentView.swift
//  contain
//
//  Created by Andrei Freund on 3/25/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @Environment(\.openWindow) private var openWindow
    @State private var isPlaying = true
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
    @State private var xDrop: Float = 0
    @State private var yDrop: Float = 0
    @State private var score: Int = 0
    private let OUT_OF_BOUNDS_ENTITY_NAME = "OutOfBoundsFloor"
    private let BALL_ENTITY_NAMES = [
        "Ball",
        "Ball05",
        "Ball1",
        "Ball2",
        "Ball3",
        "Ball4",
        "Ball5",
    ]
    private let EXAMPLE_BALL_ENTITY_NAMES = [
        "ExampleBall",
        "ExampleBall05"
    ]

    var body: some View {
        RealityView { content in
            // Load box for the game
            if let box = try? await Entity(named: "Scene", in: realityKitContentBundle) {
                content.add(box)
                floorEntity = box
            }
            // Example ball that moves with the sliders
            for exampleBallName in EXAMPLE_BALL_ENTITY_NAMES {
                if let ball = try? await Entity(named: exampleBallName, in: realityKitContentBundle) {
                    exampleBalls.append(ball)
                }
            }
            exampleBall = exampleBalls[0]
            exampleBall?.isEnabled = true
            content.add(exampleBall!)
            // Get the balls in order of size
            for ballName in BALL_ENTITY_NAMES {
                if let ball = try? await Entity(named: ballName, in: realityKitContentBundle) {
                    balls.append(ball)
                }
            }
            self.subs.append(content.subscribe(to: CollisionEvents.Began.self) { ce in
                if (ce.entityA.name == OUT_OF_BOUNDS_ENTITY_NAME) {
                    isPlaying = false
                    // TODO: Logic for ending game
                }
                // Combine balls of equal size
                if (ce.entityA.name == ce.entityB.name) {
                    replaceBallA = ce.entityA
                    replaceBallB = ce.entityB
                    score += 5 * ((balls.firstIndex(where: { e in e.name == ce.entityA.name }) ?? 0) + 1)
                }
                addBall = 0
            })
        } update: { content in
            if (replaceBallA != nil && replaceBallB != nil && replaceBallA!.isEnabled && replaceBallB!.isEnabled) {
                let ballClone = getNextSizeBallClone(ball: replaceBallA!)
                ballClone.position = getReplacementPos(ball1: replaceBallA!, ball2: replaceBallB!)
                clearReplacementBalls(ball1: replaceBallA!, ball2: replaceBallB!)
                content.add(ballClone)
                return
            }
            if (isPlaying && addBall > 0) {
                let ballClone = balls[addBallIndex].clone(recursive: true)
                // Add randomness so balls don't stack
                let x = xDrop / 65.0 + Float.random(in: -0.002...0.002)
                let y = Float.random(in: -0.02...0.02)
                let z = yDrop / 65.0 + Float.random(in: -0.002...0.002)
                ballClone.position = SIMD3(x, y, z)
                content.add(ballClone)
            }
            if (exampleBall != nil && !exampleBall!.isEnabled) {
                exampleBall!.isEnabled = true
                content.add(exampleBall!)
                print("NEW EXAMPLE BALL")
            }
            let x = xDrop / 65.0
            let z = yDrop / 65.0
            
            exampleBall?.position.x = x
            exampleBall?.position.z = z
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomOrnament) {
                HStack (spacing: 12) {
                    Button("Drop", action: {
                        addBall+=1
                        addBallIndex = (exampleBalls.firstIndex(where: { e in e.name == exampleBall?.name }) ?? 0)
                        exampleBall?.removeFromParent()
                        let next = getNextBallForDrop()
                        next.isEnabled = false
                        exampleBall = next
                    })
                    Slider(value: $xDrop, in: -10...10, step: 0.1) {
                        Text("X")
                    } minimumValueLabel: {
                        Image(systemName: "arrowshape.left")
                    } maximumValueLabel: {
                        Image(systemName: "arrowshape.right")
                    } onEditingChanged: { _ in
                        addBall = 0
                    }.frame(width: 200)
                    Slider(value: $yDrop, in: -10...10, step: 0.1) {
                        Text("Z")
                    } minimumValueLabel: {
                        Image(systemName: "arrowshape.up")
                    } maximumValueLabel: {
                        Image(systemName: "arrowshape.down")
                    } onEditingChanged: { _ in
                        addBall = 0
                    }.frame(width: 200)
                    Text("Score: \(score)").fontWeight(Font.Weight.bold).frame(width: 120)
                    Button("Info", action: {
                        openWindow(id: "info-window")
                    })
                }
            }
        }
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
        
        // TODO: Winning screen, this is crash at max size combine
        return balls[cur+1].clone(recursive: true)
    }
    
    func getNextBallForDrop() -> Entity {
        let rand = Int.random(in: 0...100)
        switch rand {
            case 0..<70: return exampleBalls[0]
            case 70..<101: return exampleBalls[1]
            default: return exampleBalls[0]
        }
    }
}

#Preview(windowStyle: .volumetric) {
    ContentView()
}
