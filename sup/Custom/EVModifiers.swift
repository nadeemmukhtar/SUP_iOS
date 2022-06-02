//
//  EVModifiers.swift
//  sayit
//
//  Created by Robert Malko on 12/18/19.
//  Copyright © 2019 Extra Visual. All rights reserved.
//

import SwiftUI

// MARK: - Drag and Move

struct DragAndMoveModifier: ViewModifier {
    @Binding var currentPosition: CGSize
    @Binding var newPosition: CGSize
    @Binding var isLongPressed: Bool?

    var onDragStart: () -> Void
    var onDragEnd: () -> Void
    var minimumDuration: Double = 0.5
    let snapToOriginal: Bool

    @State private var hasStartedDrag = false

    func body(content: Content) -> some View {
        if newPosition.width == .infinity {
            return AnyView(content.onAppear {
                self.hasStartedDrag = false
            })
        }

        let dragAndMoveGesture = DragGesture()
            .onChanged { value in
                let width = value.translation.width
                let height = value.translation.height
                self.currentPosition = CGSize(
                    width: width + self.newPosition.width,
                    height: height  + self.newPosition.height
                )
                if !self.hasStartedDrag {
                    self.hasStartedDrag = true
                    self.onDragStart()
                }
            }
            .onEnded { value in
                withAnimation(.spring()) {
                    if self.snapToOriginal {
                        self.currentPosition = .zero
                        self.newPosition = .zero
                    } else {
                        let width = value.translation.width
                        let height = value.translation.height
                        self.currentPosition = CGSize(
                            width: width + self.newPosition.width,
                            height: height + self.newPosition.height
                        )
                        self.newPosition = self.currentPosition
                    }
                }
                self.hasStartedDrag = false
                self.onDragEnd()
            }

        if let _ = isLongPressed {
            let longPressGesture = LongPressGesture(
                minimumDuration: minimumDuration
            )
                .onChanged { _ in
                    self.isLongPressed = true
                    if !self.hasStartedDrag {
                        self.hasStartedDrag = true
                        self.onDragStart()
                    }
                }
            let gesture = longPressGesture
                .simultaneously(with: dragAndMoveGesture)
                .onEnded { _ in
                    self.isLongPressed = false
                }
            return AnyView(content
                .offset(x: currentPosition.width, y: currentPosition.height)
                .gesture(gesture))
        } else {
            return AnyView(content
                .offset(x: currentPosition.width, y: currentPosition.height)
                .gesture(dragAndMoveGesture))
        }
    }
}

extension View {
    func dragAndMove(
        currentPosition: Binding<CGSize>,
        newPosition: Binding<CGSize>,
        isLongPressed: Binding<Bool?> = .constant(nil),
        onDragStart: @escaping () -> Void = { return },
        onDragEnd: @escaping () -> Void = { return },
        minimumDuration: Double = 0.5,
        snapToOriginal: Bool = false
    ) -> some View {
        self.modifier(DragAndMoveModifier(
            currentPosition: currentPosition,
            newPosition: newPosition,
            isLongPressed: isLongPressed,
            onDragStart: onDragStart,
            onDragEnd: onDragEnd,
            minimumDuration: minimumDuration,
            snapToOriginal: snapToOriginal
        ))
    }
}

// MARK: - Save saveBounds PreferenceKey

extension View {
    public func saveBounds(viewId: Int, coordinateSpace: CoordinateSpace = .global) -> some View {
        background(GeometryReader { proxy in
            Color.clear.preference(key: SaveBoundsPrefKey.self, value: [SaveBoundsPrefData(viewId: viewId, bounds: proxy.frame(in: coordinateSpace))])
        })
    }

    public func retrieveBounds(viewId: Int, _ rect: Binding<CGRect>) -> some View {
        onPreferenceChange(SaveBoundsPrefKey.self) { preferences in
            DispatchQueue.main.async {
                // The async is used to prevent a possible blocking loop,
                // due to the child and the ancestor modifying each other.
                let p = preferences.first(where: { $0.viewId == viewId })
                rect.wrappedValue = p?.bounds ?? .zero
            }
        }
    }
}

struct SaveBoundsPrefData: Equatable {
    let viewId: Int
    let bounds: CGRect
}

struct SaveBoundsPrefKey: PreferenceKey {
    static var defaultValue: [SaveBoundsPrefData] = []

    static func reduce(value: inout [SaveBoundsPrefData], nextValue: () -> [SaveBoundsPrefData]) {
        value.append(contentsOf: nextValue())
    }

    typealias Value = [SaveBoundsPrefData]
}

// MARK: - provideFrameChanges

/// Represents the `frame` of an identifiable view as an `Anchor`
struct ViewFrame: Equatable {

    /// A given identifier for the View to faciliate processing
    /// of frame updates
    let viewId : String

    /// An `Anchor` representation of the View
    let frameAnchor: Anchor<CGRect>

    // Conformace to Equatable is required for supporting
    // view udpates via `PreferenceKey`
    static func == (lhs: ViewFrame, rhs: ViewFrame) -> Bool {
        // Since we can currently not compare `Anchor<CGRect>` values
        // without a Geometry reader, we return here `false` so that on
        // every change on bounds an update is issued.
        return false
    }
}

/// A `PreferenceKey` to provide View frame updates in a View tree
struct FramePreferenceKey: PreferenceKey {
    typealias Value = [ViewFrame] // The list of view frame changes in a View tree.

    static var defaultValue: [ViewFrame] = []

    /// When traversing the view tree, Swift UI will use this function to collect all view frame changes.
    static func reduce(value: inout [ViewFrame], nextValue: () -> [ViewFrame]) {
        value.append(contentsOf: nextValue())
    }
}

/// Adds an Anchor preference to notify of frame changes
struct ProvideFrameChanges: ViewModifier {
    var viewId : String

    func body(content: Content) -> some View {
        content
            .transformAnchorPreference(key: FramePreferenceKey.self, value: .bounds) {
                $0.append(ViewFrame(viewId: self.viewId, frameAnchor: $1))
            }
    }
}

extension View {
    /// Adds an Anchor preference to notify of frame changes
    /// - Parameter viewId: A `String` identifying the View
    func provideFrameChanges(viewId : String) -> some View {
        ModifiedContent(content: self, modifier: ProvideFrameChanges(viewId: viewId))
    }
}

// MARK: - handleViewTreeFrameChanges

typealias ViewTreeFrameChanges = [String : CGRect]

/// Provides a block to handle internal View tree frame changes
/// for views using the `ProvideFrameChanges` in own coordinate space.
struct HandleViewTreeFrameChanges: ViewModifier {
    /// The handler to process Frame changes on this views subtree.
    /// `ViewTreeFrameChanges` is a dictionary where keys are string view ids
    /// and values are the updated view frame (`CGRect`)
    var handler : (ViewTreeFrameChanges)->Void

    func body(content: Content) -> some View {
        GeometryReader { contentGeometry in
            content
                .onPreferenceChange(FramePreferenceKey.self) {
                    self._updateViewTreeLayoutChanges($0, in: contentGeometry)
                }
        }
    }

    private func _updateViewTreeLayoutChanges(_ changes : [ViewFrame], in geometry : GeometryProxy) {
        let pairs = changes.map({ ($0.viewId, geometry[$0.frameAnchor]) })
        handler(Dictionary(uniqueKeysWithValues: pairs))
    }
}

extension View {
    /// Adds an Anchor preference to notify of frame changes
    /// - Parameter viewId: A `String` identifying the View
    func handleViewTreeFrameChanges(_ handler : @escaping (ViewTreeFrameChanges)->Void) -> some View {
        ModifiedContent(content: self, modifier: HandleViewTreeFrameChanges(handler: handler))
    }
}
