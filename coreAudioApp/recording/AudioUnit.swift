//
//  AudioUnit.swift
//  coreAudioApp
//
//  Created by 遠藤拓弥 on 2024/08/18.
//

import Foundation
import Foundation
import AudioToolbox
import AVFoundation
import os.log

class AudioUnitManager {
    private var audioUnit: AudioUnit?
    private var recordingFile: AudioFileID?
    private var playbackFile: AudioFileID?
    private var isRecording = false
    private var isPlaying = false
    private var currentPacket: Int64 = 0
    private var audioFileSize: Int64 = 0

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "AudioUnitManager", category: "AudioRecording")

    private var recordingFormat: AudioStreamBasicDescription = {
        var format = AudioStreamBasicDescription()
        format.mSampleRate = 44100.0
        format.mFormatID = kAudioFormatLinearPCM
        format.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
        format.mBitsPerChannel = 16
        format.mChannelsPerFrame = 1
        format.mFramesPerPacket = 1
        format.mBytesPerFrame = 2
        format.mBytesPerPacket = 2
        return format
    }()

    init() {
        setupAudioSession()
        setupAudioUnit()
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
            try session.setActive(true)
            logger.info("Audio session setup completed")
        } catch {
            logger.error("Failed to setup audio session: \(error.localizedDescription)")
        }
    }

    private func setupAudioUnit() {
        var audioComponentDescription = AudioComponentDescription(
            componentType: kAudioUnitType_Output,
            componentSubType: kAudioUnitSubType_RemoteIO,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )

        guard let audioComponent = AudioComponentFindNext(nil, &audioComponentDescription) else {
            logger.error("Failed to find audio component")
            return
        }

        var status = AudioComponentInstanceNew(audioComponent, &audioUnit)
        guard status == noErr else {
            logger.error("Failed to create audio unit instance: \(status)")
            return
        }

        var enableIO: UInt32 = 1
        status = AudioUnitSetProperty(audioUnit!, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &enableIO, UInt32(MemoryLayout<UInt32>.size))
        guard status == noErr else {
            logger.error("Failed to enable input on audio unit: \(status)")
            return
        }

        status = AudioUnitSetProperty(audioUnit!, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &recordingFormat, UInt32(MemoryLayout<AudioStreamBasicDescription>.size))
        guard status == noErr else {
            logger.error("Failed to set stream format: \(status)")
            return
        }

        var callbackStruct = AURenderCallbackStruct(
            inputProc: recordingCallback,
            inputProcRefCon: Unmanaged.passUnretained(self).toOpaque()
        )
        status = AudioUnitSetProperty(audioUnit!, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 0, &callbackStruct, UInt32(MemoryLayout<AURenderCallbackStruct>.size))
        guard status == noErr else {
            logger.error("Failed to set recording callback: \(status)")
            return
        }

        status = AudioUnitInitialize(audioUnit!)
        guard status == noErr else {
            logger.error("Failed to initialize audio unit: \(status)")
            return
        }

        logger.info("Audio unit setup completed successfully")
    }

    func startRecording() {
        guard !isRecording else {
            logger.warning("Recording already in progress")
            return
        }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilePath = documentsPath.appendingPathComponent("recording.caf")

        var audioFile: AudioFileID?
        let createStatus = AudioFileCreateWithURL(audioFilePath as CFURL, kAudioFileCAFType, &recordingFormat, .eraseFile, &audioFile)
        guard createStatus == noErr else {
            logger.error("Failed to create audio file: \(createStatus)")
            return
        }
        recordingFile = audioFile
        logger.info("Audio file created successfully")

        let status = AudioOutputUnitStart(audioUnit!)
        guard status == noErr else {
            logger.error("Failed to start audio unit: \(status)")
            return
        }

        isRecording = true
        currentPacket = 0
        logger.info("Recording started successfully")
    }

    func stopRecording() {
        guard isRecording else {
            logger.warning("No recording in progress to stop")
            return
        }

        let status = AudioOutputUnitStop(audioUnit!)
        guard status == noErr else {
            logger.error("Failed to stop audio unit: \(status)")
            return
        }

        AudioFileClose(recordingFile!)
        isRecording = false
        logger.info("Recording stopped successfully")
    }

    func startPlaying() {
        guard !isPlaying else {
            logger.warning("Playback already in progress")
            return
        }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilePath = documentsPath.appendingPathComponent("recording.caf")

        var audioFile: AudioFileID?
        var status = AudioFileOpenURL(audioFilePath as CFURL, .readPermission, kAudioFileCAFType, &audioFile)
        guard status == noErr else {
            logger.error("Failed to open audio file for playback: \(status)")
            return
        }
        playbackFile = audioFile

        var dataSize: UInt64 = 0
        var propertySize = UInt32(MemoryLayout<UInt64>.size)
        status = AudioFileGetProperty(playbackFile!, kAudioFilePropertyAudioDataByteCount, &propertySize, &dataSize)
        guard status == noErr else {
            logger.error("Failed to get audio file size: \(status)")
            return
        }
        audioFileSize = Int64(dataSize)

        var callbackStruct = AURenderCallbackStruct(
            inputProc: playbackCallback,
            inputProcRefCon: Unmanaged.passUnretained(self).toOpaque()
        )
        status = AudioUnitSetProperty(audioUnit!, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &callbackStruct, UInt32(MemoryLayout<AURenderCallbackStruct>.size))
        guard status == noErr else {
            logger.error("Failed to set playback callback: \(status)")
            return
        }

        status = AudioOutputUnitStart(audioUnit!)
        guard status == noErr else {
            logger.error("Failed to start audio unit for playback: \(status)")
            return
        }

        isPlaying = true
        currentPacket = 0
        logger.info("Playback started successfully")
    }

    func stopPlaying() {
        guard isPlaying else {
            logger.warning("No playback in progress to stop")
            return
        }

        let status = AudioOutputUnitStop(audioUnit!)
        guard status == noErr else {
            logger.error("Failed to stop audio unit: \(status)")
            return
        }

        AudioFileClose(playbackFile!)
        isPlaying = false
        logger.info("Playback stopped successfully")
    }

    private let recordingCallback: AURenderCallback = { inRefCon, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData in
        let audioManager = Unmanaged<AudioUnitManager>.fromOpaque(inRefCon).takeUnretainedValue()
        guard audioManager.isRecording, let recordingFile = audioManager.recordingFile else { return noErr }

        var bufferList = AudioBufferList(
            mNumberBuffers: 1,
            mBuffers: AudioBuffer(
                mNumberChannels: 1,
                mDataByteSize: UInt32(inNumberFrames * 2),
                mData: nil
            )
        )

        let status = AudioUnitRender(audioManager.audioUnit!, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, &bufferList)
        guard status == noErr else {
            audioManager.logger.error("Failed to render audio: \(status)")
            return status
        }

        var inNumberPackets = inNumberFrames
        AudioFileWritePackets(recordingFile, false, inNumberFrames * 2,
                              nil, audioManager.currentPacket, &inNumberPackets,
                              bufferList.mBuffers.mData!)
        audioManager.currentPacket += Int64(inNumberPackets)

        return noErr
    }

    private let playbackCallback: AURenderCallback = { inRefCon, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData in
        let audioManager = Unmanaged<AudioUnitManager>.fromOpaque(inRefCon).takeUnretainedValue()
        guard audioManager.isPlaying, let playbackFile = audioManager.playbackFile, let ioData = ioData else { return noErr }

        let bufferList = UnsafeMutableAudioBufferListPointer(ioData)
        var numPackets = inNumberFrames
        var numBytes = UInt32(inNumberFrames * audioManager.recordingFormat.mBytesPerFrame)

        for i in 0..<bufferList.count {
            if let mData = bufferList[i].mData {
                let status = AudioFileReadPackets(playbackFile, false, &numBytes,
                                                  nil, audioManager.currentPacket, &numPackets,
                                                  mData)
                if status != noErr {
                    audioManager.logger.error("Failed to read packets: \(status)")
                    return status
                }
            }
        }

        if numPackets > 0 {
            audioManager.currentPacket += Int64(numPackets)
            for i in 0..<bufferList.count {
                bufferList[i].mDataByteSize = numBytes
            }
        } else {
            for i in 0..<bufferList.count {
                bufferList[i].mDataByteSize = 0
            }
            audioManager.stopPlaying()
        }

        return noErr
    }

}
