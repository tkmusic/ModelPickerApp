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
            ARViewContainer(modelConfirmedForPlacement: self.$modelConfirmedforPlacement)
            if(self.isPlacementEnabled){
                PlaceMentButtonsView(isPlacementEnabled: self.$isPlacementEnabled, selectedModel: self.$selectedModel, modelConfirmedForPlacement: self.$modelConfirmedforPlacement)
            } else{
                ModelPickerView(isPlacementEnebled: self.$isPlacementEnabled, selectedModel: self.$selectedModel, models: self.models)
            }
            
            
            
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    @Binding var modelConfirmedForPlacement: String?
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero)
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh){
            config.sceneReconstruction = .mesh
        }
        
        arView.session.run(config)
        
        return arView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        if let modelName = self.modelConfirmedForPlacement{
            print("DEBUG: Adding model to scene \(modelName)")
            let filename = modelName + ".usdz"
            let modelEntity = try!
                ModelEntity.loadModel(named: filename)
            let anchorEntity = AnchorEntity(plane: .any)
            anchorEntity.addChild(modelEntity)
            
            uiView.scene.addAnchor(anchorEntity)
            
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
                ForEach(0 ..< self.models.count){
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
