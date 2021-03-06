//
//  AEAudioController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/25/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import AVFoundation

final class AudioEngineController : AudioController {
    
    static let instance = AudioEngineController()
    static let AUDIO_BUFFER_QUEUE = DispatchQueue(label: "com.riaz.fahad.Kyooz.AudioBuffer")
    
    var currentPlaybackTime:Double {
        get {
            return Double(currentlyPlayingAudio.lastPlayedFrame)/Double(currentlyPlayingAudio.sampleRate)
        } set {
            let framePosition = AVAudioFramePosition(newValue) * AVAudioFramePosition(currentlyPlayingAudio.sampleRate)
            currentlyPlayingAudio.sourceAudioFile.framePosition = framePosition
            currentlyPlayingAudio.lastPlayedFrame = framePosition
            scheduleBuffers(AudioEngineController.NO_OF_INITIAL_BUFFERS, shouldInterrupt: true, validationCode:validationCode)
        }
    }
    
    var audioTrackIsLoaded:Bool {
        return currentlyPlayingAudio.sourceAudioFile != nil
    }
    
    var canScrobble:Bool {
        return currentlyPlayingAudio.canScrobble
    }
    
    var delegate:AudioControllerDelegate!
    
    private var audioEngine:AVAudioEngine = AVAudioEngine()
    private var playerNode:AVAudioPlayerNode = AVAudioPlayerNode()
    
    private static let SECONDS_PER_BUFFER:Double = 0.5
    private static let NO_OF_INITIAL_BUFFERS:Int = 2
    
    private var currentlyPlayingAudio:AudioFileWrapper = AudioFileWrapper(audioFile: nil)
    private var audioToBuffer:AudioFileWrapper = AudioFileWrapper(audioFile:nil)
    
    private var validationCode:UInt8 = 0

    
    init() {
        initializeAudioEngine()
    }
    
    private func initializeAudioEngine() {
        audioEngine.attach(playerNode)
        let mixer = audioEngine.mainMixerNode
        audioEngine.connect(playerNode, to: mixer, format: mixer.outputFormat(forBus: 0))
        audioEngine.prepare()
        
        playerNode.installTap(onBus: 0, bufferSize: currentlyPlayingAudio.defaultBufferCapacity, format: nil) { (buffer, time) -> Void in
            self.currentlyPlayingAudio.advanceFramesByAmount(AVAudioFramePosition(buffer.frameLength))
            if(self.currentlyPlayingAudio.playedToEndOfFile) {
                self.audioPlayerDidAdvanceToNextItem()
            }
        }
    }
    
    func play() -> Bool {
        if(!audioEngine.isRunning) {
            do {
                try audioEngine.start()
            } catch let error as NSError {
                Logger.debug("Error with starting audio engine: \(error.description)")
                return false
            } catch {
                Logger.debug("unknown error occured with starting audio enging")
                return false
            }
        }
        
        playerNode.play()
        return true
    }
    
    func pause() -> Bool {
        if(audioEngine.isRunning) {
            playerNode.pause()
            audioEngine.pause()
        }
        return true
    }
    
    func loadItem(_ url:URL) throws {
        let audioFile = try getAudioFile(url)
        currentlyPlayingAudio = AudioFileWrapper(audioFile:audioFile)
        audioToBuffer = currentlyPlayingAudio
        scheduleBuffers(AudioEngineController.NO_OF_INITIAL_BUFFERS, shouldInterrupt: true, validationCode:validationCode)
    }
    
    private func getAudioFile(_ url:URL) throws -> AVAudioFile {
       return try AVAudioFile(forReading: url)
    }
    
    private func readNextFramesIntoBuffer(_ validationCode:UInt8) {
        scheduleBuffers(1, validationCode:validationCode)
    }
    
    private func scheduleBuffers(_ numberOfBuffersToSchedule:Int, shouldInterrupt:Bool = false, validationCode:UInt8) {
        if(self.validationCode != validationCode) {
            return
        } else if(shouldInterrupt) {
            if(self.validationCode == UInt8.max) {
                self.validationCode = 0
            } else {
                self.validationCode += 1
            }
        }
        let newValidationCode = self.validationCode
        
        AudioEngineController.AUDIO_BUFFER_QUEUE.async {
            if(self.audioToBuffer.sourceAudioFile == nil) { return }
            
            for i in 0..<numberOfBuffersToSchedule {
                self.scheduleBuffer(newValidationCode, shouldInterrupt: shouldInterrupt && i == 0)
            }
        }
    }
    
    private func scheduleBuffer(_ newValidationCode:UInt8, shouldInterrupt:Bool) {
        let bufferToUse = AVAudioPCMBuffer(pcmFormat: audioToBuffer.sourceAudioFile.processingFormat, frameCapacity: audioToBuffer.defaultBufferCapacity)
        do {
            try audioToBuffer.sourceAudioFile.read(into: bufferToUse)
        } catch let error1 as NSError {
            Logger.error("Error with reading audio file into buffer: \(error1.localizedDescription)")
            return
        } catch {
            Logger.error("Unknown error occurred while scheduling buffers")
            return
        }
        
        
        var completionHandler = { self.readNextFramesIntoBuffer(newValidationCode) }
        
        if(audioToBuffer.bufferedToEndOfFile) {
            Logger.debug("reached end of audio file")
            if let url = delegate.audioPlayerDidRequestNextItemToBuffer(self), let nextAudioFile = try? getAudioFile(url) {
                audioToBuffer = AudioFileWrapper(audioFile: nextAudioFile)
                Logger.debug("loaded next audio file")
            } else {
                completionHandler = audioPlayerDidFinishPlaying
                audioToBuffer = AudioFileWrapper(audioFile:nil)
            }
        }
        
        if playerNode.outputFormat(forBus: 0).channelCount != bufferToUse.format.channelCount {
            Logger.debug("Reconnecting player node for new channel count \(bufferToUse.format.channelCount)")
            audioEngine.disconnectNodeOutput(playerNode)
            audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: bufferToUse.format)
            _ = play()
        }
        
        if(shouldInterrupt) {
            playerNode.scheduleBuffer(bufferToUse, at: nil, options: AVAudioPlayerNodeBufferOptions.interrupts, completionHandler: completionHandler)
        } else {
            playerNode.scheduleBuffer(bufferToUse, completionHandler: completionHandler)
        }
    }
    

    
    private func audioPlayerDidFinishPlaying() {
		KyoozUtils.doInMainQueueAsync() {
            self.delegate.audioPlayerDidFinishPlaying(self, successfully: true)
        }
    }
    
    
    private func audioPlayerDidAdvanceToNextItem() {
        Logger.debug("audio player advanced to next item")
        self.delegate.audioPlayerDidAdvanceToNextItem(self)
        self.currentlyPlayingAudio = self.audioToBuffer
    }
    
    private final class AudioFileWrapper {
        static let FOUR_MINUTES:Double = 4 * 60
        
        let sourceAudioFile:AVAudioFile!
        let lengthInSamples:AVAudioFramePosition
        let sampleRate:Double
        let defaultBufferCapacity:AVAudioFrameCount
        
        var lastPlayedFrame:AVAudioFramePosition
        
        private var numberOfFramesPlayed:AVAudioFramePosition = 0
        private var playedFramesNeededToScrobble:AVAudioFramePosition = 0
        
        var playedToEndOfFile:Bool {
            return lastPlayedFrame >= lengthInSamples
        }
        
        var bufferedToEndOfFile:Bool {
            return sourceAudioFile.framePosition >= lengthInSamples
        }
        
        var canScrobble:Bool {
            if(sourceAudioFile == nil) { return false }
            
            return numberOfFramesPlayed >= playedFramesNeededToScrobble
        }
        
        init(audioFile:AVAudioFile!) {
            sourceAudioFile = audioFile
            lastPlayedFrame = audioFile?.framePosition ?? 0
            lengthInSamples = audioFile?.length ?? 0
            sampleRate = audioFile?.processingFormat.sampleRate ?? 1
            
            if(audioFile != nil) {
                let fourMinutesInFrames = AVAudioFramePosition(AudioFileWrapper.FOUR_MINUTES * sampleRate)
                let halfLengthInFrames = lengthInSamples/2
                playedFramesNeededToScrobble = fourMinutesInFrames < halfLengthInFrames ? fourMinutesInFrames : halfLengthInFrames
            }
            
            defaultBufferCapacity = AVAudioFrameCount(sampleRate * AudioEngineController.SECONDS_PER_BUFFER)
        }
        
        func advanceFramesByAmount(_ frameAmount:AVAudioFramePosition) {
            lastPlayedFrame += frameAmount
            numberOfFramesPlayed += frameAmount
        }
    }
}
