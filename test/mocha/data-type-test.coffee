assert = require("chai").assert
XDate = require("../../src/lib/xdate")
cola = require("../../src/core/data-type")

describe "data-type", () ->
	it "addProperty", () ->
		dataType = new cola.EntityDataType(
			properties: [
				{
					name: "id"
					dataType: "int"
				},
				{
					name: "name"
				},
				{
					name: "birthday"
					dataType: "date"
				},
				{
					name: "salary"
					dataType: "float"
				},
				{
					name: "taxRate"
					dataType: "float"
				},
				{
					name: "tax"
					dataType: "float"
					compute: (self, arg) ->
						return arg.entity.get("salary") * arg.entity.get("taxRate")
				},
				{
					name: "address"
					dataType: {
						properties: [
							{
								name: "city"
							},
							{
								name: "postCode"
								dataType: "int"
							}
						]
					}
				}
			]
		)

		assert.equal(dataType.getProperties().size, 7)

		birthdayProp = dataType.getProperty("birthday")
		assert.isTrue(birthdayProp instanceof cola.BaseProperty)
		assert.equal(birthdayProp.get("name"), "birthday")
		assert.equal(birthdayProp.get("dataType.name"), "date")

		taxProp = dataType.getProperty("tax")
		assert.isTrue(taxProp instanceof cola.ComputeProperty)
		assert.equal(taxProp.get("name"), "tax")

		addressProp = dataType.getProperty("address")
		assert.isTrue(addressProp instanceof cola.BaseProperty)
		assert.equal(addressProp.get("name"), "address")

		addressDataType = addressProp.get("dataType")
		assert.equal(addressDataType.getProperties().size, 2)
		assert.isTrue(addressDataType instanceof cola.EntityDataType)

		postCodeProp = addressDataType.getProperty("postCode")
		assert.isTrue(postCodeProp instanceof cola.BaseProperty)
		assert.equal(postCodeProp.get("name"), "postCode")

	it "boolean convert", () ->
		dataType = cola.DataType.defaultDataTypes["boolean"]
		assert.equal(dataType.parse("true"), true)
		assert.equal(dataType.parse("on"), true)
		assert.equal(dataType.parse("yes"), true)
		assert.equal(dataType.parse(1), true)

		assert.equal(dataType.parse(null), false)
		assert.equal(dataType.parse("FALSE"), false)
		assert.equal(dataType.parse(0), false)
		assert.equal(dataType.parse("Off"), false)

	it "int convert", () ->
		dataType = cola.DataType.defaultDataTypes["int"]
		assert.equal(dataType.parse("123.456"), 123)
		assert.equal(dataType.parse(123.456), 123)
		assert.equal(dataType.parse("abc"), 0)

	it "float convert", () ->
		dataType = cola.DataType.defaultDataTypes["float"]
		assert.equal(dataType.parse("123.456"), 123.456)
		assert.equal(dataType.parse(123.456), 123.456)
		assert.equal(dataType.parse("abc"), 0)

	it "date convert", () ->
		compareDate = (d1, d2) ->
			return d1.getYear() == d2.getYear() and
					d1.getMonth() == d2.getMonth() and
					d1.getDate() == d2.getDate() and
					d1.getHours() == d2.getHours() and
					d1.getMinutes() == d2.getMinutes() and
					d1.getSeconds() == d2.getSeconds()

		now = new XDate()
		dataType = cola.DataType.defaultDataTypes["date"]
		assert.isTrue(compareDate(dataType.parse(now.toString()), now.toDate()))
		assert.isTrue(compareDate(dataType.parse(now.toString("yyyy-MM-dd HH:mm:ss")), now.toDate()))
		assert.isTrue(isNaN(dataType.parse("abc").getTime()))