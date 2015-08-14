cola(function (model) {
	model.set({
		"recommandedProducts": model.wrapper({
			url: "items/recommanded.json"
		}),
		"newProducts": model.wrapper({
			url: "items/items.json"
		})
	});

	model.widgetConfig({
		listNewProducts: {
			$type: "listView",
			ui: "product-list lightgrey",
			bind: "product in newProducts",
			columns: "2 4 6 8 12",
			highlightCurrentItem: false
		}
	});
});