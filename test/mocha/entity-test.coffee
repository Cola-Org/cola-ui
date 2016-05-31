assert = require("chai").assert
should = require("chai").should()
cola = require("../../src/core/entity")

dataType = new cola.EntityDataType({
	properties: [
		{
			name: "id"
			dataType: "string"
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
			name: "interest"
			dataType: "array"
		},
		{
			name: "address"
			dataType: {
				name: "Address"
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
		},
		{
			name: "addresses"
			aggregated: true
			dataType: {
				name: "Address"
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
		},
		{
			name: "items"
			aggregated: true
			provider: {
				url: "any-url"
				pageSize: 10
			}
		}
	]
})

describe "Entity", () ->
	it "set and get no DateType", () ->
		entity = new cola.Entity(null, {
			id: "id001"
			name: "Mike"
			age: 25
			enabled: true
			address: {
				city: "shanghai"
				post: 201101
			}
			interest: ["movie", "music", "football"]
		})
		assert.equal(entity.get("id"), "id001")
		assert.equal(entity.get("name"), "Mike")
		assert.equal(entity.get("age"), 25)
		assert.equal(entity.get("enabled"), true)
		assert.equal(entity.get("address.post"), 201101)
		assert.equal(entity.get("address.city"), "shanghai")
		assert.isTrue(entity.get("interest") instanceof Array)

	it "set and get with DateType", () ->
		entity = new cola.Entity(dataType, {
			id: "id001"
			name: "Mike"
			salary: 10000
			taxRate: 0.2
			address: {
				city: "shanghai"
				postCode: 201101
			}
			interest: ["movie", "music", "football"]
		})

		assert.equal(entity.get("id"), "id001")
		assert.equal(entity.get("name"), "Mike")
		assert.equal(entity.get("salary"), 10000)

		address = entity.get("address")
		assert.isTrue(address instanceof cola.Entity)
		assert.equal(address.get("city"), "shanghai")
		assert.equal(address.get("postCode"), 201101)

		assert.equal(entity.get("interest").length, 3)
		assert.equal(entity.get("tax"), 2000)

	it "aggregation", () ->
		entity = new cola.Entity(dataType)

		should.throw ()->
			entity.set("addresses", {
				city: "shanghai"
				postCode: 201101
			})

		entity.set("addresses", [
			{
				city: "shanghai"
				postCode: 201101
			},
			{
				city: "beijing"
				postCode: 100020
			}
		])
		addresses = entity.get("addresses")
		assert.equal(addresses.entityCount, 2)

	it "state and oldValue", () ->
		entity = new cola.Entity(dataType, {
			id: "id001"
			name: "Mike"
			salary: 10000
			taxRate: 0.2
			address: {
				city: "shanghai"
				postCode: 201101
			}
			interest: ["movie", "music", "football"]
		})

		assert.equal(entity.state, "none")

		# set
		entity.set("salary", 20000)

		assert.equal(entity.get("salary"), 20000)
		assert.equal(entity.state, "modified")
		assert.equal(entity.get("tax"), 4000)

		assert.equal(entity.getOldValue("salary"), 10000)
		assert.equal(entity.getOldValue("address"), null)

		# reset
		entity.reset()

		assert.equal(entity.state, "none")
		assert.equal(entity.getOldValue("salary"), null)
		assert.equal(entity.getOldValue("address"), null)

	it "listener", () ->
		entity = new cola.Entity(dataType, {
			id: "id001"
			name: "Mike"
			salary: 10000
			taxRate: 0.2
			address: {
				city: "shanghai"
				postCode: 201101
			}
		})

		entity._setListener(onMessage: (path, type, arg) ->
			messages.push(
				path: path
				type: type
				arg: arg
			)
			return
		)

		# set property
		messages = []
		entity.set("salary", 20000)

		assert.equal(messages.length, 2)

		message = messages[0]
		assert.equal(message.type, cola.constants.MESSAGE_STATE_CHANGE)
		assert.equal(message.path, undefined)
		assert.equal(message.arg.oldState, "none")
		assert.equal(message.arg.state, "modified")

		message = messages[1]
		assert.equal(message.type, cola.constants.MESSAGE_DATA_CHANGE)
		assert.equal(message.path.join("."), "salary")
		assert.equal(message.arg.oldValue, 10000)
		assert.equal(message.arg.value, 20000)

		# set property again
		messages = []
		entity.set("taxRate", 0.15)

		assert.equal(messages.length, 1)

		message = messages[0]
		assert.equal(message.type, cola.constants.MESSAGE_DATA_CHANGE)
		assert.equal(message.path.join("."), "taxRate")
		assert.equal(message.arg.oldValue, 0.2)
		assert.equal(message.arg.value, 0.15)

		# set sub property
		messages = []
		entity.set("address.postCode", 201100)

		assert.equal(messages.length, 2)

		message = messages[0]
		assert.equal(message.type, cola.constants.MESSAGE_STATE_CHANGE)
		assert.equal(message.path.join("."), "address")
		assert.equal(message.arg.oldState, "none")
		assert.equal(message.arg.state, "modified")

		message = messages[1]
		assert.equal(message.type, cola.constants.MESSAGE_DATA_CHANGE)
		assert.equal(message.path.join("."), "address.postCode")
		assert.equal(message.arg.oldValue, 201101)
		assert.equal(message.arg.value, 201100)

		# remove sub object
		messages = []
		address = entity.get("address")
		address.remove()

		assert.equal(messages.length, 2)

		message = messages[0]
		assert.equal(message.type, cola.constants.MESSAGE_STATE_CHANGE)
		assert.equal(message.path.join("."), "address")
		assert.equal(message.arg.oldState, "modified")
		assert.equal(message.arg.state, "deleted")

		message = messages[1]
		assert.equal(message.type, cola.constants.MESSAGE_DATA_CHANGE)
		assert.equal(message.path.join("."), "address")
		assert.equal(message.arg.oldValue, address)
		assert.equal(message.arg.value, null)

		# add sub object
		messages = []
		entity.set("address", {
			city: "beijing"
			postCode: 100020
		})
		address = entity.get("address")

		assert.equal(messages.length, 1)

		message = messages[0]
		assert.equal(message.type, cola.constants.MESSAGE_DATA_CHANGE)
		assert.equal(message.path.join("."), "address")
		assert.equal(message.arg.oldValue, null)
		assert.equal(message.arg.value, address)

		# unbind listener
		entity._setListener(null)

		messages = []
		entity.set("address.postCode", 201100)

		assert.equal(messages.length, 0)

describe "EntityList", () ->
	it "insert and remove", () ->
		entity = new cola.Entity(dataType, {
			addresses: [
				{
					city: "shanghai"
					postCode: 201101
				},
				{
					city: "beijing"
					postCode: 100020
				}
			]
		})
		addresses = entity.get("addresses")

		assert.equal(addresses.entityCount, 2)
		assert.equal(addresses.current.get("city"), "shanghai")

		addresses.next()
		assert.equal(addresses.current.get("city"), "beijing")

		addresses.next()
		assert.equal(addresses.current.get("city"), "beijing")

		addresses.current.remove()
		assert.equal(addresses.entityCount, 1)
		assert.equal(addresses.current.get("city"), "shanghai")

		addresses.remove()
		assert.equal(addresses.entityCount, 0)
		assert.equal(addresses.current, null)

		addresses.insert({
			city: "shenzhen"
			postCode: 300021
		})
		assert.equal(addresses.entityCount, 1)
		assert.equal(addresses.current.get("city"), "shenzhen")

		addresses.insert({
			city: "beijing"
			postCode: 100020
		}, "before")
		assert.equal(addresses.entityCount, 2)
		assert.equal(addresses.current.get("city"), "shenzhen")

		addresses.previous()
		assert.equal(addresses.current.get("city"), "beijing")

		addresses.insert({
			city: "shanghai"
			postCode: 201101
		}, "begin")
		assert.equal(addresses.entityCount, 3)
		assert.equal(addresses.current.get("city"), "beijing")

		addresses.previous()
		assert.equal(addresses.current.get("city"), "shanghai")

	it "createChild and createBrother", () ->
		entity = new cola.Entity(dataType)

		assert.equal(entity.get("addresses"), null)

		address = entity.createChild("addresses", {
			city: "shenzhen"
			postCode: 300021
		})
		addresses = entity.get("addresses")

		assert.equal(addresses.entityCount, 1)
		assert.equal(address.state, "new")
		assert.equal(address.get("city"), "shenzhen")

		address = address.createBrother({
			city: "shanghai"
			postCode: 201101
		})

		assert.equal(addresses.entityCount, 2)
		assert.equal(address.state, "new")
		assert.equal(address.get("city"), "shanghai")

	it "each", () ->
		entity = new cola.Entity(dataType, {
			addresses: [
				{
					city: "shanghai"
					postCode: 201101
				},
				{
					city: "beijing"
					postCode: 100020
				},
				{
					city: "shenzhen"
					postCode: 300021
				}
			]
		})
		addresses = entity.get("addresses")

		cities = []
		addresses.each (address) ->
			cities.push(address.get("city"))

		assert.equal(cities.join(","), "shanghai,beijing,shenzhen")

	it "listener", () ->
		entity = new cola.Entity(dataType, {
			addresses: [
				{
					city: "shanghai"
					postCode: 201101
				},
				{
					city: "beijing"
					postCode: 100020
				},
				{
					city: "shenzhen"
					postCode: 300021
				}
			]
		})
		addresses = entity.get("addresses")

		entity._setListener(onMessage: (path, type, arg) ->
			messages.push(
				path: path
				type: type
				arg: arg
			)
			return
		)

		# last
		messages = []
		addresses.last()

		assert.equal(messages.length, 1)

		message = messages[0]
		assert.equal(message.type, cola.constants.MESSAGE_CURRENT_CHANGE)
		assert.equal(message.path.join("."), "addresses")
		assert.equal(message.arg.oldCurrent.get("city"), "shanghai")
		assert.equal(message.arg.current.get("city"), "shenzhen")

		# first
		messages = []
		addresses.first()

		assert.equal(messages.length, 1)

		message = messages[0]
		assert.equal(message.type, cola.constants.MESSAGE_CURRENT_CHANGE)
		assert.equal(message.path.join("."), "addresses")
		assert.equal(message.arg.oldCurrent.get("city"), "shenzhen")
		assert.equal(message.arg.current.get("city"), "shanghai")

		# remove
		messages = []
		addresses.remove()

		assert.equal(messages.length, 3)

		message = messages[0]
		assert.equal(message.type, cola.constants.MESSAGE_STATE_CHANGE)
		assert.equal(message.path.join("."), "addresses")
		assert.equal(message.arg.oldState, "none")
		assert.equal(message.arg.state, "deleted")

		message = messages[1]
		assert.equal(message.type, cola.constants.MESSAGE_REMOVE)
		assert.equal(message.path.join("."), "addresses")
		assert.equal(message.arg.entityList, addresses)
		assert.equal(message.arg.entity.get("city"), "shanghai")

		message = messages[2]
		assert.equal(message.type, cola.constants.MESSAGE_CURRENT_CHANGE)
		assert.equal(message.path.join("."), "addresses")
		assert.equal(message.arg.oldCurrent.get("city"), "shanghai")
		assert.equal(message.arg.current.get("city"), "beijing")

		# insert
		messages = []
		address = addresses.insert({
			city: "shanghai"
			postCode: 201101
		}, "begin")
		assert.equal(messages.length, 1)

		message = messages[0]
		assert.equal(message.type, cola.constants.MESSAGE_INSERT)
		assert.equal(message.path.join("."), "addresses")
		assert.equal(message.arg.entityList, addresses)
		assert.equal(message.arg.entity, address)

		# set property for current, current address is 'beijing'
		messages = []
		entity.set("addresses.postCode", 100000)

		assert.equal(messages.length, 2)

		message = messages[1]
		assert.equal(message.type, cola.constants.MESSAGE_DATA_CHANGE)
		assert.equal(message.path.join("."), "addresses.postCode")
		assert.equal(message.arg.oldValue, 100020)
		assert.equal(message.arg.value, 100000)

		# set property for non-current
		messages = []
		address.set("postCode", 200000)

		assert.equal(messages.length, 1)

		message = messages[0]
		assert.equal(message.type, cola.constants.MESSAGE_DATA_CHANGE)
		assert.equal(message.path.join("."), "!addresses.postCode")
		assert.equal(message.arg.oldValue, 201101)
		assert.equal(message.arg.value, 200000)

	it "provider and paging", () ->
		oldInvoker = cola.AjaxServiceInvoker::_invoke
		cola.AjaxServiceInvoker::_invoke = () ->
			TOTAL_ENTITY = 100
			pageSize = @ajaxService._pageSize
			pageNo = @ajaxService._pageNo
			items = []
			start = pageSize * (pageNo - 1)
			i = 1
			while i <= pageSize
				index = start + i
				if index > TOTAL_ENTITY then break
				items.push(
					pageNo: pageNo
					index: index
					indexInPage: i
				)
				i++

			result =
				$entityCount: TOTAL_ENTITY
				$pageCount: parseInt((TOTAL_ENTITY - 1) / pageSize) + 1
				$data: items
			@invokeCallback(true, result)
			return result

		entity = new cola.Entity(dataType)
		messages = null
		entity._setListener(onMessage: (path, type, arg) ->
			messages?.push(
				path: path
				type: type
				arg: arg
			)
			return
		)

		items = entity.get("items", "always")

		assert.isNotNull(items)
		assert.equal(items.entityCount, 10)
		assert.equal(items.current.get("pageNo"), 1)

		items.gotoPage(2)
		assert.equal(items.entityCount, 20)
		assert.equal(items.current.get("pageNo"), 2)

		items.gotoPage(1)
		assert.equal(items.current.get("pageNo"), 1)

		items.gotoPage(4)
		assert.equal(items.entityCount, 30)
		assert.equal(items.current.get("pageNo"), 4)

		lastItem = null
		counter = 0
		items.each (item) ->
			if lastItem?
				assert.isTrue(lastItem.get("pageNo") <= item.get("pageNo"))
			lastItem = item
			counter++
		assert.equal(counter, items.entityCount)

		items.previousPage()
		assert.equal(items.entityCount, 40)
		assert.equal(items.current.get("pageNo"), 3)

		items.previousPage()
		assert.equal(items.entityCount, 40)
		assert.equal(items.current.get("pageNo"), 2)

		items.firstPage()
		assert.equal(items.entityCount, 40)
		assert.equal(items.current.get("pageNo"), 1)

		items.lastPage()
		assert.equal(items.entityCount, 50)
		assert.equal(items.current.get("pageNo"), 10)

		items.first()
		assert.equal(items.entityCount, 50)
		assert.equal(items.current.get("pageNo"), 1)

		messages = []
		items.current.set("pageNo", -1)
		assert.equal(items.current.get("pageNo"), -1)

		assert.equal(messages.length, 2)

		message = messages[0]
		assert.equal(message.type, cola.constants.MESSAGE_STATE_CHANGE)
		assert.equal(message.path.join("."), "items")
		assert.equal(message.arg.oldState, "none")
		assert.equal(message.arg.state, "modified")

		message = messages[1]
		assert.equal(message.type, cola.constants.MESSAGE_DATA_CHANGE)
		assert.equal(message.path.join("."), "items.pageNo")
		assert.equal(message.arg.oldValue, 1)
		assert.equal(message.arg.value, -1)

		messages = []
		oldCurrent = items.current
		items.next()
		oldCurrent.set("pageNo", -2)
		assert.equal(oldCurrent.get("pageNo"), -2)

		assert.equal(messages.length, 2)

		message = messages[0]
		assert.equal(message.type, cola.constants.MESSAGE_CURRENT_CHANGE)
		assert.equal(message.path.join("."), "items")
		assert.equal(message.arg.oldCurrent, oldCurrent)
		assert.equal(message.arg.current, items.current)

		message = messages[1]
		assert.equal(message.type, cola.constants.MESSAGE_DATA_CHANGE)
		assert.equal(message.path.join("."), "!items.pageNo")
		assert.equal(message.arg.oldValue, -1)
		assert.equal(message.arg.value, -2)

		messages = null
		items.flushSync()
		assert.equal(items.entityCount, 10)
		assert.equal(items.current.get("pageNo"), 1)

		cola.AjaxServiceInvoker::_invoke = oldInvoker