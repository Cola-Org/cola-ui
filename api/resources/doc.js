$(".menu .item").tab();
var jsBeautifyOptions = {
	space_before_conditional: true,
	keep_array_indentation: false,
	preserve_newlines: true,
	unescape_strings: true,
	jslint_happy: false,
	brace_style: "end-expand",
	indent_char: " ",
	indent_size: 4
};
$(".description>code").each(function () {
	var $dom = $(this);
	var html = $dom.html();
	$dom.addClass("prettyprint")
	var code = js_beautify(html.toString(), jsBeautifyOptions);
	$dom.text(code)
});
$("#searchInput").on("input", function () {
	var value = this.value.toLowerCase();
	$("#toc .data-item").each(function () {
		var $dom = $(this);
		var state = $dom.text().toLowerCase().indexOf(value) > -1;
		$dom.toggleClass("hidden", !state);
	})
});

prettyPrint();
cola(function (model) {
})

cola.ready(function () {
		var hash = location.hash;
		var tabName, itemName;
		$("#showSidebarBtn").click(function () {
			cola.widget("sidebar").show()
		});
		$("#backButton").click(function () {
			cola.widget("sidebar").hide()
		});
		$("#sidebarSearchInput").on("input", function () {
			var value = this.value.toLowerCase();
			$("#sidebar .data-item").each(function () {
				var $dom = $(this);
				var state = $dom.text().toLowerCase().indexOf(value) > -1;
				$dom.toggleClass("hidden", !state);
			})
		});
		var tabNameMapping = {
			method: "methods",
			attribute: "attributes",
			property: "methods",
			event: "events"
		};


		if (hash) {
			hash = hash.substring(1, hash.length);
			if (hash.indexOf(":") > -1) {
				var target = hash.split(":");
				tabName = tabNameMapping[target[0]];
				itemName = target[1];
			} else {
				tabName = "attributes"
				itemName = hash
			}

			if (tabName) {
				$(".menu .item").tab("change tab", tabName);

				var tabDom = $("div.ui.tab[data-tab='" + tabName + "']");

				if (itemName && tabDom) {
					var items = tabDom.find("[data-key='" + itemName + "']");

					if (items.length > 0) {
						var $itemDom = $(items[0].parentNode);
						var tabTopPosition = $(tabDom).offset().top;
						var itemPosition = $itemDom.offset().top;
						$(tabDom)
							.animate({
								scrollTop: itemPosition - tabTopPosition
							}, 500, function () {
								$itemDom.addClass('target');
								setTimeout(function () {
									$itemDom.removeClass('target');
								}, 1000)
							})
					}
				}
			}
		}
	}
)