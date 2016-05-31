assert = require("chai").assert
should = require("chai").should()
cola = require("../../src/core/util")

describe "Util", () ->
	it "isCompatibleType()", () ->
		class Element
		class Child1 extends Element
		class Child2 extends Child1
		class Child3 extends Child1

		assert.isTrue(cola.util.isCompatibleType(Element, Child1))
		assert.isTrue(cola.util.isCompatibleType(Element, Child2))
		assert.isTrue(cola.util.isCompatibleType(Child1, Child2))
		assert.isTrue(cola.util.isCompatibleType(Child1, Child3))
		assert.isFalse(cola.util.isCompatibleType(Child2, Child3))
		assert.isFalse(cola.util.isCompatibleType(Child1, Element))