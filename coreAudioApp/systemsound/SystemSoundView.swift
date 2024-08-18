//
//  SwiftUIView.swift
//  coreAudioApp
//
//  Created by 遠藤拓弥 on 2024/08/15.
//

import SwiftUI

struct SystemSoundView: View {
    let systemSoundExample = SystemSoundExample()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Button(action: {
                    systemSoundExample.playCustomSound()
                }) {
                    Text("Play Custom Sound")
                        .font(.title)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                ForEach(SystemSoundExample.SystemSound.allCases, id: \.self) { sound in
                    Button(action: {
                        systemSoundExample.playSystemSound(sound: sound)
                    }) {
                        Text(sound.rawValue.description)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                }

                Button(action: {
                    systemSoundExample.playAlertSound()
                }) {
                    Text("Play Alert Sound")
                        .font(.title)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button(action: {
                    systemSoundExample.generateHapticFeedback()
                }) {
                    Text("Generate Haptic Feedback")
                        .font(.title)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

            }
            .padding()
        }
    }
}
