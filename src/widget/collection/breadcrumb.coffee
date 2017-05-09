cola.defineWidget({
	tagName: "c-breadcrumb",
	attributes:
		bind: null
	events:
		itemClick: null
	template:
		class: "ui breadcrumb"
		content:
			tagName: "item", "c-repeat": "item in @bind",
			"c-onclick": "itemClick(item,$dom)",
			content: [
				{
					tagName: "a", "c-bind": "item.text",
					"c-href": "item.href||'#'", "c-target": "item.target||'_black'"
				},
				{
					tagName: "i"
				}
			]
	itemClick: (item, dom)->
		@fire("itemClick", @, {item: item, dom: dom})
		unless item.get("href")
			event.preventDefault()


})