//
//  ContentView.swift
//  ModelPickerApp
//
//  Created by Toni Krug on 25.07.23.
//

import SwiftUI
import RealityKit
import ARKit

struct ContentView : View {
    @State private var isPlacementEnabled = false
    @State private var selectedModel: String?
    @State private var modelConfirmedforPlacement: String?
    
    private var models: [String] = {
        // dynamically get the file names
        let filemanager = FileManager.default
        
        guard let path = Bundle.main.resourcePath,
              let files = try?
                filemanager.contentsOfDirectory(atPath: path) else{ return []
        }
        var availableModels: [String] = []
        for filename in files where filename.hasSuffix("usdz"){
            let modelName = filename.replacingOccurrences(of: ".usdz", with: "")
            availableModels.append(modelName)
        }
        return availableModels
    }()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // placing the AR View
            ARViewContainer(modelConfirmedForPlacement: self.$modelConfirmedforPlacement)
            
            // placing the confirmation buttons, when a Model is selected
            if(self.isPlacementEnabled){
                PlaceMentButtonsView(isPlacementEnabled: self.$isPlacementEnabled, selectedModel: self.$selectedModel, modelConfirmedForPlacement: self.$modelConfirmedforPlacement)
                
            // placing the ModelPickerView when nothing is selected
            } else{
                ModelPickerView(isPlacementEnebled: self.$isPlacementEnabled, selectedModel: self.$selectedModel, models: self.models)
            }
            
            
            
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    @Binding var modelConfirmedForPlacement: String?
    
    func makeUIView(context: Context) -> ARView {
        
        // Configuring the AR Container with planedetection and environment textures
        let arView = ARView(frame: .zero)
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        
        // Configuring Scene Recon if supported
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh){
            config.sceneReconstruction = .mesh
        }
        
        // running the AR Container in the session
        arView.session.run(config)
        
        return arView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // getting the filename from the modelName
        
        if let modelName = self.modelConfirmedForPlacement{
            print("DEBUG: Adding model to scene \(modelName)")
            let filename = modelName + ".usdz"
            
            // creating the ModelEntity
            let modelEntity = try!
                ModelEntity.loadModel(named: filename)
            
            // creating the AnchorEntity
            let anchorEntity = AnchorEntity(plane: .any)
            // Adding the modelEntity to the Anchor
            anchorEntity.addChild(modelEntity)
            // Adding the Anchor to the Scene
            uiView.scene.addAnchor(anchorEntity)
            
            // resetting the model value
            DispatchQueue.main.async {
                self.modelConfirmedForPlacement = nil
            }
           
        }
    }
    
}

struct ModelPickerView : View {
    @Binding var isPlacementEnebled: Bool
    @Binding var selectedModel: String?
    
    var models: [String]
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false){
            HStack(spacing: 30){
                ForEach(0 ..< self.models.count, id: \.self){
                    index in
                    Button(action: {
                        print("DEBUG: selected model with name \(self.models[index])")
                        self.isPlacementEnebled = true
                        self.selectedModel = self.models[index]
                    }){
                            Image(uiImage:
                                    UIImage(named: self.models[index])!)
                            .resizable()
                            .frame(height: 80)
                            .aspectRatio(1/1, contentMode: .fit)
                            .background(Color.white)
                            .cornerRadius(12)
                        } .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(20)
        .background(Color.black.opacity(0.5))
    }
}

struct PlaceMentButtonsView : View {
    @Binding var isPlacementEnabled: Bool
    @Binding var selectedModel: String?
    @Binding var modelConfirmedForPlacement: String?
    
    var body: some View{
        HStack {
            // cancel button
            Button(action: {
                print("DEBUG: cancel model placement.")
                self.resetPlacementParameters()
            }){
                Image(systemName: "xmark")
                    .frame(width: 60, height: 60)
                    .font(.title)
                    .background(Color.white.opacity(0.75))
                    .cornerRadius(30)
                    .padding(20)
            }
            // confirm button
            Button(action: {
                print("DEBUG: confirm model placement.")
                self.modelConfirmedForPlacement = self.selectedModel
                self.resetPlacementParameters()
            }){
                Image(systemName: "checkmark")
                    .frame(width: 60, height: 60)
                    .font(.title)
                    .background(Color.white.opacity(0.75))
                    .cornerRadius(30)
                    .padding(20)
            }
        }
    }
    func resetPlacementParameters(){
        self.isPlacementEnabled = false
        self.selectedModel = nil
    }
}


#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
