import SwiftUI
import ComposableArchitecture
import Combine

// MARK: - Wheel Event Enum

enum WheelEvent {
  case buttonPressed(WheelButtonType)
  case scrolled(WheelScrollDirection)
}

// MARK: - ScrollWheelEventsPublisher

final class ScrollWheelEventsPublisher {
    
    // MARK: - Singleton
    
    static let shared = ScrollWheelEventsPublisher()
    
    // MARK: - Private Properties
    
    private let eventSubject = PassthroughSubject<WheelEvent, Never>()
    
    // MARK: - Init
    
    private init() {}
    
    // MARK: - Public Properties
    
    var events: AnyPublisher<WheelEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Event Sending
    
    func send(_ event: WheelEvent) {
        eventSubject.send(event)
    }
}
