cola(function (model) {
	model.set({
		"recommandedProducts": cola.data({
			url: "items/recommanded.json"
		}),
		"newProducts": cola.data({
			url: "items/items.json"
		})
	});

	model.widgetConfig({
		listNewProducts: {
			$type: "listView",
			class: "product-list lightgrey",
			bind: "product in newProducts",
			columns: "2 4 6 8 12",
			highlightCurrentItem: false
		}
	});
});