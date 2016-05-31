cola(function (model, param) {
	model.set({
		"history": cola.data({
			url: "items/search-history.json"
		})
	});

	model.action({
		search: function () {
			var searchText = model.get("searchText");
			if (!searchText) return;

			var viewSearchResult = cola.widget("viewSearchResult");
			viewSearchResult.loadIfNecessary({
				url: "search-result.html",
				jsUrl: "$",
				cssUrl: "$",
				param: { searchText: searchText }
			}, function () {
				cola.widget("layerSearchResult").show();
			});
			return false;
		}
	});

	model.widgetConfig({
		inputSearch: {
			$type: "input",
			bind: "searchText",
			class: "transparent inverted",
			placeholder: "Search...",
			width: "100%",
			click: function() {
				var layerSearchResult = cola.widget("layerSearchResult");
				if (layerSearchResult.get("visible")) {
					layerSearchResult.hide();
				}
			}
		},
		buttonSearch: {
			icon: "search",
			click: function () {
				model.action.search();
			}
		},
		listHistory: {
			$type: "listView",
			bind: "history",
			highlightCurrentItem: false,
			itemClick: function (self, arg) {
				model.set("searchText", arg.item);
				model.action.search();
			}
		}
	});
});