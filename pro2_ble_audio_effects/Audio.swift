//
//  audio.swift
//  pro2_ble_audio_effects
//
//  Created by Fuji Hiromu on 2017/10/28.
//  Copyright © 2017 藤　大夢. All rights reserved.
//

import UIKit
import AVFoundation

open class Audio: NSObject {
    let MAX_GAIN: Float = 24.0
    let MIN_GAIN: Float = -96.0
    
    var audioEngine: AVAudioEngine!
    var audioFilePlayer: AVAudioPlayerNode!
    var audioReverb: AVAudioUnitReverb!
    var audioDelay: AVAudioUnitDelay!
    var audioFile: AVAudioFile!
    var audioSpeed: AVAudioUnitTimePitch!
    var audioUnitEQ = AVAudioUnitEQ(numberOfBands: 5)
    
    var musicCount = 1
    
    override init(){
    
        // AudioEngineの生成
        audioEngine = AVAudioEngine()
        
        // AVPlayerNodeの生成
        audioFilePlayer = AVAudioPlayerNode()
        
        // AVAudioFileの生成
        audioFile = try! AVAudioFile(forReading: Bundle.main.url(forResource: "music", withExtension: "mp3")!)
        
        // ReverbNodeの生成
        audioReverb = AVAudioUnitReverb()
        audioReverb.loadFactoryPreset(.largeHall2)
        audioReverb.wetDryMix = 0
        
        // DelayNodeの生成
        audioDelay = AVAudioUnitDelay()
        audioDelay.delayTime = 0.5
        audioDelay.feedback = 70
        audioDelay.lowPassCutoff = 18000
        audioDelay.wetDryMix = 10
        
        // TimePitchの生成
        audioSpeed = AVAudioUnitTimePitch()
        audioSpeed.rate = 1
        
        //Eqの生成
        let FREQUENCY: [Float] = [400, 1000, 2500, 6300, 16000]
        for i in 0...4 {
            audioUnitEQ.bands[i].filterType = .parametric
            audioUnitEQ.bands[i].frequency = FREQUENCY[i]
            audioUnitEQ.bands[i].bandwidth = 0.5 // half an octave
            audioUnitEQ.bands[i].gain = 0
            audioUnitEQ.bands[i].bypass = false
        }
        audioUnitEQ.bypass = true
        
        // AVPlayerNodeとReverbNodeとDelayNodeをAVAudioEngineへ追加
        audioEngine.attach(audioFilePlayer)
        audioEngine.attach(audioReverb)
        audioEngine.attach(audioDelay)
        audioEngine.attach(audioSpeed)
        audioEngine.attach(audioUnitEQ)
        // AVPlayerNodeとReverbNodeとDelayNodeをAVAudioEngineへ接続
        audioEngine.connect(audioFilePlayer, to: audioReverb, format: audioFile.processingFormat)
        audioEngine.connect(audioReverb, to: audioDelay, format: audioFile.processingFormat)
        audioEngine.connect(audioDelay, to: audioSpeed, format: audioFile.processingFormat)
        audioEngine.connect(audioSpeed, to: audioUnitEQ, format: audioFile.processingFormat)
        audioEngine.connect(audioUnitEQ, to: audioEngine.mainMixerNode, format: audioFile.processingFormat)
        
        // AVAudioEngineの開始
        try! audioEngine.start()
        print(audioEngine.isRunning)
        
        
        
    }
    
  
    
    public func buttonPlayPressed(isPlay : Bool) {
        if (isPlay) {
            audioFilePlayer.pause()
            
        } else {
            audioFilePlayer.scheduleFile(audioFile, at: nil, completionHandler: nil)
            audioFilePlayer.play()
            
      
        }
    }
    
    public func sliderReverbChanged(value : Float) {
        audioReverb.wetDryMix = value
    }
    
    public func sliderDelayTimeChanged(value : Float){
        audioDelay.delayTime = TimeInterval(value)
    }
    
    public func sliderFeedbackChanged(value : Float){
        audioDelay.feedback = value
    }
    
    public func sliderLowPassCutOff(value : Float) {
        audioDelay.lowPassCutoff = value
    }
    
    public func sliderWetDryMix(value : Float){
        audioDelay.wetDryMix = value
    }
    public func sliderSpeed(value : Float) {
        audioSpeed.rate = value
    }
    
    public func musicChanged(isPlay : Bool,Num : Bool){
      
        if(Num){
            audioFilePlayer.stop()
            // AVAudioFileの生成
            audioFile = try! AVAudioFile(forReading: Bundle.main.url(forResource: "music2", withExtension: "mp3")!)
            audioFilePlayer.scheduleFile(audioFile, at: nil, completionHandler: nil)
            if(isPlay){
                audioFilePlayer.play()
            }
            
        }else{
            audioFilePlayer.stop()
            // AVAudioFileの生成
            audioFile = try! AVAudioFile(forReading: Bundle.main.url(forResource: "music", withExtension: "mp3")!)
            audioFilePlayer.scheduleFile(audioFile, at: nil, completionHandler: nil)
            if(isPlay){
                audioFilePlayer.play()
            }
        }
        
    }
    
    public func sliderPitch(value : Float){
        audioSpeed.pitch = value
    }
    
    public func sliderGain(value : Float,num : Int){
        let band = self.audioUnitEQ.bands[num]
        band.gain = value
    }
    
    public func sliderVolumeChange(value : Float){
         audioFilePlayer.volume = value
    }
    
}
