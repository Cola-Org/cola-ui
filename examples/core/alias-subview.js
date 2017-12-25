cola(function(model) {
	model.action({
		addItem: function () {
			model.get("items").insert({
				name: "item " + (new Date()).getTime()
			});
		}
	});
});