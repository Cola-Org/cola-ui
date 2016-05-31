assert = require("chai").assert
should = require("chai").should()
cola = require("../../src/core/model")

describe "Model", () ->
	it "create and parent", () ->
		model = new cola.Model()
		model.set(
			name: "Tom",
			address:
				city: "shanghai"
				postCode: 201101
		)

		assert.equal(model.get("name"), "Tom")
		assert.equal(model.get("address.city"), "shanghai")

		subModel = new cola.Model(model)
		subModel.set(
			alias: "Tommy"
		)

		assert.equal(subModel.get("name"), "Tom")
		assert.equal(subModel.get("address.city"), "shanghai")
		assert.equal(subModel.get("alias"), "Tommy")
		assert.equal(model.get("alias"), null)

		subModel.set("name", "Mike")
		assert.equal(model.get("name"), "Tom")
		assert.equal(subModel.get("name"), "Mike")

		subModel.set("alias", "Mickael")
		assert.equal(subModel.get("alias"), "Mickael")
		assert.equal(model.get("alias"), null)

	it "DataType registation", () ->
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

		model = new cola.Model()
		oldScope = cola.currentScope
		cola.currentScope = model

		model.set(
			tree: cola.data({
				dataType: {
					name: "treeNode"
					properties: [
						{
							name: "id"
							dataType: "string"
						},
						{
							name: "children"
							dataType: "treeNode"
						}
					]
				}
			})
			addresses: cola.data({
				provider: {
					url: "any-url"
					pageSize: 10
				}
			})
		)

		treeNodeType = model.data.dataType("treeNode")
		assert.equal(treeNodeType.get("name"), "treeNode")

		property = treeNodeType.getProperty("children")
		assert.equal(property.get("dataType.name"), "treeNode")

		addresses = model.get("addresses", "always")
		assert.equal(addresses.entityCount, 10)

		cola.currentScope = oldScope
		cola.AjaxServiceInvoker::_invoke = oldInvoker

	it "path", () ->
		model = new cola.Model()
		model.set(
			tree: {
				name: "node1"
				children: [
					{
						name: "node1.1"
						children: [
							{name: "node1.1.1"}
							{name: "node1.1.2"}
						]
					}
					{
						name: "node1.2"
						children: [
							{
								name: "node1.2.1"
								children: [
									{name: "node1.2.1.1"}
								]
							}
							{name: "node1.2.2"}
						]
					}
				]
			}
		)

		tree = model.get("tree")
		node = tree.get("children.children#")

		assert.equal(node.get("name"), "node1.1.1")

		tree.get("children.children").next()
		assert.equal(tree.get("children.children.name"), "node1.1.2")

		tree.get("children").next()
		assert.equal(tree.get("children.children.children.name"), "node1.2.1.1")

		tree.get("children.children").next()
		assert.equal(tree.get("children.children.children.name"), undefined)
		assert.equal(tree.get("children.children.name"), "node1.2.2")

	it "binding and message", () ->
		model = new cola.Model()
		model.set(
			tree: {
				name: "node1"
				children: [
					{
						name: "node1.1"
						children: [
							{name: "node1.1.1"}
							{name: "node1.1.2"}
						]
					}
					{
						name: "node1.2"
						children: [
							{
								name: "node1.2.1"
								children: [
									{name: "node1.2.1.1"}
								]
							}
							{name: "node1.2.2"}
						]
					}
				]
			}
		)

		processor = {
			_processMessage: (bindingPath, path, type, arg) ->
				messages?.push({
					bindingPath: bindingPath
					path: path
					type: type
					arg: arg
				})
				assert.equal(bindingPath, "tree.children.name")
				return
		}
		model.data.bind("tree.children.name", processor)

		messages = []
		model.set("tree.children.name", "CHANGED")
		assert.equal(messages.length, 1)

		message = messages[0]
		assert.equal(message.type, cola.constants.MESSAGE_DATA_CHANGE)
		assert.equal(message.path.join("."), "tree.children.name")
		assert.equal(message.arg.value, "CHANGED")

		messages = []
		model.set("tree.name", "CHANGED")
		assert.equal(messages.length, 0)

		messages = []
		model.set("tree.children.children.name", "CHANGED")
		assert.equal(messages.length, 0)

		messages = []
		model.get("tree.children").next()
		assert.equal(messages.length, 1)

		message = messages[0]
		assert.equal(message.type, cola.constants.MESSAGE_CURRENT_CHANGE)
		assert.equal(message.path.join("."), "tree.children")

		model.data.unbind("tree.children.name", processor)

		messages = []
		model.get("tree.children").first()
		assert.equal(messages.length, 0)

	it "alias", () ->
		model = new cola.Model()
		model.set(
			tree: {
				name: "node1"
				children: [
					{
						name: "node1.1"
						children: [
							{name: "node1.1.1"}
							{name: "node1.1.2"}
						]
					}
					{
						name: "node1.2"
						children: [
							{
								name: "node1.2.1"
								children: [
									{name: "node1.2.1.1"}
								]
							}
							{name: "node1.2.2"}
						]
					}
				]
			}
		)

		processor = {
			repeatNotification: true
			_processMessage: (bindingPath, path, type, arg) ->
				messages?.push({
					bindingPath: bindingPath
					path: path
					type: type
					arg: arg
				})
				return
		}
		model.data.bind("**", processor)

		node = model.get("tree.children.children#")
		assert.equal(node.get("name"), "node1.1.1")

		messages = []
		model.set("alias1", node)
		assert.equal(messages.length, 1)

		message = messages[0]
		assert.equal(message.type, cola.constants.MESSAGE_DATA_CHANGE)
		assert.equal(message.path.join("."), "alias1")
		assert.equal(message.arg.value, node)

		messages = []
		node.setState("modified")
		assert.equal(messages.length, 2)
		assert.equal(messages[0].type, cola.constants.MESSAGE_STATE_CHANGE)

		messages = []
		node.set("name", "CHANGED1")
		assert.equal(messages.length, 2)
		assert.equal(messages[1].type, cola.constants.MESSAGE_DATA_CHANGE)

		messages = []
		model.set("alias1", null)
		assert.equal(messages.length, 1)
		assert.equal(messages[0].type, cola.constants.MESSAGE_DATA_CHANGE)

		messages = []
		node.set("name", "CHANGED2")
		assert.equal(messages.length, 1)
		assert.equal(messages[0].type, cola.constants.MESSAGE_DATA_CHANGE)

		messages = []
		model.set("alias1", node)
		model.set("alias2", node)
		assert.equal(messages.length, 2)
		assert.equal(messages[1].type, cola.constants.MESSAGE_DATA_CHANGE)

		messages = []
		node.set("name", "CHANGED3")
		assert.equal(messages.length, 3)
		assert.equal(messages[2].type, cola.constants.MESSAGE_DATA_CHANGE)

		messages = []
		model.data.disableObservers()
		node.set("name", "CHANGED4")
		model.data.enableObservers()
		assert.equal(messages.length, 0)

	it "Element binding", () ->
		model = new cola.Model()
		model.set(
			tree: {
				name: "node1"
				children: [
					{
						name: "node1.1"
					}
					{
						name: "node1.2"
					}
				]
			}
		)
		cola.currentScope = model

		element = new cola.Element({
			userData: "{{tree.name}}"
		})
		assert.isNotNull(element._bindExpression)
		assert.equal(element.get("userData"), "node1")

		model.set("tree.name", "CHANGED")
		assert.equal(element.get("userData"), "CHANGED")

		element = new cola.Element({
			userData: "{{tree.children.name}}"
		})
		assert.equal(element.get("userData"), "node1.1")

		model.get("tree.children").next()
		assert.equal(element.get("userData"), "node1.2")

	it "action", () ->
		model = new cola.Model()
		model.action({
			add: () ->
				model.add_count++

			ajax: {
				beforeExecute: () ->
					model.ajax_count++
			}
		})

		model.add_count = 0
		model.ajax_count = 0

		model.action.add()
		assert.equal(model.add_count, 1)

		model.action.ajax()
		assert.equal(model.ajax_count, 1)