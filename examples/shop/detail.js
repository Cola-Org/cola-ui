cola(function (model, param) {
	model.set({
		"product": model.wrapper({
			url: "items/item.json?itemId=" + param.itemId
		}),
		"recommandedProducts": model.wrapper({
			url: "items/recommanded.json"
		})
	});

	model.action({});

	model.widgetConfig({
		listRecommandedProducts: {
			$type: "listView",
			ui: "product-list lightgrey",
			bind: "product in recommandedProducts",
			columns: "3 6 9 12",
			highlightCurrentItem: false
		},
		buttonFavorite: {
			$type: "button",
			ui: "orange",
			icon: "star"
		},
		buttonAddToCart: {
			$type: "button",
			ui: "red",
			icon: "add to cart",
			caption: "Buy"
		}
	});
});