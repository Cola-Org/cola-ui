_ = require "underscore"
sources =
	coffee:
		core: [
			"src/core/namespace.coffee"
			"src/core/x-create.coffee"
			"src/core/keyed-array.coffee"
			"src/core/util.coffee"
			"src/core/base.coffee"
			"src/core/ajax.coffee"
			"src/core/element.coffee"
			"src/core/date.coffee"
			"src/core/convertor.coffee"
			"src/core/expression.coffee"
			"src/core/service.coffee"
			"src/core/validator.coffee"
			"src/core/data-type.coffee"
			"src/core/entity.coffee"
			"src/core/model.coffee"
			"src/core/dom-util.coffee"
			"src/core/loader.coffee"
			"src/core/router.coffee"
			"src/core/dom-feature.coffee"
			"src/core/dom-binding.coffee"
			"src/core/dom-template.coffee"
		]
		widget: [
			"src/widget/util.coffee"
			"src/widget/fx.coffee"
			"src/widget/support.coffee"
			"src/widget/semantic-overrides.coffee"
			"src/widget/widget.coffee"
		]
		base: [
			"src/widget/base/abstract-container.coffee"
			"src/widget/base/link.coffee"
			"src/widget/base/button.coffee"
			"src/widget/base/date-picker.coffee"
			"src/widget/base/calendar.coffee"
			"src/widget/base/divider.coffee"
			"src/widget/base/iframe.coffee"
			"src/widget/base/sub-view.coffee"
			"src/widget/base/image.coffee"
			"src/widget/base/label.coffee"
			"src/widget/base/message-box.coffee"
			"src/widget/base/reveal.coffee"
			"src/widget/base/search.coffee"
		]
		edit: [
			"src/widget/edit/abstract-editor.coffee"
			"src/widget/edit/checkbox.coffee"
			"src/widget/edit/abstract-editor.coffee"
			"src/widget/edit/input.coffee"
			"src/widget/edit/progress.coffee"
			"src/widget/edit/radio.coffee"
			"src/widget/edit/rating.coffee"
			"src/widget/edit/select.coffee"
			"src/widget/edit/dropdown.coffee"
			"src/widget/edit/form.coffee"
		]
		layout: [
			"src/widget/layout/segment.coffee"
			"src/widget/layout/layer.coffee"
			"src/widget/layout/dialog.coffee"
			"src/widget/layout/modal.coffee"
			"src/widget/layout/sidebar.coffee"
			"src/widget/layout/tab.coffee"
		]
		collection: [
			"src/widget/collection/item-group.coffee"
			"src/widget/collection/breadcrumb.coffee"
			"src/widget/collection/card-book.coffee"
			"src/widget/collection/carousel.coffee"
			"src/widget/collection/menu.coffee"
			"src/widget/collection/menu-button.coffee"
			"src/widget/collection/shape.coffee"
			"src/widget/collection/steps.coffee"
			"src/widget/collection/stack.coffee"
		]
		list: [
			"src/widget/list/items-view.coffee"
			"src/widget/list/pull-action.coffee"
			"src/widget/list/list.coffee"
			"src/widget/list/tree-support.coffee"
			"src/widget/list/nested-list.coffee"
			"src/widget/list/tree.coffee"
			"src/widget/list/table-support.coffee"
			"src/widget/list/table.coffee"
		]
	less:
		cola: [
			"src/css/global.less"
			"src/css/box.less"
			"src/css/block-grid.less"
			"src/css/grid.less"
			"src/css/items-view.less"
			"src/css/list-view.less"
			"src/css/nested-list.less"
			"src/css/tree.less"
			"src/css/table.less"
			"src/css/input.less"
			"src/css/dropdown.less"
			"src/css/iframe.less"
			"src/css/message-box.less"
			"src/css/layer.less"
			"src/css/dialog.less"
			"src/css/transit.less"
			"src/css/slide.less"
			"src/css/carousel.less"
			"src/css/tab.less"
			"src/css/menu.less"
			"src/css/slide.less"
			"src/css/box.less"
			"src/css/picker.less"
			"src/css/calendar.less"
			"src/css/stack.less"
			"src/css/radio.less"
			"src/css/sidebar.less"
		]
	lib:
		js: [
			"src/lib/number-formatter.js"
			"src/lib/xdate.js"
			"src/lib/swipe.lite.js"
#			"src/lib/jquery-2.1.3.js"
			"src/lib/jquery.transit.js"

			"src/lib/jsep.js"

			"src/lib/animate.js"
			"src/lib/scroller.js"
			"src/lib/easy-scroller.js"

			"src/lib/fastclick.js"
			"src/lib/semantic-ui/semantic.js"
			"src/lib/hammer.js"
			"src/lib/jquery.hammer.js"
		]
		css: [
			"lib/semantic-ui/semantic.css"
		]
sources.coffee.widgetAll = _.union(sources.coffee.widget, sources.coffee.base,
	sources.coffee.layout,sources.coffee.edit, sources.coffee.collection, sources.coffee.list)

module?.exports = sources