assert = require("chai").assert
should = require("chai").should()
cola = require("../../src/core/element")

class TestElement extends cola.Element
	@ATTRIBUTES:
		id:
			readOnlyAfterCreate: true
		name:
			defaultValue: "default name"
			readOnly: true
		language:
			enum: ["java", "c", "javascript", "python", "ruby"]
		child: null

	@EVENTS:
		event1:
			singleListener: true

describe "element", () ->
	describe "cola.Element", () ->
		it "attribute", () ->
			element = new TestElement({
				id: "element id"
			})
			assert.equal("element id", element.get("id"))
			assert.equal("default name", element.get("name"))
			should.throw () ->
				element.set("id", "new id")
			should.throw () ->
				element.set("name", "new name")
			should.not.throw () ->
				element.set("name", "new name", true)

		it "extends", () ->
			class TestElement1 extends TestElement
				@ATTRIBUTES:
					attr1: null

			class TestElement2 extends TestElement1
				@ATTRIBUTES:
					attr2: null

			class TestElement3 extends TestElement2
				@ATTRIBUTES:
					attr3: null

			element = new TestElement3({
				tag: "tag10"
				attr1: "value1"
				attr2: "value2"
				attr3: "value3"
			})
			assert.equal("value1", element.get("attr1"))
			assert.equal("value2", element.get("attr2"))
			assert.equal("value3", element.get("attr3"))

		it "enum", () ->
			element = new TestElement()

			element.set("language", "javascript")
			assert.equal("javascript", element.get("language"))

			should.throw () ->
				element.set("language", "basic")

		it "extend", () ->
			element = new TestElement()
			assert.isNotNull(element.constructor.ATTRIBUTES.name)
			assert.isNotNull(element.constructor.ATTRIBUTES.tag)
			assert.isTrue(element instanceof cola.Element)

		it "path", () ->
			root = new TestElement()
			child1 = new TestElement()
			child2 = new TestElement()

			root.set("child", child1)
			root.set("child.child", child2)

			assert.equal(child1, root.get("child"))
			assert.equal(child2, child1.get("child"))
			assert.equal(child2, root.get("child.child"))

		it "cola.tag", () ->
			element = new TestElement()
			element.set("tag", "tag1.1")
			assert.equal("tag1.1", element.get("tag"))

			element.set("tag", "tag1.2")
			assert.equal("tag1.2", element.get("tag"))

			element.destroy()

		it "#event:attributeChange", () ->
			tagCounter = 0
			element = new TestElement({
				attributeChange: (self, arg)->
					assert.equal("tag", arg.attribute)
					tagCounter++
			})
			element.set("tag", "tag4.1")
			assert.equal(1, tagCounter)

			element.set(tag: null)
			assert.equal(2, tagCounter)

		it "#event:singleListener", () ->
			element = new TestElement()

			element.on("event1", () -> )
			assert.equal(1, element.getListeners("event1").length)

			should.throw () ->
				element.on("event1", () -> )

		it "#event:once", () ->
			tagCounter = 0
			element = new TestElement({
				"attributeChange:once": (self, arg)->
					assert.equal("tag", arg.attribute)
					tagCounter++
			})

			assert.equal(1, element.getListeners("attributeChange").length)

			element.set("tag", "tag4.2")
			assert.equal(1, tagCounter)

			element.set(tag: null)
			assert.equal(1, tagCounter)

			assert.equal(0, element.getListeners("attributeChange").length)

	describe "TagManager", () ->
		it "cola.tag", () ->
			element1 = new TestElement()
			element1.set("tag", "tag2.1")

			group = cola.tag("tag2.1")
			assert.equal(1, group.length)
			assert.equal(element1, group[0])

			element1.set("tag", "tag2.2")

			group = cola.tag("tag2.1")
			assert.equal(0, group.length)

			group = cola.tag("tag2.2")
			assert.equal(1, group.length)
			assert.equal(element1, group[0])

			element2 = new TestElement()
			element2.set("tag", "tag2.2")

			group = cola.tag("tag2.2")
			assert.equal(2, group.length)

			element1.set("tag", "tag2.1")
			group = cola.tag("tag2.2")
			assert.equal(1, group.length)
			assert.equal(element2, group[0])

			element1.set("tag", "tag2.2")
			group = cola.tag("tag2.2")
			assert.equal(2, group.length)

		it "group", () ->
			element1 = new TestElement()
			element1.set("tag", "tag3.1")

			element2 = new TestElement()
			element2.set("tag", "tag3.1")

			group = cola.tag("tag3.1")
			assert.equal(2, group.length)

			group.set("tag", "tag3.2")

			group = cola.tag("tag3.1")
			assert.equal(0, group.length)

			group = cola.tag("tag3.2")
			assert.equal(2, group.length)
