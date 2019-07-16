cola.registerTypeResolver "table.column", (config)->
	return unless config and config.$type
	type = cola.util.capitalize(config.$type)
	return cola["Table" + type + "Column"]

cola.registerTypeResolver "table.column", (config)->
	if config.columns?.length then return cola.TableGroupColumn
	return cola.TableDataColumn

class cola.TableColumn extends cola.Element
	@attributes:
		parent: null
		name:
			readOnlyAfterCreate: true
		caption:
			refreshColumns: true
		align:
			refreshColumns: true
			enum: [ "left", "center", "right" ]
		visible:
			refreshColumns: true
			type: "boolean"
			defaultValue: true
			refreshStructure: true
		headerTemplate:
			refreshColumns: true

	@events:
		renderHeader: null
		headerClick: null

	constructor: (config)->
		super(config)
		@_id = cola.uniqueId()
		@_name ?= @_id

		@on("attributeChange", (self, arg)=>
			return unless @_table
			attrConfig = @constructor.attributes[arg.attribute]
			return unless attrConfig
			if attrConfig.refreshStructure
				@_table._refreshItemsScheduled = true
				@_table._collectionColumnsInfo()
			return
		)

	_doSet: (attr, attrConfig, value)->
		if attrConfig?.refreshColumns
			@_table?._onColumnChange(attrConfig?.refreshItems)
		return super(attr, attrConfig, value)

	_setTable: (table)->
		@_table._unregColumn(@) if @_table
		@_table = table
		table._regColumn(@) if table
		return

	getTemplate: (type, defaultTemplate)->
		template = @["_real_" + type]
		return template if template isnt undefined

		templateDef = @get(type) or defaultTemplate
		return null unless templateDef

		if typeof templateDef is "string"
			if templateDef.indexOf("<") >= 0
				template = $.xCreate(templateDef)
			else if templateDef.match(/^\#[\w\-\$]*$/)
				template = cola.util.getGlobalTemplate(templateDef.substring(1))
				if template
					div = document.createElement("div")
					div.innerHTML = template
					template = div.firstElementChild
		else if typeof templateDef is "object"
			if templateDef.nodeType
				template = templateDef
			else
				template = $.xCreate(templateDef)

		if not template
			template = @_table.getTemplate(templateDef)

		@["_real_" + type] = template or null
		return template

class cola.TableGroupColumn extends cola.TableColumn
	@attributes:
		columns:
			refreshColumns: true
			refreshItems: true
			setter: (columnConfigs)->
				_columnsSetter.call(@, @_table, columnConfigs)
				return

	_setTable: (table)->
		super(table)
		if @_columns
			for column in @_columns
				column._setTable(table)
		return

class cola.TableContentColumn extends cola.TableColumn
	@attributes:
		width:
			refreshColumns: true
			defaultValue: 100
		valign:
			refreshColumns: true
			enum: [ "top", "center", "bottom" ]

		footerValue:
			refreshColumns: true
		footerTemplate:
			refreshColumns: true

	@events:
		renderCell: null
		renderFooter: null
		cellClick: null
		footerClick: null

class cola.TableDataColumn extends cola.TableContentColumn
	@attributes:
		property: null
		bind: null
		format: null
		template:
			refreshColumns: true
		sortable:
			refreshColumns: true
		sortDirection:
			refreshColumns: true
		resizeable:
			defaultValue: true

		readOnly: null
		editTemplate: null

class cola.TableNumColumn extends cola.TableContentColumn
	@attributes:
		width:
			defaultValue: "42px"
		align:
			defaultValue: "center"

	renderHeader: (dom)->

		$fly(dom).addClass("row-num")
		return

	renderCell: (dom)->
		$fly(dom).addClass("row-num")
		return


class cola.TableSelectColumn extends cola.TableContentColumn
	@attributes:
		width:
			defaultValue: "42px"
		align:
			defaultValue: "center"
	@events:
		headerSelectionChange: null
		itemSelectionChange: null

	renderHeader: (dom)->
		if not dom.firstElementChild
			@_headerCheckbox = checkbox = new cola.Checkbox(
				triState: true
				input: (self, arg)=>
					checked = self.get("checked")
					if checked isnt undefined
						@selectAll(checked)
					if typeof arg.value isnt "boolean"
						@fire("headerSelectionChange", @, { checkbox: self, oldValue: arg.oldValue, value: arg.value })
			)
			checkbox.appendTo(dom)
		return

	renderCell: (dom, item)->
		if not dom.firstElementChild
			checkbox = new cola.Checkbox(
				bind: @_table._alias + "." + @_table._selectedProperty
				input: (self, arg)=>
					if not @_ignoreCheckedChange
						@refreshHeaderCheckbox()
					arg.item = item
					@fire("itemSelectionChange", @, arg)
					return
			)
			oldRefreshValue = checkbox.refreshValue
			checkbox.refreshValue = ()=>
				oldValue = checkbox._value
				result = oldRefreshValue.call(checkbox)
				if checkbox._value isnt oldValue
					arg =
						model: checkbox.get("model")
						dom: checkbox._dom
						item: item
					@fire("itemSelectionChange", @, arg)
				return result

			checkbox.appendTo(dom)
		return

	refreshHeaderCheckbox: ()->
		return unless @_headerCheckbox
		cola.util.delay(@, "refreshHeaderCheckbox", 50, ()->
			table = @_table
			selectedProperty = table._selectedProperty
			if table._realItems
				i = 0
				selected = undefined
				cola.each @_table._realItems, (item)->
					itemType = table._getItemType(item)
					if itemType is "default"
						i++
						if item instanceof cola.Entity
							s = item.get(selectedProperty)
						else
							s = item[selectedProperty]

						if i is 1
							selected = s
						else if selected isnt s
							selected = undefined
							return false
					return

				@_headerCheckbox.set("value", selected)
			return
		)
		return

	selectAll: (selected)->
		table = @_table
		selectedProperty = table._selectedProperty
		if table._realItems
			@_ignoreCheckedChange = true
			cola.each table._realItems, (item)=>
				itemType = table._getItemType(item)
				if itemType is "default"
					if item instanceof cola.Entity
						item.set(selectedProperty, selected)
					else
						item[selectedProperty]
						table.refreshItem(item)
				return

			setTimeout(()=>
				@_ignoreCheckedChange = false
				return
			, 100)
		return

class cola.TableStateColumn extends cola.TableContentColumn
	@attributes:
		width:
			defaultValue: "36px"
		align:
			defaultValue: "center"

	renderCell: (dom, item)->
		if item instanceof cola.Entity
			message = item.getKeyMessage()
			if message
				if typeof message is "string"
					message =
						type: "error"
						text: message
				state = message.type
			else
				if item.state is cola.Entity.STATE_NEW
					state = "new"
				if item.state is cola.Entity.STATE_MODIFIED
					state = "modified"
			dom.className = "state " + (state or "")
		return

class cola.AbstractTable extends cola.Widget

	@attributes:
		columns:
			refreshItems: true
			setter: (columnConfigs)->
				_columnsSetter.call(@, @, columnConfigs)
				if @_rendered then @_collectionColumnsInfo()
				return

		showHeader:
			type: "boolean"
			defaultValue: true
		showFooter:
			type: "boolean"

		highlightCurrentItem:
			type: "boolean"
			defaultValue: true

	@events:
		renderItem: null
		renderCell: null
		renderHeaderCell: null
		renderFooterCell: null
		itemClick: null
		itemDoubleClick: null
		itemPress: null
		cellClick: null
		headerClick: null
		footerClick: null

	@templates:
		"default-row":
			tagName: "div"

		"boolean-column":
			"c-display": "$default"
			content:
				tagName: "i"
				class: "green checkmark icon"

	constructor: (config)->
		@_uniqueId = cola.uniqueId()
		@_columnMap = {}
		super(config)

	_regColumn: (column)->
		if column._name
			@_columnMap[column._name] = column
		return

	_unregColumn: (column)->
		if column._name
			delete @_columnMap[column._name]
		return

	getColumn: (name)->
		return @_columnMap[name]

	_onColumnChange: (refreshItems)->
		if @_rendered
			cola.util.delay(@, "onColumnChange", 50, ()=>
				@_collectionColumnsInfo()
				@_buildStyleSheet()
				if refreshItems
					@_refreshItemsScheduled = true
				@_refreshDom()
				@_refreshScrollbars()
				return
			)
		return

	_collectionColumnsInfo: ()->
		collectColumnInfo = (column, context, deepth, rootIndex)->
			if deepth + 1 > context.rows
				context.rows = deepth + 1

			info =
				rootIndex: rootIndex
				level: deepth
				column: column
			if column instanceof cola.TableGroupColumn
				if column._columns
					info.colInfos = colInfos = []
					for col in column._columns
						continue unless col._visible
						colInfos.push(collectColumnInfo(col, context, deepth + 1, rootIndex))
			else
				if column._bind
					bind = column._bind
					if bind.charCodeAt(0) is 46 # `.`
						if not column._property
							column._property = bind.substring(1)
					else
						info.expression = cola._compileExpression(@_scope, bind)

				if column._width
					width = column._width
					widthType = null
					if typeof width is "string"
						if width.indexOf("px") > 0
							widthType = "px"
						else if width.indexOf("%") > 0
							widthType = "%"
					widthType ?= "weight"
					info.widthType = widthType
					info.width = parseFloat(width)
					if widthType is "weight"
						context.totalWidthWeight += info.width

				info.index = context.dataColumns.length
				info.rootIndex = rootIndex
				context.dataColumns.push(info)

				if column instanceof cola.TableSelectColumn
					context.selectColumns ?= []
					context.selectColumns.push(info)
			return info

		@_columnsInfo = columnsInfo = {
			timestamp: cola.sequenceNo()
			totalWidthWeight: 0
			colInfos: []
			dataColumns: []
			rows: 1
			alias: "item"
		}
		if @_columns
			expression = @_itemsScope.expression
			if expression
				columnsInfo.alias = expression.alias

			leftFixedCols = @_leftFixedCols
			rightFixedCols = @_rightFixedCols

			if leftFixedCols > 0 or rightFixedCols > 0
				overflow = leftFixedCols + rightFixedCols - @_columns.length
				if overflow >= 0
					if rightFixedCols > overflow
						rightFixedCols -= (overflow + 1)
						overflow = -1
					else
						rightFixedCols = 0
						overflow -= rightFixedCols

					if overflow >= 0
						leftFixedCols -= (overflow + 1)

			if leftFixedCols < 0 then leftFixedCols = 0
			if rightFixedCols < 0 then rightFixedCols = 0

			for col, i in @_columns
				if not col._visible
					if i < leftFixedCols and leftFixedCols > 0
						leftFixedCols--
					if @_columns.length - i <= rightFixedCols and rightFixedCols > 0
						rightFixedCols--
					continue

				colInfo = collectColumnInfo(col, columnsInfo, 0, i)
				if colInfo
					columnsInfo.colInfos.push(colInfo)

			@_realLeftFixedCols = leftFixedCols
			@_realRightFixedCols = rightFixedCols

			if leftFixedCols > 0 or rightFixedCols > 0
				if leftFixedCols > 0
					columnsInfo.left =
						timestamp: columnsInfo.timestamp
						start: 0
						rows: columnsInfo.rows
						colInfos: columnsInfo.colInfos.slice(0, leftFixedCols)
						dataColumns: []
				else
					delete columnsInfo.left

				if rightFixedCols > 0
					columnsInfo.right =
						timestamp: columnsInfo.timestamp
						start: @_columns.length - rightFixedCols
						rows: columnsInfo.rows
						colInfos: columnsInfo.colInfos.slice(columnsInfo.colInfos.length - rightFixedCols, columnsInfo.colInfos.length)
						dataColumns: []
				else
					delete columnsInfo.right

				columnsInfo.center =
					timestamp: columnsInfo.timestamp
					start: leftFixedCols
					rows: columnsInfo.rows
					colInfos: columnsInfo.colInfos.slice(leftFixedCols, columnsInfo.colInfos.length - rightFixedCols)
					dataColumns: []

				for col in columnsInfo.dataColumns
					i = col.rootIndex
					if i < leftFixedCols
						columnsInfo.left.dataColumns.push(col)
					else if i >= @_columns.length - rightFixedCols
						columnsInfo.right.dataColumns.push(col)
					else
						columnsInfo.center.dataColumns.push(col)
			else
				delete columnsInfo.left
				delete columnsInfo.right
				columnsInfo.center =
					timestamp: columnsInfo.timestamp
					start: 0
					rows: columnsInfo.rows
					colInfos: columnsInfo.colInfos
					dataColumns: columnsInfo.dataColumns
		return

	_initDragDrop: (selector, dom)->
		$fly(dom).delegate(selector, "mousemove", (evt)=>
			return if @_innerDragging
			cell = $fly(evt.target).closest(".header-cell")[0]
			return unless cell

			if evt.offsetX <= 4
				resizePrevColumn = true
				nextColumn = @getColumn(cell._name)
				for nextColumnInfo in @_columnsInfo.dataColumns
					if nextColumnInfo.column is nextColumn
						column = columnInfo?.column
						break
					columnInfo = nextColumnInfo
			else if cell.offsetWidth - evt.offsetX <= 4
				column = @getColumn(cell._name)

			tableHeader = evt.currentTarget
			handler = @_getHeaderCellResizeHandler(".inner-table", tableHeader)
			if column?._resizeable
				$fly(handler).css(
					left: if resizePrevColumn then cell.offsetLeft else cell.offsetLeft + cell.offsetWidth
					top: cell.offsetTop
					height: cell.offsetHeight
				).removeClass("hidden")
				cola.util.userData(handler, "column", column)

				cell = @_getHeaderCellByColumn(selector + " .header-cell", column)
				cola.util.userData(handler, "cell", cell)
			else
				$fly(handler).addClass("hidden")
		).delegate(selector, "mouseenter", ()=>
			$fly(@_dom).find(">.inner-table >.table-header .header-cell").each (i, cell)=>
				if cell.className.indexOf("ui-draggable") < 0
					$fly(cell).draggable(
						appendTo: "body"
						distance: 10
						revert: "invalid"
						revertDuration: 200
						scroll: false
						refreshPositions: true
						helper: ()->
							helper = cell.cloneNode(true)
							$fly(helper).addClass("table-column-dragging-helper").width(cell.offsetWidth).height(cell.offsetHeight)
							return helper
						start: (evt, ui)=>
							ui.helper.draggingColumn = @getColumn(cell._name)
							return
						drag: (evt, ui)=>
							dragOverCell = ui.helper.dragOverCell
							if dragOverCell
								tableHeader = $fly(dragOverCell).closest(".table-header")[0]
								dragOverColumn = @getColumn(dragOverCell._name)
								if dragOverColumn
									ui.helper.dragOverColumn = dragOverColumn
									centerPosition = dragOverCell.offsetLeft + (dragOverCell.offsetWidth / 2)
									$indicator = $fly(@_getColumnInsertIndicator(tableHeader)).removeClass("hidden")
									dragPosLeft = ui.position.left + (dragOverCell.offsetWidth / 2)
									$indicator.css("top", dragOverCell.offsetTop)
									if dragPosLeft < centerPosition
										$indicator.css("left", dragOverCell.offsetLeft)
										ui.helper.dragOverMode = "before"
									else
										$indicator.css("left", dragOverCell.offsetLeft + dragOverCell.offsetWidth)
										ui.helper.dragOverMode = "after"
							return
					)

				if cell.className.indexOf("ui-droppable") < 0
					$fly(cell).droppable(
						accept: ".header-cell"
						over: (evt, ui)->
							ui.helper.dragOverCell = @
							return
						out: (evt, ui)=>
							if cell is ui.helper.dragOverCell
								tableHeader = $fly(ui.helper.dragOverCell).closest(".table-header")[0]
								ui.helper.dragOverCell = null
								ui.helper.dragOverColumn = null
								$fly(@_getColumnInsertIndicator(tableHeader)).addClass("hidden")
						drop: (evt, ui)=>
							shouldRefreshTable = false
							draggingColumn = ui.helper.draggingColumn
							dragOverColumn = ui.helper.dragOverColumn
							columns = dragOverColumn._parent?._columns
							if columns
								sourceColumns = draggingColumn._parent?._columns
								if sourceColumns
									i = sourceColumns.indexOf(draggingColumn)
									if i >= 0 then sourceColumns.splice(i, 1)
									if draggingColumn._parent isnt dragOverColumn._parent
										draggingColumn._parent.set("columns", sourceColumns)

								i = columns.indexOf(dragOverColumn)
								if ui.helper.dragOverMode is "after" then i++
								if i > columns.length - 1
									columns.push(ui.helper.draggingColumn)
								else
									columns.splice(i, 0, draggingColumn)
								dragOverColumn._parent.set("columns", columns)
								shouldRefreshTable = true

							if ui.helper.dragOverCell
								tableHeader = $fly(ui.helper.dragOverCell).closest(".table-header")[0]
								ui.helper.dragOverCell = null
								ui.helper.dragOverColumn = null
								$fly(@_getColumnInsertIndicator(tableHeader)).addClass("hidden")

							if shouldRefreshTable
								@_onColumnChange(true)
							return
					)
				return
			return
		)
		return

	_getHeaderCellByColumn: (selector, column)->
		headerCell = null
		@get$Dom().find(selector).each (i, cell)->
			if cell._name is column._name
				headerCell = cell
				return false
			return
		return headerCell

	_getHeaderCellResizeHandler: (offsetParentSelector, tableHeader)->
		table = @
		handler = tableHeader.querySelector(".resize-handler")
		if not handler
			handler = cola.xCreate(
				class: "resize-handler"
			)
			$(handler).draggable(
				axis: "x"
				start: ()->
					cell = cola.util.userData(@, "cell")
					helper = table._doms.resizeHelper
					if not helper
						helper = cola.xCreate(
							class: "resize-helper"
						)
						table._dom.appendChild(helper)
						table._doms.resizeHelper = helper

					offsetParent = $fly(cell).closest(offsetParentSelector)[0]
					$fly(helper).css(
						left: (offsetParent.offsetLeft + cell.offsetLeft - offsetParent.scrollLeft - 1) + "px"
						width: cell.offsetWidth + "px"
					).show()
					cola.util.userData(helper, "originalWidth", cell.offsetWidth)
					table._innerDragging = true
					return
				stop: ()->
					helper = table._doms.resizeHelper
					column = cola.util.userData(@, "column")
					column.set("width", helper.offsetWidth + "px")
					$fly(helper).hide()
					table._innerDragging = false
					return
				drag: (evt, ui)->
					helper = table._doms.resizeHelper
					originalWidth = cola.util.userData(helper, "originalWidth")
					$fly(helper).width(originalWidth + ui.position.left - ui.originalPosition.left)
					return
			)
			tableHeader.appendChild(handler)
		return handler

	_getColumnInsertIndicator: (tableHeader)->
		indicator = @_doms.columnInsertIndicator
		if not indicator
			@_doms.columnInsertIndicator = indicator = cola.xCreate(
				class: "insert-indicator"
			)
		if indicator.parentNode isnt tableHeader
			tableHeader.appendChild(indicator)
		return indicator

	_initDom: (dom)->
		dom.className += " " + @_uniqueId
		@_regDefaultTemplates()
		@_templateContext ?= {}
		return

	_parseDom: (dom)->
		return unless dom
		@_doms ?= {}

		child = dom.firstElementChild
		while child
			cola.xRender(child)
			child.setAttribute(cola.constants.IGNORE_DIRECTIVE, "")
			child = child.nextElementSibling

		columns = []
		child = dom.firstElementChild
		while child
			next = child.nextElementSibling
			nodeName = child.nodeName
			if nodeName is "TEMPLATE"
				@regTemplate(child)
			else
				map = @_getNodeNameColumnMap()
				if map.hasOwnProperty(nodeName)
					column = @_parseColumnDom(child)
					column.$type = map[nodeName]

				if column
					columns.push(column)
				dom.removeChild(child)
			child = next

		@set("columns", columns) if columns.length

		@_createInnerDom(dom)
		return

	_parseColumnDom: (dom)->
		column = {}
		for attr in dom.attributes
			attrName = attr.name
			if attrName.substring(0, 2) is "c-"
				expression = cola._compileExpression(@_scope, attr.value)
				column[attrName.substring(2)] = expression
			else
				column[attrName] = attr.value

		child = dom.firstElementChild
		while child
			next = child.nextElementSibling
			nodeName = child.nodeName
			if nodeName is "TEMPLATE"
				templateName = child.getAttribute("name")
				if templateName and templateName.indexOf("header") is 0
					templateName = "headerTemplate"
				else if templateName and templateName.indexOf("footer") is 0
					templateName = "footerTemplate"
				else if templateName and templateName.indexOf("edit") is 0
					templateName = "editTemplate"
				else
					templateName = "template"
				column[templateName] = @trimTemplate(child)
			else if child.nodeType is 1
				subColumn = @_parseColumnDom(child)
				column.columns ?= []
				column.columns.push(subColumn)
			child = next
		return column

	_doSet: (attr, attrConfig, value)->
		if attrConfig?.refreshItems
			attrConfig.refreshDom = true
			@_refreshItemsScheduled = true
		return super(attr, attrConfig, value)

	_buildStyleSheet: (selector)->
		return unless @_columnsInfo?.dataColumns

		clientWidth = @_dom.clientWidth + 1
		if @_scrollMode is "scroll"
			clientWidth -= @constructor.scrollBarWidth

		realTotalWidth = 0
		weightColumns = []

		leftPaneWidth = 0
		rightPaneWidth = 0
		centerPaneWidth = 0

		columnCssDefs = []
		for colInfo in @_columnsInfo.dataColumns
			if colInfo.widthType is "weight"
				weightColumns.push(colInfo)
				continue

			def = ".#{colInfo.column._id}{"

			if colInfo.widthType is "%"
				if clientWidth > 0
					width = Math.round(colInfo.width * clientWidth / 100)
					widthType = "px"
					realTotalWidth += width
				else
					width = colInfo.width
					widthType = "%"
			else
				width = Math.round(colInfo.width) or 80
				widthType = colInfo.widthType or "px"
				realTotalWidth += width

			if colInfo.index < @_realLeftFixedCols and widthType is "px"
				leftPaneWidth += width
			else if @_columnsInfo.dataColumns.length - colInfo.index <= @_realRightFixedCols and widthType is "px"
				rightPaneWidth += width
			else
				centerPaneWidth += width

			def += "width:#{width}#{widthType};"
			def += "}"
			columnCssDefs.push(def)

		clientWidthForWeight = clientWidth - realTotalWidth
		totalWidthWeight = @_columnsInfo.totalWidthWeight
		adjust = 0
		for colInfo, i in weightColumns
			if colInfo.widthType isnt "weight"
				continue

			def = ".#{colInfo.column._id}{"

			minWidth = colInfo.width
			if clientWidth > 0
				rawWidth = colInfo.width * clientWidthForWeight / totalWidthWeight + adjust
				width = Math.floor(rawWidth)
				if width < minWidth then width = minWidth
				realTotalWidth += width
				adjust = rawWidth - width
				def += "width:#{width}px;"

				if colInfo.index < @_realLeftFixedCols
					leftPaneWidth += width
				else if @_columnsInfo.dataColumns.length - colInfo.index <= @_realRightFixedCols
					rightPaneWidth += width
				else
					centerPaneWidth += width
			else
				width = Math.round(colInfo.width * 100 / totalWidthWeight)
				def += "width:#{width}%; min-width:#{colInfo.width}px"

			def += "}"
			columnCssDefs.push(def)

		if leftPaneWidth or rightPaneWidth
			def = ".#{@_uniqueId}{"
			def += "padding-left:#{leftPaneWidth}px;padding-right:#{rightPaneWidth}px;"
			def += "}"
			columnCssDefs.push(def)

		def = ".#{@_uniqueId} #{@_mainItemsContainer}{"
		def += "width:#{centerPaneWidth}px;"
		def += "}"
		columnCssDefs.push(def)

		head = document.querySelector("head") or document.documentElement
		@_styleSheetDom ?= $.xCreate(
			tagName: "style"
			type: "text/css"
		)
		@_styleSheetDom.innerHTML = "\n" + columnCssDefs.join("\n") + "\n"
		head.appendChild(@_styleSheetDom)

		return {
			clientWidth: clientWidth
			totalWidth: realTotalWidth
			leftPaneWidth: leftPaneWidth
			rightPaneWidth: rightPaneWidth
		}

	_doItemsLoadingStart: (arg)->
		@_showLoadingTip()
		return

	_doItemsLoadingEnd: (arg)->
		@_hideLoadingTip()
		return

	_showLoadingTip: ()->
		$loaderContainer = @_$loaderContainer
		if not $loaderContainer and @_$dom
			$dom = @_$dom
			$dom.xAppend(
				class: "loader-container"
				content:
					class: "ui loader"
			)
			@_$loaderContainer = $loaderContainer = $dom.find(">.loader-container");
		$loaderContainer.addClass("active")
		return

	_hideLoadingTip: ()->
		@_$loaderContainer?.removeClass("active")
		return

cola.Element.mixin(cola.AbstractTable, cola.TemplateSupport)
cola.Element.mixin(cola.AbstractTable, cola.DataItemsWidgetMixin)