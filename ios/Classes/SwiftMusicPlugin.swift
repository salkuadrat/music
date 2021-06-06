import Flutter
import UIKit

import AVKit
import AVFoundation
import MediaPlayer

public class SwiftMusicPlugin: NSObject, FlutterPlugin {

  let positionUpdateInterval = TimeInterval(0.1)

  var playPauseTarget: Any?
  var nextTrackTarget: Any?
  var previousTrackTarget: Any?
  var changePlaybackPositionTarget: Any?

  var player: AVPlayer?
  let audioSession: AVAudioSession
  let channel: FlutterMethodChannel

  var positionTimer: Timer?
  var duration: Double?
  var position = 0.0

  var title = ""
  var album = ""
  var artist = ""
  var image: UIImage?

  var itemStatusObserver: NSKeyValueObservation?
  var timeControlStatusObserver: NSKeyValueObservation?
  var durationObserver: NSKeyValueObservation?

  init(_ channel: FlutterMethodChannel) {
    self.channel = channel
    self.audioSession = AVAudioSession.sharedInstance()
    super.init()
  }

  private func getPlayer() -> AVPlayer {
    if self.player != nil { 
      return player! 
    }

    let player = AVPlayer()
    player.automaticallyWaitsToMinimizeStalling = false
    self.player = player
    
    timeControlStatusObserver = player.observe(\AVPlayer.timeControlStatus) { [unowned self] player, _ in
      self.timeControlStatusChanged(player.timeControlStatus)
    }

    let commandCenter = MPRemoteCommandCenter.shared()
    
    commandCenter.togglePlayPauseCommand.isEnabled = true
    playPauseTarget = commandCenter.togglePlayPauseCommand
      .addTarget(handler: { (event) in
        if player.timeControlStatus == AVPlayer.TimeControlStatus.paused {
          self.resume()
        } else {
          self.pause()
        }
        return .success
      })

    commandCenter.nextTrackCommand.isEnabled = true
    nextTrackTarget = commandCenter.nextTrackCommand
      .addTarget(handler: { (event) in
        self.channel.invokeMethod("onPlayNext", arguments: nil)
        return .success
      })

    commandCenter.previousTrackCommand.isEnabled = true
    previousTrackTarget = commandCenter.previousTrackCommand
      .addTarget(handler: { (event) in
        self.channel.invokeMethod("onPlayPrevious", arguments: nil)
        return .success
      })
    
    commandCenter.changePlaybackPositionCommand.isEnabled = true
    changePlaybackPositionTarget = commandCenter
      .changePlaybackPositionCommand
      .addTarget(handler: { (remoteEvent) in
        if let event = remoteEvent as MPChangePlaybackPositionCommandEvent {
          player.seek(to: CMTime(
            seconds: event.positionTime, 
            preferredTimescale: CMTimeScale(1000)
          ))
          return .success
        }

        return .commandFailed
      })
    
    return player
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "salkuadrat/musicplayer", 
      binaryMessenger: registrar.messenger())
    
    let instance = SwiftMusicplayerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
      case "play":
        do {
          try play(call.arguments as! NSDictionary)
        } catch {
          print("MusicPlayer error")
        }
        result(true)
        break
      case "pause":
        pause()
        result(true)
        reak
      case "stop":
        stop()
        result(true)
        break
      case "resume":
        resume()
        result(true)
        break
      case "seek":
        seek(call.arguments as! Double)
        result(true)
        break
      case "cancel":
        result(true)
        break
      default:
        throw MusicPlayerError.unknownMethod
    }
  }

  func updateInfoCenter() {
    if (self.player == nil) { 
      return
    }
    
    let player = self.player!
    var songInfo = [String : Any]()
    songInfo[MPNowPlayingInfoPropertyPlaybackRate] = 
      player.timeControlStatus == AVPlayer.TimeControlStatus.playing 
      ? 1.0 : 0.0
    
    songInfo[MPMediaItemPropertyTitle] = title
    songInfo[MPMediaItemPropertyAlbumTitle] = album
    songInfo[MPMediaItemPropertyArtist] = artist
    
    if duration != nil {
      songInfo[MPMediaItemPropertyPlaybackDuration] =  duration! / 1000
      songInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] =  (position * duration!) / 1000
    }
    if (image != nil) {
      songInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork.init(image: image!)
    }
    
    MPNowPlayingInfoCenter.default().nowPlayingInfo = songInfo
    MPNowPlayingInfoCenter.default().playbackState = 
      player.rate == 0.0 ? .paused : .playing
  }

  func setImage(_ imageFilename: String) throws {
    let documentsUrl =  FileManager.default.urls(
      for: .cachesDirectory, 
      in: .userDomainMask
    ).first!

    let imageUrl = documentsUrl.appendingPathComponent(imageFilename)
    let imageData = try Data.init(contentsOf: imageUrl)
    image = UIImage.init(data: imageData)
  }

  func play(_ params: NSDictionary) throws {
    let player = getPlayer()
    
    try audioSession.setCategory(.playback, mode: .default, options: [])
    try audioSession.setActive(true)
    
    self.duration = nil
    position = 0.0
    positionTimer?.invalidate()
    positionTimer = nil
    
    let urlString = params["url"] as! String
    let url = URL.init(string: urlString)
    if url == nil {
      throw MusicPlayerError.invalidUrl
    }
    
    title = params["title"] as! String
    artist = params["artist"] as! String
    album = params["album"] as? String
    
    let imageFilename = params["image"]
    if imageFilename != nil && imageFilename is String {
      try setImage(imageFilename as! String)
    }
    
    updateInfoCenter()
    
    let playerItem = AVPlayerItem.init(url: url!)

    itemStatusObserver = playerItem.observe(\AVPlayerItem.status) { 
      [unowned self] playerItem, _ in
      self.itemStatusChanged(playerItem.status)
    }
    
    durationObserver = playerItem.observe(\AVPlayerItem.duration) { 
      [unowned self] playerItem, _ in
      self.durationChanged()
    }
    
    player.replaceCurrentItem(with: playerItem)
    player.playImmediately(atRate: 1.0)

    NotificationCenter.default.addObserver(
      self, 
      selector: #selector(audioDidPlayToEnd), 
      name: .AVPlayerItemDidPlayToEndTime, 
      object: playerItem
    )
  }

  func pause() {
    player?.pause()
  }
  
  func stop() {
    if self.player == nil { 
      return 
    }
    
    let player = self.player!
    self.player = nil
    
    itemStatusObserver?.invalidate()
    durationObserver?.invalidate()
    positionTimer?.invalidate()
    
    player.pause()
    player.replaceCurrentItem(with: nil)

    let commandCenter = MPRemoteCommandCenter.shared();
    commandCenter.togglePlayPauseCommand.removeTarget(playPauseTarget)
    commandCenter.nextTrackCommand.removeTarget(nextTrackTarget)
    commandCenter.previousTrackCommand.removeTarget(previousTrackTarget)
    commandCenter.changePlaybackPositionCommand.removeTarget(changePlaybackPositionTarget)

    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
  }
  
  func resume() {
    player?.play()
  }

  func seek(_ positionPercent: Double) {
    if self.player == nil { 
      return 
    }
    
    let player = self.player!

    if (duration == nil || player.currentItem == nil) { 
      return
    }

    let to = CMTime.init(
      seconds: (duration! * positionPercent) / 1000, 
      preferredTimescale: 1)

    let tolerance = CMTime.init(
      seconds: 0.1, 
      preferredTimescale: 1)
    
    player.currentItem!.seek(
      to: to, 
      toleranceBefore: tolerance, 
      toleranceAfter: tolerance)
  }
  
  @objc func audioDidPlayToEnd() {
    channel.invokeMethod("onCompleted", arguments: nil)
  }

  func timeControlStatusChanged(_ status: AVPlayer.TimeControlStatus) {
    switch (status) {
      case AVPlayer.TimeControlStatus.playing:
        print("Playing.")
        channel.invokeMethod("onPlaying", arguments: nil)
        break
      case AVPlayer.TimeControlStatus.paused:
        print("Paused.")
        channel.invokeMethod("onPaused", arguments: nil)
        break
      case AVPlayer.TimeControlStatus.waitingToPlayAtSpecifiedRate:
        print("Waiting to play...")
        channel.invokeMethod("onLoading", arguments: nil)
        break
    }

    updateInfoCenter()
  }

  func durationChanged() {
    if self.player == nil { 
      return
    }

    let player = self.player!
    
    var currentDuration: Double?
    
    if player.currentItem != nil && 
      !CMTIME_IS_INDEFINITE(player.currentItem!.duration) {
      currentDuration = player.currentItem!.duration.seconds * 1000
    }
    
    if currentDuration != nil && currentDuration != duration {
      duration = currentDuration
      channel.invokeMethod("onDuration", arguments: lround(duration!))
    }

    updateInfoCenter()
  }

  func positionChanged(timer: Timer) {
    if self.player == nil { 
      return 
    }

    let player = self.player!
    
    if duration == nil || 
      player.currentItem == nil || 
      CMTIME_IS_INDEFINITE(player.currentItem!.currentTime()) {
      return
    }
    
    let currentPos = player.currentItem!.currentTime().seconds * 1000
    let currentPosPercent = currentPos / duration!
    
    if currentPosPercent != position {
      position = currentPosPercent
      channel.invokeMethod("onPosition", arguments: currentPos)
    }
  }

  func itemStatusChanged(_ status: AVPlayerItem.Status) {
    switch status {
      case .readyToPlay:
        positionTimer = Timer.scheduledTimer(
          withTimeInterval: positionUpdateInterval, 
          block:  self.positionChanged,
          repeats: true)
        break
      case .failed:
        channel.invokeMethod("onError", arguments: "Playback failed")
        break
      case .unknown:
        channel.invokeMethod("onError", arguments: "Unknown error")
        break
    }
  }
}
