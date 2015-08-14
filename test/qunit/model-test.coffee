QUnit.test "dom-template: simple attr", (assert) ->
	model = new cola.Model()
	model.set("text", "HelloWorld!")
	dom = $.xCreate({
		tagName: "div"
		"d-text": "text"
	})
	cola._compileDom(dom, model)

	assert.equal(dom.innerHTML, "HelloWorld!")

	model.set("text", "Wow!")
	assert.equal(dom.innerHTML, "Wow!")

QUnit.test "dom-template: simple content", (assert) ->
	model = new cola.Model()
	model.set("text", "HelloWorld!")
	dom = $.xCreate({
		tagName: "div"
		content: "{{text}}"
	})
	cola._compileDom(dom, model)

	assert.equal(dom.firstChild.innerHTML, "HelloWorld!")

	model.set("text", "Wow!")
	assert.equal(dom.firstChild.innerHTML, "Wow!")


QUnit.test "dom-template: style", (assert) ->
	model = new cola.Model()
	dom = $.xCreate({
		tagName: "div"
		"d-style": "width: style.width; height: style.height * 2"
	})
	cola._compileDom(dom, model)

	model.set("style", {
		width: 60
		height: 80
	})
	assert.equal(dom.style.width, "60px")
	assert.equal(dom.style.height, "160px")

	model.set("style.height", 18)
	assert.equal(dom.style.width, "60px")
	assert.equal(dom.style.height, "36px")

QUnit.test "dom-template: input and text", (assert) ->
	model = new cola.Model()
	model.set("name", "Tom")
	doms = {}
	dom = $.xCreate(
		tagName: "div"
		content: [
			{
				tagName: "input"
				contextKey: "input"
				"d-bind": "name"
			}
			{
				tagName: "span"
				contextKey: "span"
				"d-bind": "name"
			}
		], doms)
	cola._compileDom(dom, model)

	assert.equal(doms.input.value, "Tom")
	assert.equal(doms.span.innerHTML, "Tom")

	doms.input.value = "Mike"
	$(doms.input).trigger("input") # 模拟Input的onchange事件
	assert.equal(doms.input.value, "Mike")
	assert.equal(doms.span.innerHTML, "Mike")

QUnit.test "dom-template: alias", (assert) ->
	model = new cola.Model()
	model.set(
		category:
			name: "CategoryName"
			product: {
				name: "ProductName"
				price: 120
			}
	)

	doms = {}
	dom = $.xCreate(
		tagName: "div"
		"d-alias": "category.product as product"
		content: [
			{
				tagName: "span"
				contextKey: "name"
				"d-bind": "product.name"
			}
			{
				tagName: "span"
				contextKey: "price"
				"d-bind": "category.product.price"
			}
		], doms)
	cola._compileDom(dom, model)

	assert.equal(doms.name.innerHTML, "ProductName")
	assert.equal(doms.price.innerHTML, "120")

	model.set("category.product.price", 150)
	assert.equal(doms.name.innerHTML, "ProductName")
	assert.equal(doms.price.innerHTML, "150")

	model.set("category.product", {
		name: "NewProduct"
		price: 80
	})
	assert.equal(doms.name.innerHTML, "NewProduct")
	assert.equal(doms.price.innerHTML, "80")

QUnit.test "dom-template: repeat on EntityList", (assert) ->
	model = new cola.Model()
	model.set("region", {
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

	dom = $.xCreate(
		tagName: "div"
		content: [
			{
				tagName: "div"
				content: "Addresses"
			}
			{
				tagName: "div"
				class: "address"
				"d-repeat": "address in region.addresses"
				"d-text": "address.city"
			}
		])
	cola._compileDom(dom, model)

	nodes = dom.getElementsByClassName("address")
	assert.equal(nodes.length, 3)

	model.get("region.addresses").insert({
		city: "tianjin"
		postCode: 400002
	})
	nodes = dom.getElementsByClassName("address")
	assert.equal(nodes.length, 4)

	model.set("region.addresses.city", "CHANGED")
	assert.equal(nodes[0].innerHTML, "CHANGED")

	model.get("region.addresses").remove()
	nodes = dom.getElementsByClassName("address")
	assert.equal(nodes.length, 3)

	model.set("region.addresses", null)
	nodes = dom.getElementsByClassName("address")
	assert.equal(nodes.length, 0)

QUnit.test "dom-template: repeat on array", (assert) ->
	model = new cola.Model()
	model.set("region", {
		addresses: ["shanghai", "beijing", "shenzhen"]
	})

	dom = $.xCreate(
		tagName: "div"
		content: [
			{
				tagName: "div"
				content: "Addresses"
			}
			{
				tagName: "div"
				class: "address"
				"d-repeat": "address in region.addresses"
				"d-text": "address"
			}
		])
	cola._compileDom(dom, model)

	nodes = dom.getElementsByClassName("address")
	assert.equal(nodes.length, 3)
	assert.equal(nodes[0].innerHTML, "shanghai")

	model.set("region.addresses", ["shanghai", "beijing", "shenzhen", "tianjin"])
	nodes = dom.getElementsByClassName("address")
	assert.equal(nodes.length, 4)

	model.set("region.addresses", null)
	nodes = dom.getElementsByClassName("address")
	assert.equal(nodes.length, 0)

