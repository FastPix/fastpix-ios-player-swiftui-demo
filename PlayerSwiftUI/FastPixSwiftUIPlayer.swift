//
//  FastPixSwiftUIPlayer.swift
//  PlayerSwiftUI
//
//  Created by D. Neha Reddy on 27/03/26.
//

import SwiftUI
import AVKit
import AVFoundation
import FastPixPlayerSDK

// MARK: - 1.  ViewModel  (SwiftUI state bridge)

final class FastPixPlayerViewModel: ObservableObject {
    
    // Published so any SwiftUI overlay can react
    @Published var currentTitle: String     = ""
    @Published var isPlaying:    Bool       = false
    @Published var isLoading:    Bool       = false
    @Published var subtitleText: String     = ""
    @Published var showSubtitle: Bool       = false
    
    // Build whatever playlist you need here
    let playlist: [FastPixPlaylistItem] = [
        FastPixPlaylistItem(
            playbackId: "16ac212a-0f4f-49c5-9fd7-a42d9ff61541",
            title: "Sample-Video",
            duration: "02:45:00",
            token: "",
            drmToken: ""
        ),
        FastPixPlaylistItem(
            playbackId: "2125094c-db43-4748-90e1-18539f2ccf98",
            title: "AudioTracks & Subtitles",
            duration: "02:45:00",
            token: "",
            drmToken: ""
        )
    ]
}

// MARK: - 2.  UIViewControllerRepresentable

struct FastPixPlayerRepresentable: UIViewControllerRepresentable {
    
    @ObservedObject var viewModel: FastPixPlayerViewModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    func makeUIViewController(context: Context) -> FastPixPlayerHostVC {
        let vc = FastPixPlayerHostVC()
        vc.coordinator = context.coordinator
        vc.playlist    = viewModel.playlist
        context.coordinator.hostVC = vc
        return vc
    }
    
    func updateUIViewController(_ uiViewController: FastPixPlayerHostVC, context: Context) {
        // SwiftUI will call this when state changes; we don't need to push anything back.
    }
    
    
    // Coordinator – receives SDK delegate callbacks and forwards
    // them to the ViewModel so SwiftUI views can react.
    
    final class Coordinator:
        FastPixSeekDelegate,
        FastPixVolumeDelegate,
        FastPixSkipDelegate,
        FastPixAudioTrackDelegate,
        FastPixSubtitleTrackDelegate
    {
        weak var hostVC: FastPixPlayerHostVC?
        let viewModel: FastPixPlayerViewModel
        
        init(viewModel: FastPixPlayerViewModel) {
            self.viewModel = viewModel
        }
        
        // MARK: FastPixSeekDelegate
        func onBufferedTimeUpdate(loaded: TimeInterval, duration: TimeInterval) {
            hostVC?.seekBar.updateBuffer(loaded: loaded, duration: duration)
        }
        func onTimeUpdate(currentTime: TimeInterval, duration: TimeInterval) {
            hostVC?.seekBar.updateTime(current: currentTime, duration: duration)
        }
        func onSeekStart(at time: TimeInterval) {}
        func onSeekEnd(at time: TimeInterval) {
            guard let vc = hostVC else { return }
            let duration = vc.playerViewController.getDuration()
            vc.seekBar.updateTime(current: time, duration: duration)
        }
        
        // MARK: FastPixVolumeDelegate
        func fastPixVolumeDidChange(volume: Float, isMuted: Bool, isSystemChange: Bool) {
            DispatchQueue.main.async { [weak self] in
                guard let self, let vc = self.hostVC else { return }
                vc.volumeSlider.value = volume
                vc.updateMuteIcon(isMuted: isMuted)
                if isSystemChange { vc.showVolumeSliderTemporarily() }
            }
        }
        
        // MARK: FastPixSkipDelegate
        func onSkipVisibilityChanged(isVisible: Bool, segment: SkipSegment?) {
            guard let vc = hostVC else { return }
            if isVisible, let seg = segment {
                let title: String
                switch seg.type {
                case .intro:   title = "Skip Intro"
                case .credits: title = "Skip Credits"
                case .song:    title = "Skip Song"
                }
                vc.showSkipButton(title: title)
            } else {
                vc.hideSkipButton()
            }
        }
        func onSkipStarted()   { hostVC?.skipButton.isEnabled = false; hostVC?.skipButton.alpha = 0.6 }
        func onSkipCompleted() { hostVC?.skipButton.isEnabled = true;  hostVC?.hideSkipButton() }
        func onSkipFailed(error: SkipError) { hostVC?.skipButton.isEnabled = true; hostVC?.hideSkipButton() }
        
        // MARK: FastPixAudioTrackDelegate
        func onAudioTracksUpdated(tracks: [AudioTrack]) {
            hostVC?.updateSettingsButtonVisibility()
        }
        func onAudioTrackChange(selectedTrack: AudioTrack) {}
        func onAudioTrackFailed(error: AudioTrackError) {}
        func onAudioTrackSwitching(isSwitching: Bool) {}
        
        // MARK: FastPixSubtitleTrackDelegate
        func onSubtitlesLoaded(tracks: [SubtitleTrack]) {
            hostVC?.updateSettingsButtonVisibility()
        }
        func onSubtitleChange(track: SubtitleTrack?) {}
        func onSubtitlesLoadedFailed(error: SubtitleTrackError) {}
        func onSubtitleCueChange(information: SubtitleRenderInfo) {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if information.text.isEmpty {
                    self.viewModel.subtitleText = ""
                    self.viewModel.showSubtitle = false
                } else {
                    self.viewModel.subtitleText = information.text
                    self.viewModel.showSubtitle = true
                    self.hostVC?.playerViewController.view.bringSubviewToFront(
                        self.hostVC!.subtitleLabel
                    )
                }
            }
        }
    }
}

// MARK: - 3.  Host UIViewController

final class FastPixPlayerHostVC: UIViewController, AVPlayerViewControllerDelegate {
    
    // Set by the representable before viewDidLoad
    var coordinator: FastPixPlayerRepresentable.Coordinator?
    var playlist: [FastPixPlaylistItem] = []
    
    // MARK: Views (all programmatic – no storyboard)
    private let containerView = UIView()
    
    lazy var playerViewController = AVPlayerViewController()
    
    // Controls
    var seekBar          = FastPixSeekBar()
    var volumeSlider     = UISlider()
    var muteButton       = UIButton(type: .system)
    var skipButton       = UIButton(type: .system)
    var subtitleLabel    = UILabel()
    
    private var playPauseButton  = UIButton(type: .system)
    private var prevButton       = UIButton(type: .system)
    private var nextButton       = UIButton(type: .system)
    private var playlistButton   = UIButton(type: .system)
    private var audioTrackButton = UIButton(type: .system)
    private var rateLabel        = UILabel()
    private var titleLabel       = UILabel()
    
    // Internals
    private var seekBarBottomConstraint: NSLayoutConstraint!
    private var subtitleBottomConstraint: NSLayoutConstraint!
    private var playerStatusObserver: NSKeyValueObservation?
    private var loadingView: UIActivityIndicatorView?
    private var isUserSeeking    = false
    private var didSetupSeekUI   = false
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        buildContainerView()
        configureAudioSession()
        setupTitleLabel()
        setupPlayerViewController()
        
        setupSubtitleLabel()
        setupLoadingView()
        setupPlayPauseButton()
        
        playerViewController.fastPixVolumeDelegate = coordinator
        setupVolumeControls()
        setupPlaybackRateControls()
        
        playerViewController.addPlaylist(playlist)
        
        DispatchQueue.main.async { [weak self] in
            guard let self,
                  self.playerViewController.player != nil,
                  let coordinator = self.coordinator else { return }
            self.playerViewController.setupSkipManager(delegate: coordinator)
            self.setupSkipButton()
        }
        
        playerViewController.isLoopEnabled      = true
        playerViewController.isAutoPlayEnabled  = true
        playerViewController.setPlaybackSpeed(.x1)
        updateRateLabel()
        
        playerViewController.audioTrackDelegate    = coordinator
        playerViewController.subtitleTrackDelegate = coordinator
        
        setupAudioTrackButton()
        setupPlaylistStateObserver()
        playerViewController.hideDefaultControls = true
        setupSeekBar()
        
        if playerViewController.hasPlaylist && playerViewController.playlistCount > 1 {
            addCustomPlaylistControls()
            setupBottomControlsRow()
            updateButtonVisibility()
        }
        
        updateCurrentTitle()
        playerViewController.setupSeekManager(delegate: coordinator)
        
        if !didSetupSeekUI {
            didSetupSeekUI = true
            playerViewController.configureSeekButtons(
                enablePortrait: true,
                enableLandscape: true,
                forwardIncrement: 10,
                backwardIncrement: 10
            )
            playerViewController.fastpix_setupSeekButtons()
            styleSeekButtons()
        }
        
        let previewConfig = FastPixSeekPreviewConfig()
        playerViewController.loadSpritesheet(url: nil, previewEnable: true, config: previewConfig)
        playerViewController.setFallbackMode(.timestamp)
        
        setupPlayerStatusObserver()
        registerNotifications()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let popGesture = navigationController?.interactivePopGestureRecognizer,
           let sliderPan  = seekBar.panGestureRecognizer {
            popGesture.require(toFail: sliderPan)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if playerViewController.isPiPActive() { return }
        if isMovingFromParent || isBeingDismissed {
            playerViewController.pause()
            playerViewController.player = nil
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        seekBar.cancelActiveSeekIfNeeded()
        coordinator.animate(alongsideTransition: { _ in
            let isLandscape = size.width > size.height
            self.seekBarBottomConstraint.constant = isLandscape ? -24 : -40
            self.view.layoutIfNeeded()
        })
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        playerViewController.cleanupPlaylist()
    }
    
    // MARK: - Build container
    
    private func buildContainerView() {
        containerView.backgroundColor = .black
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Title label
    
    private func setupTitleLabel() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor    = .white
        titleLabel.font         = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    // MARK: - AVPlayerViewController
    
    private func setupPlayerViewController() {
        playerViewController.showsPlaybackControls = false
        playerViewController.allowsPictureInPicturePlayback = true
        playerViewController.canStartPictureInPictureAutomaticallyFromInline = true
        
        addChild(playerViewController)
        containerView.addSubview(playerViewController.view)
        playerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        playerViewController.didMove(toParent: self)
        let normalConstraints = [
            playerViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            playerViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
        let fullscreenConstraints = [
            playerViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            playerViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
        NSLayoutConstraint.activate(normalConstraints)
        
        view.bringSubviewToFront(titleLabel)
    }
    
    // MARK: - Subtitle label
    
    private func setupSubtitleLabel() {
        subtitleLabel.textColor       = .white
        subtitleLabel.font            = UIFont.systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textAlignment   = .center
        subtitleLabel.numberOfLines   = 0
        subtitleLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.isHidden        = true
        
        playerViewController.view.addSubview(subtitleLabel)
        playerViewController.view.bringSubviewToFront(subtitleLabel)
        
        subtitleBottomConstraint = subtitleLabel.bottomAnchor.constraint(
            equalTo: playerViewController.view.bottomAnchor, constant: -130
        )
        NSLayoutConstraint.activate([
            subtitleLabel.leadingAnchor.constraint(equalTo: playerViewController.view.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: playerViewController.view.trailingAnchor, constant: -20),
            subtitleBottomConstraint
        ])
        
        subtitleLabel.isHidden = true
        subtitleLabel.alpha = 0
    }
    
    // MARK: - Loading view
    
    private func setupLoadingView() {
        guard let overlay = playerViewController.contentOverlayView else { return }
        let loader = UIActivityIndicatorView(style: .large)
        loader.translatesAutoresizingMaskIntoConstraints = false
        loader.color = .white
        loader.hidesWhenStopped = true
        overlay.addSubview(loader)
        NSLayoutConstraint.activate([
            loader.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            loader.centerYAnchor.constraint(equalTo: overlay.centerYAnchor)
        ])
        self.loadingView = loader
    }
    
    func showLoader() { loadingView?.startAnimating() }
    func hideLoader() { loadingView?.stopAnimating() }
    
    private func makeSeekOverlay(iconName: String, text: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.layer.cornerRadius = 12; container.alpha = 0
        
        let stack = UIStackView(); stack.axis = .vertical; stack.alignment = .center; stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let icon = UIImageView(); icon.image = UIImage(systemName: iconName)
        icon.tintColor = .white; icon.contentMode = .scaleAspectFit
        
        let label = UILabel(); label.text = text; label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 14)
        
        stack.addArrangedSubview(icon); stack.addArrangedSubview(label)
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            container.widthAnchor.constraint(equalToConstant: 60),
            container.heightAnchor.constraint(equalToConstant: 50)
        ])
        return container
    }
    
    // MARK: - Player status observer
    
    private func setupPlayerStatusObserver() {
        guard let player = playerViewController.player else { return }
        playerStatusObserver = player.observe(\.timeControlStatus, options: [.new, .initial]) { [weak self] player, _ in
            DispatchQueue.main.async {
                self?.updatePlayPauseButton(for: player.timeControlStatus)
                switch player.timeControlStatus {
                case .waitingToPlayAtSpecifiedRate: self?.showLoader()
                case .playing, .paused:             self?.hideLoader()
                @unknown default: break
                }
            }
        }
    }
    
    private func updatePlayPauseButton(for status: AVPlayer.TimeControlStatus) {
        let name = (status == .playing) ? "pause.fill" : "play.fill"
        let icon = UIImage(systemName: name)?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 30, weight: .bold))
        playPauseButton.setImage(icon, for: .normal)
        coordinator?.viewModel.isPlaying = (status == .playing)
    }
    
    // MARK: - Play / Pause button
    
    private func setupPlayPauseButton() {
        guard let overlay = playerViewController.contentOverlayView else { return }
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.tintColor = .white
        playPauseButton.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        playPauseButton.layer.cornerRadius = 20
        playPauseButton.clipsToBounds = true
        let icon = UIImage(systemName: "pause.fill")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 18, weight: .bold))
        playPauseButton.setImage(icon, for: .normal)
        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
        overlay.addSubview(playPauseButton)
        NSLayoutConstraint.activate([
            playPauseButton.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            playPauseButton.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: 40),
            playPauseButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc private func playPauseTapped() {
        guard !isUserSeeking else { return }
        playerViewController.togglePlayPause()
        //        autoHideControls()
    }
    
    // MARK: - Seek bar
    
    private func setupSeekBar() {
        guard let overlay = playerViewController.contentOverlayView else { return }
        seekBar.translatesAutoresizingMaskIntoConstraints = false
        seekBar.layer.cornerRadius = 3; seekBar.clipsToBounds = true
        overlay.addSubview(seekBar)
        
        seekBarBottomConstraint = seekBar.bottomAnchor.constraint(equalTo: overlay.bottomAnchor, constant: -32)
        NSLayoutConstraint.activate([
            seekBar.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 16),
            seekBar.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -16),
            seekBar.heightAnchor.constraint(equalToConstant: 28),
            seekBarBottomConstraint
        ])
        
        playerViewController.view.addSubview(seekBar.previewView)
        playerViewController.view.bringSubviewToFront(seekBar.previewView)
        seekBar.previewView.frame   = CGRect(x: 0, y: 0, width: 160, height: 100)
        seekBar.previewView.isHidden = true
        
        seekBar.onSeekStart = { [weak self] _ in
            guard let self else { return }
            self.isUserSeeking = true
            self.playerViewController.seekManager?.cancelSeekIfNeeded()
        }
        seekBar.onSeekEnd = { [weak self] time in
            guard let self else { return }
            self.playerViewController.seek(to: time)
            self.isUserSeeking = false
            self.seekBar.previewView.imageView.image = nil
            self.seekBar.previewView.label.text = ""
            self.seekBar.previewView.isHidden = true
        }
        seekBar.onPreviewScrub = { [weak self] time in self?.updatePreview(at: time) }
        seekBar.onPreviewVisibilityChanged = { [weak self] visible, time in
            if visible { self?.updatePreview(at: time) }
        }
    }
    
    private func updatePreview(at time: TimeInterval) {
        let result = playerViewController.fastpixThumbnailForPreview(at: time)
        seekBar.updatePreviewThumbnail(result.image, time: time, useTimestamp: result.useTimestamp)
    }
    
    // MARK: - Seek buttons styling
    
    private func styleSeekButtons() {
        func apply(_ button: UIButton) {
            button.tintColor = .white
            button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            button.layer.cornerRadius = 24; button.clipsToBounds = true
            button.adjustsImageWhenHighlighted = false
        }
        if let f = playerViewController.fastpixForwardButton  { apply(f) }
        if let b = playerViewController.fastpixBackwardButton { apply(b) }
    }
    
    // MARK: - Volume controls
    
    private func setupVolumeControls() {
        guard let overlay = playerViewController.contentOverlayView else { return }
        
        volumeSlider.translatesAutoresizingMaskIntoConstraints = false
        volumeSlider.minimumValue = 0; volumeSlider.maximumValue = 1
        volumeSlider.value  = playerViewController.getCurrentVolume()
        volumeSlider.tintColor = .white
        volumeSlider.alpha  = 0; volumeSlider.isHidden = true
        volumeSlider.transform = CGAffineTransform(rotationAngle: -.pi / 2)
        volumeSlider.addTarget(self, action: #selector(volumeChanged(_:)), for: .valueChanged)
        
        muteButton.translatesAutoresizingMaskIntoConstraints = false
        muteButton.tintColor = .white
        updateMuteIcon(isMuted: playerViewController.getCurrentVolume() == 0)
        muteButton.addTarget(self, action: #selector(muteTapped), for: .touchUpInside)
        
        overlay.addSubview(volumeSlider); overlay.addSubview(muteButton)
        NSLayoutConstraint.activate([
            muteButton.widthAnchor.constraint(equalToConstant: 70),
            muteButton.heightAnchor.constraint(equalToConstant: 30),
            volumeSlider.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 16),
            volumeSlider.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            volumeSlider.widthAnchor.constraint(equalToConstant: 80),
            volumeSlider.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    @objc private func volumeChanged(_ sender: UISlider) {
        playerViewController.setVolume(sender.value)
        updateMuteIcon(isMuted: sender.value == 0)
    }
    
    @objc private func muteTapped() {
        playerViewController.toggleMute()
        let muted = playerViewController.isMuted()
        volumeSlider.value = muted ? 0 : playerViewController.getCurrentVolume()
        updateMuteIcon(isMuted: muted)
    }
    
    func updateMuteIcon(isMuted: Bool) {
        let name = isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill"
        muteButton.setImage(UIImage(systemName: name), for: .normal)
    }
    
    func showVolumeSliderTemporarily() {
        volumeSlider.isHidden = false
        UIView.animate(withDuration: 0.2) { self.volumeSlider.alpha = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            UIView.animate(withDuration: 0.2) { self.volumeSlider.alpha = 0 } completion: { _ in
                self.volumeSlider.isHidden = true
            }
        }
    }
    
    // MARK: - Playback rate
    
    private func setupPlaybackRateControls() {
        guard let overlay = playerViewController.contentOverlayView else { return }
        rateLabel.translatesAutoresizingMaskIntoConstraints = false
        rateLabel.textColor = .white; rateLabel.font = UIFont.boldSystemFont(ofSize: 14); rateLabel.text = "1.0x"
        let tap = UITapGestureRecognizer(target: self, action: #selector(showRateSheet))
        rateLabel.isUserInteractionEnabled = true; rateLabel.addGestureRecognizer(tap)
        
        let stack = UIStackView(arrangedSubviews: [rateLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.trailingAnchor.constraint(equalTo: muteButton.leadingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: overlay.bottomAnchor, constant: -70)
        ])
    }
    
    @objc private func showRateSheet() {
        let speeds: [Float] = [0.25,0.5,0.75,1.0,1.25,1.5,1.75,2.0]
        let alert = UIAlertController(title: "Playback Speed", message: nil, preferredStyle: .actionSheet)
        for s in speeds {
            alert.addAction(UIAlertAction(title: "\(s)x", style: .default) { [weak self] _ in
                guard let self else { return }
                let rateEnum = self.playbackRateEnum(from: s)
                self.playerViewController.setPlaybackSpeed(rateEnum)
                self.updateRateLabel()
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func updateRateLabel() { rateLabel.text = "\(playerViewController.currentPlaybackRate())x" }
    
    private func playbackRateEnum(from value: Float) -> FastPixPlaybackRateManager.PlaybackRate {
        switch value {
        case 0.25: return .x025; case 0.5: return .x05; case 0.75: return .x075
        case 1.25: return .x125; case 1.5: return .x15; case 1.75: return .x175; case 2.0: return .x2
        default: return .x1
        }
    }
    
    // MARK: - Audio track button
    
    private func setupAudioTrackButton() {
        guard let overlay = playerViewController.contentOverlayView else { return }
        audioTrackButton.translatesAutoresizingMaskIntoConstraints = false
        audioTrackButton.setImage(UIImage(systemName: "gearshape"), for: .normal)
        audioTrackButton.tintColor = .white
        audioTrackButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        audioTrackButton.layer.cornerRadius = 12; audioTrackButton.clipsToBounds = true
        audioTrackButton.addTarget(self, action: #selector(showAudioTracks), for: .touchUpInside)
        audioTrackButton.isHidden = true
        overlay.addSubview(audioTrackButton)
        NSLayoutConstraint.activate([
            audioTrackButton.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -16),
            audioTrackButton.bottomAnchor.constraint(equalTo: overlay.bottomAnchor, constant: -60),
            audioTrackButton.widthAnchor.constraint(equalToConstant: 24),
            audioTrackButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    @objc private func showAudioTracks() {
        let audioTracks    = playerViewController.getAudioTracks()
        let selectedAudio  = playerViewController.getCurrentAudioTrack()
        let subtitleTracks = playerViewController.getSubtitleTracks()
        let selectedSub    = playerViewController.getCurrentSubtitleTrack()
        
        let alert = UIAlertController(title: "Settings", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Audio Tracks", style: .default, handler: nil))
        for t in audioTracks {
            let title = t.id == selectedAudio?.id ? "✓  \(t.label)" : "    \(t.label)"
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.playerViewController.setAudioTrack(trackId: t.id)
            })
        }
        alert.addAction(UIAlertAction(title: "Subtitles", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: selectedSub == nil ? "✓  Off" : "    Off", style: .default) { [weak self] _ in
            self?.playerViewController.disableSubtitles()
        })
        for t in subtitleTracks {
            let title = t.id == selectedSub?.id ? "✓  \(t.label)" : "    \(t.label)"
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                try? self?.playerViewController.setSubtitleTrack(trackId: t.id)
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    func updateSettingsButtonVisibility() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self else { return }
            let hasContent = self.playerViewController.getAudioTracks().count > 1
            || !self.playerViewController.getSubtitleTracks().isEmpty
            self.audioTrackButton.isHidden = !hasContent
        }
    }
    
    // MARK: - Skip button
    
    private func setupSkipButton() {
        guard let overlay = playerViewController.contentOverlayView else { return }
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.alpha = 0; skipButton.isHidden = true
        skipButton.setTitle("Skip", for: .normal); skipButton.setTitleColor(.white, for: .normal)
        skipButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        skipButton.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        skipButton.layer.cornerRadius = 18
        skipButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        overlay.addSubview(skipButton)
        NSLayoutConstraint.activate([
            skipButton.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -16),
            skipButton.bottomAnchor.constraint(equalTo: overlay.bottomAnchor, constant: -140)
        ])
    }
    
    @objc private func skipTapped() {
        playerViewController.skipManager?.skipCurrentSegment()
        hideSkipButton()
    }
    
    func showSkipButton(title: String) {
        skipButton.setTitle(title, for: .normal); skipButton.isHidden = false
        skipButton.superview?.bringSubviewToFront(skipButton)
        UIView.animate(withDuration: 0.25) { self.skipButton.alpha = 1 }
    }
    
    func hideSkipButton() {
        UIView.animate(withDuration: 0.25, animations: { self.skipButton.alpha = 0 }) { _ in
            self.skipButton.isHidden = true
        }
    }
    
    // MARK: - Playlist controls (prev / next / playlist)
    
    private func addCustomPlaylistControls() {
        guard let overlay = playerViewController.contentOverlayView else { return }
        
        func configure(_ button: UIButton, action: Selector) {
            button.translatesAutoresizingMaskIntoConstraints = false
            button.tintColor = .white; button.setTitleColor(.white, for: .normal)
            button.addTarget(self, action: action, for: .touchUpInside)
            overlay.addSubview(button)
        }
        configure(prevButton,     action: #selector(prevTapped))
        configure(nextButton,     action: #selector(nextTapped))
        configure(playlistButton, action: #selector(showPlaylist))
        
        NSLayoutConstraint.activate([
            prevButton.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 20),
            prevButton.bottomAnchor.constraint(equalTo: overlay.bottomAnchor, constant: -70),
            prevButton.widthAnchor.constraint(equalToConstant: 50),
            prevButton.heightAnchor.constraint(equalToConstant: 50),
            
            nextButton.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -20),
            nextButton.bottomAnchor.constraint(equalTo: overlay.bottomAnchor, constant: -70),
            nextButton.widthAnchor.constraint(equalToConstant: 50),
            nextButton.heightAnchor.constraint(equalToConstant: 50),
            
            playlistButton.leadingAnchor.constraint(equalTo: prevButton.trailingAnchor, constant: 16),
            playlistButton.trailingAnchor.constraint(equalTo: nextButton.leadingAnchor, constant: -16),
            playlistButton.centerYAnchor.constraint(equalTo: prevButton.centerYAnchor)
        ])
    }
    
    private func setupBottomControlsRow() {
        guard let overlay = playerViewController.contentOverlayView else { return }
        
        func style(_ b: UIButton, icon: String) {
            let cfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
            b.setImage(UIImage(systemName: icon, withConfiguration: cfg), for: .normal)
            b.tintColor = .white
            b.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            b.layer.cornerRadius = 25; b.clipsToBounds = true
            b.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                b.widthAnchor.constraint(equalToConstant: 32),
                b.heightAnchor.constraint(equalToConstant: 32)
            ])
        }
        style(prevButton,     icon: "backward.fill")
        style(nextButton,     icon: "forward.fill")
        style(playlistButton, icon: "play.square.stack.fill")
        style(muteButton,     icon: "speaker.slash.fill")
        
        rateLabel.textColor = .white
        rateLabel.font = UIFont.boldSystemFont(ofSize: 16); rateLabel.textAlignment = .center
        
        let bottomStack = UIStackView(arrangedSubviews: [
            prevButton, UIStackView(arrangedSubviews: [rateLabel]),
            playlistButton, muteButton, audioTrackButton, nextButton
        ])
        bottomStack.axis = .horizontal; bottomStack.alignment = .center
        bottomStack.distribution = .equalSpacing; bottomStack.spacing = 12
        bottomStack.translatesAutoresizingMaskIntoConstraints = false
        
        let bg = UIView(); bg.layer.cornerRadius = 30; bg.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(bg); overlay.addSubview(bottomStack)
        
        NSLayoutConstraint.activate([
            bg.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 15),
            bg.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -15),
            bg.bottomAnchor.constraint(equalTo: overlay.bottomAnchor, constant: -60),
            bg.heightAnchor.constraint(equalToConstant: 60),
            
            bottomStack.leadingAnchor.constraint(equalTo: bg.leadingAnchor, constant: 10),
            bottomStack.trailingAnchor.constraint(equalTo: bg.trailingAnchor, constant: -10),
            bottomStack.centerYAnchor.constraint(equalTo: bg.centerYAnchor)
        ])
    }
    
    private func updateButtonVisibility() {
        playerViewController.updatePlaylistButtonVisibility(prevButton: prevButton, nextButton: nextButton)
    }
    
    private func updateCurrentTitle() {
        titleLabel.text = playerViewController.currentPlaylistItem?.title ?? ""
        coordinator?.viewModel.currentTitle = titleLabel.text ?? ""
    }
    
    @objc private func prevTapped() {
        if playerViewController.previous() { handlePlaylistItemChange() }
    }
    
    @objc private func nextTapped() {
        if playerViewController.next() { handlePlaylistItemChange() }
    }
    
    @objc private func showPlaylist() {
        guard playerViewController.hasPlaylist else { return }
        let alert = UIAlertController(title: "Playlist", message: nil, preferredStyle: .actionSheet)
        let current = playerViewController.currentPlaylistIndex
        for i in 0..<playerViewController.playlistCount {
            if let item = playerViewController.playlistItem(at: i) {
                alert.addAction(UIAlertAction(title: item.title, style: .default) { [weak self] _ in
                    guard i != current, let self else { return }
                    self.playerViewController.jumpTo(index: i)
                    self.handlePlaylistItemChange()
                })
            }
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func handlePlaylistItemChange() {
        resetSubtitleState()
        seekBar.resetBuffer()
        playerViewController.clearSpritesheet()
        seekBar.previewView.isHidden = true
        playerViewController.setupSeekManager(delegate: coordinator)
        updateCurrentTitle(); updateButtonVisibility()
        let previewConfig = FastPixSeekPreviewConfig()
        playerViewController.loadSpritesheet(url: nil, previewEnable: true, config: previewConfig)
        playerViewController.setFallbackMode(.timestamp)
    }
    
    // MARK: - Playlist state observer
    
    private func setupPlaylistStateObserver() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(playlistStateChanged(_:)),
            name: Notification.Name("FastPixPlaylistStateChanged"), object: playerViewController
        )
    }
    
    @objc private func playlistStateChanged(_ notification: Notification) {
        showLoader()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.resetSubtitleState()
            self.seekBar.resetBuffer()
            self.playerViewController.clearSpritesheet()
            self.seekBar.previewView.isHidden = true
            self.playerViewController.setupSeekManager(delegate: self.coordinator)
            self.updateCurrentTitle(); self.updateButtonVisibility()
            self.playerViewController.skipManager?.clearSegments()
            self.hideSkipButton()
            
            if let item = notification.object as? FastPixPlaylistItem, !item.skipSegments.isEmpty {
                self.playerViewController.skipManager?.setSkipSegments(item.skipSegments)
            }
            
            let cfg = FastPixSeekPreviewConfig()
            self.playerViewController.loadSpritesheet(url: nil, previewEnable: true, config: cfg)
            self.playerViewController.setFallbackMode(.timestamp)
        }
    }
    
    private func resetSubtitleState() {
        audioTrackButton.isHidden = true
        subtitleLabel.text = ""; subtitleLabel.isHidden = true
    }
    
    // MARK: - Audio session
    
    private func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    // MARK: - Notifications
    
    private func registerNotifications() {
        let notification = NotificationCenter.default
        notification.addObserver(self, selector: #selector(appDidBecomeActive),
                                 name: UIApplication.didBecomeActiveNotification, object: nil)
        notification.addObserver(self, selector: #selector(handlePlaybackStalled),
                                 name: Notification.Name("PlaybackStalled"), object: playerViewController)
        notification.addObserver(self, selector: #selector(handlePlaybackResumed),
                                 name: Notification.Name("PlaybackResumed"), object: playerViewController)
        notification.addObserver(self, selector: #selector(handleAppWillResignActive),
                                 name: UIApplication.willResignActiveNotification, object: nil)
        notification.addObserver(self, selector: #selector(handleAppDidEnterBackground),
                                 name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    @objc private func appDidBecomeActive() {
        if let s = playerViewController.player?.timeControlStatus { updatePlayPauseButton(for: s) }
    }
    @objc private func handleAppWillResignActive()    { seekBar.cancelActiveSeekIfNeeded() }
    @objc private func handleAppDidEnterBackground()  { seekBar.cancelActiveSeekIfNeeded() }
    
    @objc private func handlePlaybackStalled() {
        showLoader()
        seekBar.isUserInteractionEnabled = false
        playPauseButton.isEnabled = false
        prevButton.isEnabled = false; nextButton.isEnabled = false
    }
    
    @objc private func handlePlaybackResumed() {
        hideLoader()
        seekBar.isUserInteractionEnabled = true
        playPauseButton.isEnabled = true
        prevButton.isEnabled = true; nextButton.isEnabled = true
    }
}

// MARK: - 4.  SwiftUI Entry Point
struct FastPixPlayerView: View {
    @StateObject private var viewModel = FastPixPlayerViewModel()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            FastPixPlayerRepresentable(viewModel: viewModel)
                .ignoresSafeArea()
            
            if viewModel.showSubtitle {
                Text(viewModel.subtitleText)
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(6)
                    .multilineTextAlignment(.center)
                    .allowsHitTesting(false)
                    .padding(.bottom, 100) // sits above seekbar (28pt) + controls row (60pt) + spacing
            }
        }
        .background(Color.black)
        .navigationBarHidden(true)
    }
}

// MARK: - 6.  Preview
struct FastPixPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        FastPixPlayerView()
    }
}
