//
//  InterfaceController.swift
//  AnodaTurnTimerWatch Extension
//
//  Created by Alexander Kravchenko on 5/23/18.
//  Copyright © 2018 ANODA. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity
import ReSwift

class TransitionHelper: NSObject {
    //    var delegate: TimeIntervalPickerDelegate?
}

class MainController: WKInterfaceController, StoreSubscriber {
    
    @IBOutlet private var ibSettingsButton: WKInterfaceButton!
    @IBOutlet private var ibTimerButton: WKInterfaceButton!
    
    let session = WCSession.default
    private var timer: TimerService?
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        updateTimerLabel()
        setupSession()
        timer = TimerService()
    }
    
    override func willActivate() {
        super.willActivate()
        store.subscribe(self)
        { $0.select({ $0.roundAppState }).skipRepeats({$0 == $1})}
    }
    
    override func willDisappear() {
        store.unsubscribe(self)
        super.willDisappear()
    }
    
    private func setupSession() {
        processAppContext()
        session.delegate = self
        session.activate()
    }
    
    func updateTimerLabel(isActive: Bool = false, isInitial: Bool = false) {
        let color = isActive ? UIColor.apple : UIColor.lipstick
        let interval = isInitial ? store.state.timerAppState.timeInterval : store.state.roundAppState.roundTimeProgress
        let text = updatedTimerLabelString(timeRemaining: interval)
        ibTimerButton.setTitleWithColor(title: text, color: color)
    }
    
    private func updatedTimerLabelString(timeRemaining: Int) -> String {
        let minutesLeft = timeRemaining / 60 % 60
        let secondsLeft = timeRemaining % 60
        
        var minutesString = "\(minutesLeft)"
        var secondsString = "\(secondsLeft)"
        
        if minutesLeft < 10 {
            minutesString = "0\(minutesString)"
        }
        
        if secondsLeft < 10 {
            secondsString = "0\(secondsString)"
        }
        
        return "\(minutesString):\(secondsString)"
    }
    
    // MARK: Actions
    @IBAction private func timerButtonAction() {
        let state: TimerState = store.state.roundAppState.roundState
        
        if state == .paused || state == .initial {
            store.dispatch(RoundRunningAction())
        } else if state == .running {
            store.dispatch(RoundPausedAction())
        } else if state == .isOut {
            replayAction()
        }
    }
    
    private func replayAction() {
        store.dispatch(RoundReplayAction(timeValue: store.state.timerAppState.timeInterval,
                                         beepValue: store.state.timerAppState.beepInterval))
        let start = Date()
        let endDate = start.addingTimeInterval(TimeInterval(store.state.timerAppState.timeInterval))
        store.dispatch(RoundEndDate(endDate: endDate))
        store.dispatch(RoundInitialAction(progress: 0))
        store.dispatch(RoundRunningAction())
    }
    
    @IBAction private func didPressSettings() {
        store.dispatch(RoundPausedAction())
        moveToSettings()
    }
    
    @IBAction private func didPressStart(){
        store.dispatch(RoundPausedAction())
        moveToNewSettings()
    }
    
    private func moveToNewSettings() {
        self.presentController(withNames: [Constants.roundDurationControllerClassName, Constants.beepIntervalController], contexts: nil)
    }
    
    private func moveToSettings() {
        let transitionHelper = TransitionHelper()
        self.pushController(withName: Constants.settingsControllerClassName, context: transitionHelper)
    }
    
    func newState(state: RoundState) {
        switch state.roundState {
        case .initial:
            updateTimerLabel(isActive: false, isInitial: true)
            
        case .running:
            updateTimerLabel(isActive: true)
            
        case .paused:
            updateTimerLabel(isActive: false)
            
        case .isOut:
            updateTimerLabel(isActive: false)
        }
    }
}
