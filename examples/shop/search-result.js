cola(function (model, param) {
	model.set({
		"searchResult": model.wrapper({
			url: "items/items.json?st=" + param.searchText
		})
	});

	model.widgetConfig({
		listSearchResult: {
			$type: "listView",
			ui: "product-list lightgrey",
			height: "100%",
			bind: "product in searchResult",
			columns: "row 4 6 8 12",
			highlightCurrentItem: false
		}
	});
});