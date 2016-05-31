//var picker = new cola.mobile.DateTimePicker({
//	type: "date"
//});
//document.body.appendChild(picker.getDom());
//picker.updateItems();
//$(window).on("load",function(){$(".sys-dimmer").addClass("active")});





var container = new cola.Segment({
	content: [
		{
			$type: "Button",
			caption: "日期",
			userDate: "date",
			click: function () {
				cola.mobile.showDateTimePicker({
					type: "date",
					value: new Date(),
					onHide: function (picker) {
						alert(picker.get("value"))
					}
				})
			}
		}, {
			$type: "Button",
			caption: "年月",
			userDate: "month",
			click: function () {
				cola.mobile.showDateTimePicker({
					type: "month",value: new Date()
				})
			}
		}, {
			$type: "Button",
			caption: "时间",
			userDate: "time",
			click: function () {
				cola.mobile.showDateTimePicker({
					type: "time",
					value: new Date()
				})
			}
		}

	]
});

document.body.appendChild(container.getDom());
