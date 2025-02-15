//
//  DOM.swift
// LiveViewNative
//
//  Created by Shadowfacts on 10/10/22.
//

import LiveViewNativeCore

/// A wrapper for an element-containing DOM node and its associated data.
///
/// ## Topics
/// ### Tag Info
/// - ``namespace``
/// - ``tag``
/// ### Accessing Attributes
/// - ``attributes``
/// - ``attribute(named:)``
/// - ``attributeValue(for:)``
/// - ``attributeBoolean(for:)``
/// ### Accessing Children
/// - ``children()``
/// - ``depthFirstChildren()``
/// - ``elementChildren()``
/// - ``innerText()``
public struct ElementNode: Identifiable, @unchecked Sendable {
    public let node: Node
    public let data: Element
    
    init(node: Node, data: Element) {
        self.node = node
        self.data = data
    }
    
    public var id: NodeRef { node.id }
    
    /// A sequence representing this element's direct children.
    public func children() -> NodeChildrenSequence { node.children() }
    /// A sequence that traverses the nested child nodes of this element in depth-first order.
    public func depthFirstChildren() -> NodeDepthFirstChildrenSequence { node.depthFirstChildren() }
    /// A sequence representing this element's direct children that are elements.
    public func elementChildren() -> [ElementNode] { node.children().compactMap({ $0.asElement() }) }

    /// The namespace of the element.
    public var namespace: String? { data.name.namespace }
    /// The tag name of the element.
    public var tag: String { data.name.name }
    /// The list of attributes present on this element.
    public var attributes: [LiveViewNativeCore.Attribute] { data.attributes }
    /// The attribute with the given name, or `nil` if there is no such attribute.
    ///
    /// ## Discussion
    /// Because `AttributeName` conforms to `ExpressibleByStringLiteral`, you can directly use a string literal as the attribute name:
    /// ```swift
    /// element.attribute(named: "my-attr")
    /// ```
    public func attribute(named name: AttributeName) -> LiveViewNativeCore.Attribute? { node[name] }
    
    /// The value of the attribute with the given name, or `nil` if there is no such attribute.
    ///
    /// ## Discussion
    /// Because `AttributeName` conforms to `ExpressibleByStringLiteral`, you can directly use a string literal as the attribute name:
    /// ```swift
    /// element.attributeValue(for: "my-attr")
    /// ```
    public func attributeValue(for name: AttributeName) -> String? {
        attribute(named: name)?.value
    }
    
    /// The value of the attribute with the given name, decoded to a concrete type.
    ///
    /// The attribute is decoded to the type ``T``, which must conform to the ``AttributeDecodable`` protocol.
    public func attributeValue<T: AttributeDecodable>(_: T.Type, for name: AttributeName) throws -> T {
        try T.init(from: attribute(named: name), on: self)
    }
    
    /// Checks for a [boolean attribute](https://html.spec.whatwg.org/multipage/common-microsyntaxes.html#boolean-attributes).
    ///
    /// If the attribute is present, the value is `true`.
    ///
    ///
    /// > The strings `"true"`/`"false"` are ignored, and only the presence of the attribute is considered.
    /// > A value of `"false"` would still return `true`.
    public func attributeBoolean(for name: AttributeName) -> Bool {
        guard let attribute = attribute(named: name)
        else { return false }
        return attribute.value != "false"
    }
    
    /// The text of this element.
    ///
    /// The returned string only incorporates the direct text node children, not any text nodes within nested elements.
    public func innerText() -> String {
        // TODO: should follow the spec and insert/collapse whitespace around elements
        self.children().compactMap { node in
            if case .leaf(let content) = node.data() {
                return content
            } else {
                return nil
            }
        }
        .joined(separator: " ")
    }
    
    internal func buildPhxValuePayload() -> Payload {
        let prefix = "phx-value-"
        return attributes
            .filter { $0.name.namespace == nil && $0.name.name.starts(with: prefix) }
            .reduce(into: [:]) { partialResult, attr in
                // TODO: for nil attribute values, what value should this use?
                partialResult[String(attr.name.name.dropFirst(prefix.count))] = attr.value
            }
    }
}

extension Node {
    func asElement() -> ElementNode? {
        if case .nodeElement(let data) = self.data() {
            return ElementNode(node: self, data: data)
        } else {
            return nil
        }
    }
}
