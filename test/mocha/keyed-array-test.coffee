assert = require("chai").assert
cola = require("../../src/core/keyed-array")

describe "keyed-array", () ->
	keyedArray = new cola.util.KeyedArray()
	element1 =
		name: "key1"
	element2 =
		name: "key2"
	element3 =
		name: "key3"
	element4 =
		name: "key4"
	element5 =
		name: "key5"

	it "add", () ->
		assert.equal(0, keyedArray.size)

		keyedArray.add(element1.name, element1)
		assert.equal(1, keyedArray.size)
		assert.equal(element1, keyedArray.get("key1"))
		assert.equal(element1, keyedArray.get(0))

		keyedArray.add(element2.name, element2)
		assert.equal(2, keyedArray.size)
		assert.equal(element2, keyedArray.get("key2"))
		assert.equal(element2, keyedArray.get(1))

		keyedArray.add(element3.name, element3)
		assert.equal(3, keyedArray.size)
		assert.equal(element3, keyedArray.get("key3"))
		assert.equal(element3, keyedArray.get(2))

		keyedArray.add(element4.name, element4)
		keyedArray.add(element5.name, element5)
		assert.equal(5, keyedArray.size)

	it "getIndex", () ->
		assert.equal(3, keyedArray.getIndex("key4"))

	it "remove", () ->
		keyedArray.remove(1)
		assert.equal(4, keyedArray.size)
		assert.equal(null, keyedArray.get("key2"))

		keyedArray.remove("key3")
		assert.equal(3, keyedArray.size)
		assert.equal(null, keyedArray.get("key3"))

		keyedArray.remove("key1")
		assert.equal(2, keyedArray.size)
		assert.equal(element4, keyedArray.get(0))

	it "clear", () ->
		keyedArray.clear()
		assert.equal(0, keyedArray.size)
		assert.equal(null, keyedArray.get(0))

	it "each", () ->
		keyedArray.add(element1.name, element1)
		keyedArray.add(element2.name, element2)
		keyedArray.add(element3.name, element3)
		keyedArray.add(element4.name, element4)
		keyedArray.add(element5.name, element5)

		output = ""
		keyedArray.each (element) ->
			output += element.name + ";"

		assert.equal("key1;key2;key3;key4;key5;", output)
