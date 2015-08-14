QUnit.test "definitions", (assert) ->
	assert.equal(typeof $.xCreate, "function")

QUnit.test "simple div", (assert) ->
	div = $.xCreate(
		tagName: "div"
		content: "Some Text"
	)
	assert.ok(div != null)
	assert.equal(div.nodeName.toLowerCase(), "div")
	assert.equal(div.innerHTML, "Some Text")

QUnit.test "multi divs", (assert) ->
	divs = $.xCreate([
		{
			tagName: "div"
			content: "div1"
		}
		{
			tagName: "div"
			content: "div2"
		}
	])
	assert.ok(divs instanceof Array)
	assert.equal(2, divs.length)
	assert.equal(divs[0].nodeName.toLowerCase(), "div")
	assert.equal(divs[0].innerHTML, "div1")
	assert.equal(divs[1].nodeName.toLowerCase(), "div")
	assert.equal(divs[1].innerHTML, "div2")

QUnit.test "child span", (assert) ->
	div = $.xCreate(
		tagName: "div"
		content: {
			tagName: "span"
			content: "Some Text"
		}
	)
	assert.ok(div.firstChild != null)
	assert.equal(div.firstChild.nodeName.toLowerCase(), "span")
	assert.equal(div.firstChild.innerHTML, "Some Text")

QUnit.test "child span 2", (assert) ->
	div = $.xCreate(
		tagName: "div"
		content: "^span"
	)
	assert.ok(div.firstChild != null)
	assert.equal(div.firstChild.nodeName.toLowerCase(), "span")
	assert.equal(div.firstChild.innerHTML, "")

QUnit.test "input", (assert) ->
	input = $.xCreate(
		tagName: "input",
		type: "text"
		value: "value1"
	)
	assert.equal(input.nodeName.toLowerCase(), "input")
	assert.equal(input.type, "text")
	assert.equal(input.value, "value1")

QUnit.test "table", (assert) ->
	table = $.xCreate(
		tagName: "table"
		content: [
			{
				tagName: "tr"
				content: ["^td", "^td"]
			}
			{
				tagName: "tr"
				content: ["^td", "^td"]
			}
		]
	)
	assert.equal(table.nodeName.toLowerCase(), "table")
	tbody = table.firstChild
	assert.equal(tbody.nodeName.toLowerCase(), "tbody")
	assert.equal(tbody.rows.length, 2)

	row = tbody.rows[0]
	assert.equal(row.nodeName.toLowerCase(), "tr")
	assert.equal(row.cells.length, 2)

QUnit.test "text", (assert) ->
	text = $.xCreate("text content")
	assert.equal(text.nodeType, 3)

QUnit.test "event", (assert) ->
	clicked = false
	button = $.xCreate(
		tagName: "button"
		content: "Test"
		click: () ->
			clicked = true
			return
	)
	document.body.appendChild(button)
	button.click()
	document.body.removeChild(button)
	assert.equal(clicked, true)