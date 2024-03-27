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
    @State private var isPlaying = true
    @State private var subs: [EventSubscription] = []
    @State private var exampleBall: Entity?
    @State private var floorEntity: Entity?
    @State private var balls: [Entity] = []
    @State private var addBall = 0
    @State private var replaceBallA: Entity?
    @State private var replaceBallB: Entity?
    @State private var xDrop: Float = 0
    @State private var yDrop: Float = 0
    @State private var score: Int = 0
    private let OUT_OF_BOUNDS_ENTITY_NAME = "OutOfBoundsFloor"
    private let BALL_ENTITY_NAMES = [
        "Ball",
        "Ball1",
        "Ball2",
        "Ball3",
        "Ball4",
        "Ball5",
    ]

    var body: some View {
        RealityView { content in
            // Load box for the game
            if let box = try? await Entity(named: "Scene", in: realityKitContentBundle) {
                content.add(box)
                floorEntity = box
            }
            // Example ball that moves with the sliders
            if let example = try? await Entity(named: "ExampleBall", in: realityKitContentBundle) {
                exampleBall = example
                content.add(exampleBall!)
            }
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
                    score += 5 // Make score scale by size and streak?\
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
                let ballClone = balls[0].clone(recursive: true)
                // Add randomness so balls don't stack
                let x = xDrop / 65.0 + Float.random(in: -0.002...0.002)
                let y = Float.random(in: -0.02...0.02)
                let z = yDrop / 65.0 + Float.random(in: -0.002...0.002)
                ballClone.position = SIMD3(x, y, z)
                content.add(ballClone)
            } else {
                let x = xDrop / 65.0
                let z = yDrop / 65.0
                exampleBall?.position.x = x
                exampleBall?.position.z = z
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomOrnament) {
                HStack (spacing: 12) {
                    Button("Drop", action: {
                        addBall+=1
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
}

#Preview(windowStyle: .volumetric) {
    ContentView()
}
