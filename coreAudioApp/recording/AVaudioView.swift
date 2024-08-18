//
//  AVFaudio.swift
//  coreAudioApp
//
//  Created by 遠藤拓弥 on 2024/08/15.
//

import Foundation
import SwiftUI
struct AudioEngineView: View {
    private var audioRecorder = AudioEngineRecorder()
    private var audioPlayer = AVFAudioPlayer()

    @State private var isRecording = false
    @State private var isPlaying = false

    private let filename = "recording.caf"

    var body: some View {
        VStack(spacing: 20) {
            Button(action: {
                if isRecording {
                    audioRecorder.stopRecording()
                } else {
                    audioRecorder.startRecording(filename: filename)
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
                    audioPlayer.stopPlaying()
                } else {
                    audioPlayer.startPlaying(filename: filename)
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
