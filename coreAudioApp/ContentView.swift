//
//  ContentView.swift
//  coreAudioApp
//
//  Created by 遠藤拓弥 on 2024/08/07.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            
            VStack {
                NavigationLink(destination: AVFaudioView()) {
                    Text("Go to AVFaudioView")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                NavigationLink(destination: AudioEngineView()) {
                    Text("Go to AudioEngineView")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)

                }
                NavigationLink(destination: AudioQueueServicesView()) {
                    Text("Go to CoreAudioView")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                NavigationLink(destination: AudioUnitView()) {
                    Text("Go to AudioUnitView")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                NavigationLink(destination: SystemSoundView()) {
                    Text("Go to SystemSoundView")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
