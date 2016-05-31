cola(function (model, param) {
	model.set({
		"searchResult": cola.data({
			url: "items/items.json?st=" + param.searchText
		})
	});

	model.widgetConfig({
		listSearchResult: {
			$type: "listView",
			class: "product-list lightgrey",
			height: "100%",
			bind: "product in searchResult",
			columns: "row 4 6 8 12",
			highlightCurrentItem: false
		}
	});
});