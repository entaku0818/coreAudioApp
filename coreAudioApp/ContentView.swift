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
                    Text("Go to ContentView")
                        .font(.title)
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
