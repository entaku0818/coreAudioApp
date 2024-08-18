//
//  a.swift
//  coreAudioApp
//
//  Created by 遠藤拓弥 on 2024/08/16.
//

import Foundation
import SwiftUI

struct AudioUnitView: View {
    private var audioManager = AudioUnitManager()

    @State private var isRecording = false
    @State private var isPlaying = false

    var body: some View {
        VStack(spacing: 20) {
            Button(action: {
                if isRecording {
                    audioManager.stopRecording()
                } else {
                    audioManager.startRecording()
                }
                isRecording.toggle()
            }) {
                Text(isRecording ? "Stop Recording" : "Start Recording")
                    .font(.title)
                    .padding()
                    .background(isRecording ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Button(action: {
                if isPlaying {
                    audioManager.stopPlaying()
                } else {
                    audioManager.startPlaying()
                }
                isPlaying.toggle()
            }) {
                Text(isPlaying ? "Stop Playing" : "Start Playing")
                    .font(.title)
                    .padding()
                    .background(isPlaying ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}
