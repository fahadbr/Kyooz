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
    static let AUDIO_BUFFER_QUEUE = dispatch_queue_create("com.riaz.fahad.Kyooz.AudioBuffer", DISPATCH_QUEUE_SERIAL)
    
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
        audioEngine.attachNode(playerNode)
        let mixer = audioEngine.mainMixerNode
        audioEngine.connect(playerNode, to: mixer, format: mixer.outputFormatForBus(0))
        audioEngine.prepare()
        
        playerNode.installTapOnBus(0, bufferSize: currentlyPlayingAudio.defaultBufferCapacity, format: nil) { (buffer, time) -> Void in
            self.currentlyPlayingAudio.advanceFramesByAmount(AVAudioFramePosition(buffer.frameLength))
            if(self.currentlyPlayingAudio.playedToEndOfFile) {
                self.audioPlayerDidAdvanceToNextItem()
            }
        }
    }
    
    func play() -> Bool {
        if(!audioEngine.running) {
            var error:NSError?
            let successful: Bool
            do {
                try audioEngine.start()
                successful = true
            } catch let error1 as NSError {
                error = error1
                successful = false
            }
            if(!successful || error != nil) {
                Logger.debug("Error with starting audio engine: \(error?.description)")
                return false
            }
        }
        
        playerNode.play()
        return audioEngine.running && playerNode.playing
    }
    
    func pause() -> Bool {
        if(audioEngine.running) {
            playerNode.pause()
            audioEngine.pause()
        }
        return !playerNode.playing && !audioEngine.running
    }
    
    func loadItem(url:NSURL) -> Bool {
        if let audioFile = getAudioFile(url) {
            currentlyPlayingAudio = AudioFileWrapper(audioFile:audioFile)
            audioToBuffer = currentlyPlayingAudio
            scheduleBuffers(AudioEngineController.NO_OF_INITIAL_BUFFERS, shouldInterrupt: true, validationCode:validationCode)
            return true
        }
        return false
    }
    
    private func getAudioFile(url:NSURL) -> AVAudioFile! {
        var error:NSError?
        do {
            let audioFile = try AVAudioFile(forReading: url)
            if(error != nil) {
                Logger.debug("Error with loading audio file: \(error!.localizedDescription)")
                return nil
            }
            
            return audioFile
        } catch let error1 as NSError {
            error = error1
        }
        return nil
    }
    
    private func readNextFramesIntoBuffer(validationCode:UInt8) {
        scheduleBuffers(1, validationCode:validationCode)
    }
    
    private func scheduleBuffers(numberOfBuffersToSchedule:Int, shouldInterrupt:Bool = false, validationCode:UInt8) {
        if(self.validationCode != validationCode) {
            Logger.debug("canceling buffer")
            return
        } else if(shouldInterrupt) {
            if(self.validationCode == UInt8.max) {
                self.validationCode = 0
            } else {
                self.validationCode++
            }
        }
        let newValidationCode = self.validationCode
        
        dispatch_async(AudioEngineController.AUDIO_BUFFER_QUEUE) {
            if(self.audioToBuffer.sourceAudioFile == nil) { return }
            
            for i in 0..<numberOfBuffersToSchedule {
                
                let bufferToUse = AVAudioPCMBuffer(PCMFormat: self.audioToBuffer.sourceAudioFile.processingFormat, frameCapacity: self.audioToBuffer.defaultBufferCapacity)
                do {
                    try self.audioToBuffer.sourceAudioFile.readIntoBuffer(bufferToUse)
                } catch let error1 as NSError {
					Logger.error("Error with reading audio file into buffer: \(error1.localizedDescription)")
					return
                } catch {
                    Logger.error("Unknown error occurred while scheduling buffers")
					return
                }
				
                
                var completionHandler = { self.readNextFramesIntoBuffer(newValidationCode) }
                
                if(self.audioToBuffer.bufferedToEndOfFile) {
                    Logger.debug("reached end of audio file")
                    if let url = self.delegate.audioPlayerDidRequestNextItemToBuffer(self), nextAudioFile = self.getAudioFile(url) {
                        self.audioToBuffer = AudioFileWrapper(audioFile: nextAudioFile)
                        Logger.debug("loaded next audio file")
                    } else {
                        completionHandler = self.audioPlayerDidFinishPlaying
                        self.audioToBuffer = AudioFileWrapper(audioFile:nil)
                    }
                }
                
                if(shouldInterrupt && i == 0) {
                    self.playerNode.scheduleBuffer(bufferToUse, atTime: nil, options: AVAudioPlayerNodeBufferOptions.Interrupts, completionHandler: completionHandler)
                } else {
                    self.playerNode.scheduleBuffer(bufferToUse, completionHandler: completionHandler)
                }
            }
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
        
        func advanceFramesByAmount(frameAmount:AVAudioFramePosition) {
            lastPlayedFrame += frameAmount
            numberOfFramesPlayed += frameAmount
        }
    }
}