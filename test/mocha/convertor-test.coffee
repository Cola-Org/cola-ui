assert = require("chai").assert
should = require("chai").should()
cola = require("../../src/core/convertor")

describe "Convertor", () ->
	it "filter", () ->
		entity = new cola.Entity()
		entity.set("addresses", [
			{
				city: "ShangHai"
				street: "NanJing"
				postCode: 201101
			},
			{
				city: "BeiJing"
				street: "ChangAn"
				postCode: 100020
			},
			{
				city: "TianJin"
				street: "ShangDong"
				postCode: 400002
			},
			{
				city: "ShenZhen"
				street: "ZhongShan"
				postCode: 300021
			}
		])
		addresses = entity.get("addresses")

		filtered = cola.convertor.filter(addresses, "en")
		assert.equal(filtered.length, 1)
		assert.equal(filtered[0].get("city"), "ShenZhen")

		filtered = cola.convertor.filter(addresses, 20)
		assert.equal(filtered.length, 2)
		assert.equal(filtered[0].get("city"), "ShangHai")
		assert.equal(filtered[1].get("city"), "BeiJing")

		filtered = cola.convertor.filter(addresses, "A", true)
		assert.equal(filtered.length, 1)
		assert.equal(filtered[0].get("city"), "BeiJing")

		filtered = cola.convertor.filter(addresses, "ZhongShan", true, true)
		assert.equal(filtered.length, 1)
		assert.equal(filtered[0].get("city"), "ShenZhen")

		filtered = cola.convertor.filter(addresses, {
			city: "an"
		})
		assert.equal(filtered.length, 2)
		assert.equal(filtered[0].get("city"), "ShangHai")
		assert.equal(filtered[1].get("city"), "TianJin")

	it "orderBy", () ->
		entity = new cola.Entity()
		entity.set("addresses", [
			{
				id: 1
				city: "ShangHai"
				street: "NanJing"
				postCode: 201101
				region: "A"
			},
			{
				id: 2
				city: "BeiJing"
				street: "ChangAn"
				postCode: 100020
				region: "A"
			},
			{
				id: 3
				city: "TianJin"
				street: "ShangDong"
				postCode: 300002
				region: "B"
			},
			{
				id: 4
				city: "ShenZhen"
				street: "ZhongShan"
				postCode: 400021
				region: "B"
			}
		])
		addresses = entity.get("addresses")

		getIds = (addresses) ->
			ids = []
			for address in addresses
				ids.push(address.get("id"))
			return ids.join("")

		sorted = cola.convertor.orderBy(addresses, "city")
		assert.equal(getIds(sorted), "2143")

		sorted = cola.convertor.orderBy(addresses, "city", true)
		assert.equal(getIds(sorted), "3412")

		sorted = cola.convertor.orderBy(addresses, "+postCode")
		assert.equal(getIds(sorted), "2134")

		sorted = cola.convertor.orderBy(addresses, "-postCode")
		assert.equal(getIds(sorted), "4312")

		sorted = cola.convertor.orderBy(addresses, "-region,postCode")
		assert.equal(getIds(sorted), "3421")