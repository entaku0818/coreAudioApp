//
//  File1.swift
//  coreAudioApp
//
//  Created by 遠藤拓弥 on 2024/08/07.
//

import Foundation
import AudioToolbox
class AudioConverter {
    func convertAudioFile(inputURL: URL, outputURL: URL) {
        var inputFile: AudioFileID?
        var outputFile: AudioFileID?

        AudioFileOpenURL(inputURL as CFURL, .readPermission, 0, &inputFile)

        var dataFormat = AudioStreamBasicDescription()
        var dataFormatSize = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        AudioFileGetProperty(inputFile!, kAudioFilePropertyDataFormat, &dataFormatSize, &dataFormat)

        // 出力フォーマットを AAC に設定
        dataFormat.mFormatID = kAudioFormatMPEG4AAC
        dataFormat.mChannelsPerFrame = 2
        dataFormat.mSampleRate = 44100

        AudioFileCreateWithURL(outputURL as CFURL, kAudioFileM4AType, &dataFormat, .eraseFile, &outputFile)

        let bufferSize = 32768
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        while true {
            var numBytes = UInt32(bufferSize)
            var numPackets = UInt32(bufferSize) / dataFormat.mBytesPerPacket
            AudioFileReadPackets(inputFile!, false, &numBytes, nil, 0, &numPackets, buffer)

            if numPackets == 0 { break }

            AudioFileWritePackets(outputFile!, false, numBytes, nil, 0, &numPackets, buffer)
        }

        AudioFileClose(inputFile!)
        AudioFileClose(outputFile!)
    }
}

