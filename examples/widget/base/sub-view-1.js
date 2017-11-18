cola(function (model, param) {
	console.log("1");
	model.dataType({
		name: "TestDataType",
		properties: {
			id: {
				caption: "ID"
			},
			name: {
				caption: "Name"
			}
		}
	});
});