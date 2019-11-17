//
//  ViewController.swift
//  ARKitPractice
//
//  Created by 杉浦光紀 on 2019/11/15.
//  Copyright © 2019 杉浦光紀. All rights reserved.
//

import UIKit
import RealityKit
import ARKit
import Combine

class ViewController: UIViewController, ARSessionDelegate {

    @IBOutlet weak var arView: ARView!
    
    // The 3D character to display.
    var character: BodyTrackedEntity?
    let characterOffset: SIMD3<Float> = [-1.0, 0, 0] // Offset the character by one meter to the left
    let characterAnchor = AnchorEntity()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        arView.session.delegate = self
        arView.debugOptions = [
            .showWorldOrigin,
            .showFeaturePoints,
            .showStatistics,
            .showAnchorGeometry,
            .showAnchorOrigins
        ]
        
        // 3D Body tracking and Add Robot
//        setup3DBodyTrackingAndAddRobot()
        
        // detect plane
        detectPlane()
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        arView.session.pause()
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        // 3D Body tracking and Add Robot
//        setup3DBodyTrackingAndAddRobotDelegate(anchors: anchors)
        
     }
    
    func detectPlane() {
        print("detectPlane")
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        arView.session.run(configuration)
        
    }
    
    
    func setup3DBodyTrackingAndAddRobot() {
        print("setup3DBodyTrackingAndAddRobot")
        guard ARBodyTrackingConfiguration.isSupported else {
            fatalError("This feature is only supported on devices with an A12 chip")
        }

        // Run a body tracking configration.
        let configuration = ARBodyTrackingConfiguration()
        arView.session.run(configuration)
        
        // Asynchronously load the 3D character.
        var cancellable: AnyCancellable? = nil
        cancellable = Entity.loadBodyTrackedAsync(named: "character/robot").sink(
            receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error: Unable to load model: \(error.localizedDescription)")
                }
                cancellable?.cancel()
        }, receiveValue: { (character: Entity) in
            if let character = character as? BodyTrackedEntity {
                // Scale the character to human size
                character.scale = [1.0, 1.0, 1.0]
                self.character = character
                cancellable?.cancel()
            } else {
                print("Error: Unable to load model as BodyTrackedEntity")
            }
        })
        
        arView.scene.addAnchor(characterAnchor)
    }
    
    func setup3DBodyTrackingAndAddRobotDelegate(anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }

            // Update the position of the character anchor's position.
            let bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
            characterAnchor.position = bodyPosition
            // Also copy over the rotation of the body anchor, because the skeleton's pose
            // in the world is relative to the body anchor's rotation.
            characterAnchor.orientation = Transform(matrix: bodyAnchor.transform).rotation

            if let character = character, character.parent == nil {
             // Attach the character to its anchor as soon as
             // 1. the body anchor was detected and
             // 2. the character was loaded.
             characterAnchor.addChild(character)
            }
        }
    }
}

