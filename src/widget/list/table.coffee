_columnsSetter = (table, columnConfigs)->
	if @_columns
		for column in @_columns
			delete column._parent
			column._setTable(null)

	columns = []
	if columnConfigs
		for columnConfig in columnConfigs
			continue unless columnConfig
			if columnConfig instanceof cola.TableColumn
				column = columnConfig
				if column._parent and column._parent isnt @
					parentColumns = column._parent._columns
					if parentColumns
						i = parentColumns.indexOf(column)
						if i >= 0
							parentColumns.splice(i, 1)
						column._parent.set("columns", parentColumns)
			else
				column = cola.create("table.column", columnConfig, cola.TableColumn)

			column._parent = @
			column._setTable(table)
			columns.push(column)
	@_columns = columns
	return

class cola.Table extends cola.Widget
	@tagName: "c-table"
	@className: "items-view widget-table"

	@scrollBarWidth = 10

	@attributes:
		items:
			refreshItems: true
			setter: (items)->
				return if @_items is items
				@_set("bind", undefined)
				@_items = items
				return
		bind:
			setter: (bindStr)->
				return if @_bindStr is bindStr
				@_set("items", undefined)
				@_bindSetter(bindStr)
				return

		columns:
			refreshItems: true
			setter: (columnConfigs)->
				_columnsSetter.call(@, @, columnConfigs)
				@_collectionColumnsInfo()
				return
		dataType:
			setter: cola.DataType.dataTypeSetter

		showHeader:
			type: "boolean"
			defaultValue: true
		showFooter:
			type: "boolean"

		scrollMode:
			defaultValue: "auto" # auto/scroll
			readOnlyAfterCreate: true
		selectedProperty:
			defaultValue: "selected"

		sortMode:
			defaultValue: "remote" # local/remote
		sortCriteria:
			refreshItems: true
			setter: (sortCriteria)->
				@_sortCriteria = sortCriteria
				@_centerTable._sortCriteria = sortCriteria
				return

		readOnly:
			type: "boolean"
			defaultValue: true

		leftFixedCols:
			defaultValue: 0
			setter: (value)->
				@_leftFixedCols = value
				if @_rendered then @_collectionColumnsInfo()
				return

		rightFixedCols:
			defaultValue: 0
			setter: (value)->
				@_rightFixedCols = value
				if @_rendered then @_collectionColumnsInfo()
				return

		allowNoCurrent:
			type: "boolean"
		currentPageOnly:
			type: "boolean"
			defaultValue: true
		highlightCurrentItem:
			type: "boolean"
			defaultValue: true
		changeCurrentItem:
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
		sortDirectionChange: null

	@TEMPLATES:
		"default-row":
			tagName: "div"

		"boolean-column":
			"c-display": "$default"
			content:
				tagName: "i"
				class: "green checkmark icon"
		"checkbox-column":
			tagName: "c-checkbox"
			bind: "$default"
		"toggle-column":
			tagName: "c-toggle"
			bind: "$default"
		"input-column":
			tagName: "c-input"
			bind: "$default"
		"date-picker-column":
			tagName: "c-datepicker"
			bind: "$default"

		"input":
			tagName: "c-input"
			bind: "$default"
		"checkbox":
			class: "editor-container"
			content:
				tagName: "c-checkbox"
				bind: "$default"
		"toggle":
			class: "editor-container"
			content:
				tagName: "c-toggle"
				bind: "$default"
		"date-picker":
			tagName: "c-date-picker"
			bind: "$default"

	constructor: (config)->
		@_columnMap = {}
		super(config)

	_getItems: ()->
		if @_items
			return { items: @_items }
		else
			return super()

	_getItemScope: (parentScope, alias, item)->
		itemScope = parentScope.getItemScope(item)
		if itemScope
			cola.currentScope = itemScope
		else
			itemScope = new cola.ItemScope(parentScope, alias)
			cola.currentScope = itemScope
			itemScope.data.setItemData(item, true)
		return itemScope

	_getItemType: (type)->
		return @_centerTable._getItemType(type)

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

	_createDom: ()->
		dom = cola.xCreate({})
		@_doms ?= {}
		@_createInnerDom(dom)
		return dom

	_createInnerDom: (dom)->
		@_centerTable = new cola.Table.InnerTable(
			scope: @_scope
			type: "center"
			table: @
			sortCriteria: @_sortCriteria
		)
		@_centerTable.appendTo(dom)

		if @_scrollMode is "scroll"
			@_createVertScrollBar()

		$fly(dom).on("mouseenter", (evt)=>
			@_mouseIn = true
			@_refreshScrollbars()
		).on("mouseleave", (evt)=>
			@_mouseIn = false
		).on("sizingChange", ()=>
			@_buildStyleSheet()
			@_refreshScrollbars()
			return
		)
		return

	_refreshScrollbars: ()->
		table = @
		dom = @_dom
		innerTable = @_centerTable._dom
		if innerTable.scrollWidth > (innerTable.clientWidth + 2)
			if not @_horiScrollBar and table._mouseIn
				@_horiScrollBar = cola.xCreate({
					class: "scroll-bar hori"
					content:
						class: "fake-content"
					scroll: ()->
						return if table._ignoreScrollbarMove
						innerTable.scrollLeft = @scrollLeft / @scrollWidth * innerTable.scrollWidth
						return
				})
				dom.appendChild(@_horiScrollBar)

			horiScrollBar = @_horiScrollBar
			if horiScrollBar
				horiScrollBar.querySelector(".fake-content").style.width =
				  (innerTable.scrollWidth / innerTable.clientWidth * dom.clientWidth) + "px"
				horiScrollBar.scrollLeft = innerTable.scrollLeft / innerTable.scrollWidth * horiScrollBar.scrollWidth
				horiScrollBar.style.display = ""

			@_$dom.addClass("h-scroll")
		else
			if @_horiScrollBar
				@_horiScrollBar.style.display = "none"
			@_$dom.removeClass("h-scroll")

		tableBody = @_centerTable._doms.tableBody
		if tableBody.scrollHeight > (tableBody.clientHeight + 2)
			if not @_vertScrollBar and table._mouseIn
				@_vertScrollBar = @_createVertScrollBar()

			vertScrollBar = @_vertScrollBar
			if vertScrollBar
				vertScrollBar.querySelector(".fake-content").style.height =
				  (tableBody.scrollHeight / tableBody.clientHeight * dom.clientHeight) + "px"
				vertScrollBar.scrollTop = tableBody.scrollTop / tableBody.scrollHeight * vertScrollBar.scrollHeight
				vertScrollBar.style.display = ""
		else if @_vertScrollBar
			@_vertScrollBar.style.display = "none"
		return

	_createVertScrollBar: ()->
		table = @
		@_vertScrollBar = cola.xCreate({
			class: "scroll-bar vert"
			content:
				class: "fake-content"
			scroll: ()->
				return if table._ignoreScrollbarMove
				tableBody = table._centerTable._doms.tableBody
				scrollTop = @scrollTop / @scrollHeight * tableBody.scrollHeight
				tableBody.scrollTop = scrollTop
				table._leftTable?._doms.tableBody.scrollTop = scrollTop
				table._rightTable?._doms.tableBody.scrollTop = scrollTop
				return
		})
		@_dom.appendChild(@_vertScrollBar)
		return @_vertScrollBar

	_initDragDrop: (dom)->
		$fly(dom).delegate(">.inner-table >.table-header", "mousemove", (evt)=>
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
			handler = @_getHeaderCellResizeHandler(tableHeader)
			if column?._resizeable
				$fly(handler).css(
					left: if resizePrevColumn then cell.offsetLeft else cell.offsetLeft + cell.offsetWidth
					top: cell.offsetTop
					height: cell.offsetHeight
				).removeClass("hidden")
				cola.util.userData(handler, "column", column)

				cell = @_getHeaderCellByColumn(column)
				cola.util.userData(handler, "cell", cell)
			else
				$fly(handler).addClass("hidden")
		).delegate(">.inner-table >.table-header", "mouseenter", ()=>
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

	_initDom: (dom)->
		@_regDefaultTemplates()
		@_templateContext ?= {}

		if $.fn.draggable
			@_initDragDrop(dom)

		dataType = @_getBindDataType()
		if dataType and dataType instanceof cola.EntityDataType
			if not @_columns
				columnConfigs = []
				for propertyDef in dataType.getProperties().elements
					columnConfigs.push(
						caption: propertyDef._caption
						bind: propertyDef._property
					)
				@set("columns", columnConfigs)

			if @_columns
				for column in @_columns
					if not column._property then continue

					propertyDef = dataType.getProperty(column._property)
					column._propertyDef = propertyDef
					if propertyDef and not column._caption
						column._caption = propertyDef._caption or propertyDef._property
		return

	_getHeaderCellByColumn: (column)->
		headerCell = null
		@get$Dom().find(">.inner-table >.table-header .header-cell").each (i, cell)->
			if cell._name is column._name
				headerCell = cell
				return false
			return
		return headerCell

	_getHeaderCellResizeHandler: (tableHeader)->
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

					innerTable = $fly(cell).closest(".inner-table")[0]
					$fly(helper).css(
						left: (innerTable.offsetLeft + cell.offsetLeft - innerTable.scrollLeft - 1) + "px"
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

	_parseDom: (dom)->
		return unless dom
		@_doms ?= {}

		@_uniqueId ?= cola.uniqueId()
		dom.className += " " + @_uniqueId

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
				if nodeName is "COLUMN"
					column = @_parseColumnDom(child)
				else if nodeName is "SELECT-COLUMN"
					column = @_parseColumnDom(child)
					column.$type = "select"
				else if nodeName is "STATE-COLUMN"
					column = @_parseColumnDom(child)
					column.$type = "state"
				if column then columns.push(column)
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

	_buildStyleSheet: ()->
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
			def = ".#{@_uniqueId} {"
			def += "padding-left:#{leftPaneWidth}px;padding-right:#{rightPaneWidth}px;"
			def += "}"
			columnCssDefs.push(def)

		def = ".#{@_uniqueId} >.center.ui.inner-table >.table-body{"
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

	_doRefreshDom: ()->
		return unless @_dom
		super()

		if @_refreshItemsScheduled
			delete @_refreshItemsScheduled
			@_leftTable?._refreshItemsScheduled = true
			@_rightTable?._refreshItemsScheduled = true
			@_centerTable._refreshItemsScheduled = true

			@_classNamePool.toggle("highlight-current", @_highlightCurrentItem)
			@_classNamePool.toggle("v-scroll", @_scrollMode is "scroll")
			@_classNamePool.toggle("has-left-pane", @_realLeftFixedCols > 0)
			@_classNamePool.toggle("has-right-pane", @_realRightFixedCols > 0)

			if not @_columnsInfo
				@_collectionColumnsInfo()
			@_refreshItems()
		return

	refreshItem: (item)->
		@_leftTable?.refreshItem(item)
		@_rightTable?.refreshItem(item)
		@_centerTable.refreshItem(item)
		return

	_onItemRefresh: (arg)->
		item = arg.entity
		if typeof item is "object"
			@refreshItem(item)
		return

	_onItemsRefresh: ()->
		return @_refreshItems()

	_refreshItems: ()->
		if not @_dom
			@_refreshItemsScheduled = true
			return

		if @_columnsTimestamp isnt @_columnsInfo.timestamp or @_oldClientWidth = @_dom.clientWidth
			@_columnsTimestamp = @_columnsInfo.timestamp
			@_oldClientWidth = @_dom.clientWidth

			$centerTableDom = @_centerTable.get$Dom()
			if @_columnsInfo.left and not @_leftTable
				@_leftTable = new cola.Table.InnerTable(
					type: "left"
					table: @
				)
				$centerTableDom.before(@_leftTable.getDom())
			if @_columnsInfo.right and not @_rightTable
				@_rightTable = new cola.Table.InnerTable(
					type: "right"
					table: @
				)
				$centerTableDom.after(@_rightTable.getDom())

			@_buildStyleSheet()

			@_leftTable?.set("columnsInfo", @_columnsInfo.left)
			@_rightTable?.set("columnsInfo", @_columnsInfo.right)
			@_centerTable.set("columnsInfo", @_columnsInfo.center)

		@_leftTable?._refreshItems()
		@_rightTable?._refreshItems()
		@_centerTable._refreshItems()

		if @_columnsInfo.selectColumns
			cola.util.delay(@, "refreshHeaderCheckbox", 50, ()=>
				for colInfo in @_columnsInfo.selectColumns
					colInfo.column.refreshHeaderCheckbox()
				return
			)

		cola.util.delay(@, "refreshScrollbars", 300, @_refreshScrollbars)
		return

	_onCurrentItemChange: (arg)->
		@_leftTable?._onCurrentItemChange(arg)
		@_rightTable?._onCurrentItemChange(arg)
		@_centerTable._onCurrentItemChange(arg)
		return

	_onItemInsert: (arg)->
		@_refreshItems()
		return

	_onItemRemove: (arg)->
		@_refreshItems()

		if @_columnsInfo.selectColumns
			cola.util.delay(@, "refreshHeaderCheckbox", 50, ()=>
				for colInfo in @_columnsInfo.selectColumns
					colInfo.column.refreshHeaderCheckbox()
				return
			)
		return

	_getCurrentItem: ()->
		return @_centerTable._getCurrentItem()

	_onBlur: ()->
		@_currentInnerTable?.hideCellEditor()
		return

	_onKeyDown: (evt)->
		centerTable = @_centerTable

		if evt.keyCode is 9 # Tab
			currentItem = @_getCurrentItem()
			return unless currentItem

			dataColumns = @_columnsInfo.dataColumns
			index = -1
			for columnInfo, i in dataColumns
				if columnInfo.column is @_currentColumn
					index = i
					break

			while not nextColumnInfo
				if evt.shiftKey
					if index <= 0 or index > dataColumns.length - 1
						index = dataColumns.length - 1
						itemDom = centerTable._getPreviousItemDom(centerTable._currentItemDom)
						if itemDom
							centerTable._setCurrentItemDom(itemDom)
							currentItem = centerTable._getCurrentItem()
					else
						index--
				else
					if index < 0 or index >= dataColumns.length - 1
						index = 0
						itemDom = centerTable._getNextItemDom(centerTable._currentItemDom)
						if itemDom
							centerTable._setCurrentItemDom(itemDom)
							currentItem = centerTable._getCurrentItem()
					else
						index++

				columnInfo = dataColumns[index]
				# if not columnInfo.column._readOnly and columnInfo.column._property
				nextColumnInfo = columnInfo

			if nextColumnInfo and currentItem
				if @_columnsInfo.center.dataColumns.indexOf(nextColumnInfo) >= 0
					innerTable = centerTable
				else if @_columnsInfo.left?.dataColumns.indexOf(nextColumnInfo) >= 0
					innerTable = @_leftTable
				else if @_columnsInfo.right?.dataColumns.indexOf(nextColumnInfo) >= 0
					innerTable = @_rightTable

				innerTable.setCurrentCell(currentItem, nextColumnInfo.column)
				return false

		else if evt.keyCode is 38 # up
			currentItem = @_getCurrentItem()
			if currentItem
				itemDom = centerTable._getPreviousItemDom(centerTable._currentItemDom)
			else
				itemDom = @_getNextItemDom()

			if itemDom
				centerTable._setCurrentItemDom(itemDom)
				currentItem = centerTable._getCurrentItem()
				if currentItem and @_currentInnerTable
					@_currentInnerTable.setCurrentCell(currentItem, @_currentColumn)

		else if evt.keyCode is 40 # down
			currentItem = @_getCurrentItem()
			if currentItem
				itemDom = centerTable._getNextItemDom(centerTable._currentItemDom)
			else
				itemDom = @_getFirstItemDom()

			if itemDom
				centerTable._setCurrentItemDom(itemDom)
				currentItem = centerTable._getCurrentItem()
				if currentItem and @_currentInnerTable
					@_currentInnerTable.setCurrentCell(currentItem, @_currentColumn)
		return

	_sysHeaderClick: (column)->
		if column instanceof cola.TableDataColumn and column.get("sortable")
			sortDirection = column.get("sortDirection")
			if sortDirection is "asc" then sortDirection = "desc"
			else if sortDirection is "desc" then sortDirection = null
			else sortDirection = "asc"
			column.set("sortDirection", sortDirection)

			collection = @_realOriginItems or @_realItems
			if not collection then return

			if not sortDirection
				criteria = null
			else
				criteria = if sortDirection is "asc" then "+" else "-"
				property = column._bind
				if not property or property.match(/\(/)
					property = column._property
				if not property then return

				if property.charCodeAt(0) is 46 # `.`
					property = property.slice(1)
				else if @_alias and property.indexOf("." + @_alias) is 0
					property = property.slice(@_alias.length + 1)
				criteria += property

			colInfos = @_columnsInfo.dataColumns
			for colInfo in colInfos
				col = colInfo.column
				if col isnt column then col.set("sortDirection", null)

			if @_sortMode is "remote"
				if collection instanceof cola.EntityList
					invoker = collection._providerInvoker

				if @fire("sortDirectionChange", @, {
					column: column
					invoker: invoker
					sortDirection: sortDirection
				}) is false
					return

				if collection instanceof cola.EntityList and invoker
					parameter = invoker.ajaxService.get("parameter")
					if not parameter
						invoker.ajaxService.set("parameter", parameter = {})
					else if typeof parameter isnt "object" or parameter instanceof cola.EntityList or parameter instanceof Date
						throw new cola.Exception("Can not set sort parameter automatically.")

					if parameter instanceof cola.Entity
						parameter.set(cola.setting("defaultSortParameter", ) or "sort", criteria)
					else
						parameter[cola.setting("defaultSortParameter") or "sort"] = criteria

					cola.util.flush(collection)
			else
				if @fire("sortDirectionChange", @, {
					column: column
					sortDirection: sortDirection
				}) is false
					return

				@set("sortCriteria", criteria)
		return

cola.registerWidget(cola.Table)
cola.Element.mixin(cola.Table, cola.TemplateSupport)
cola.Element.mixin(cola.Table, cola.DataItemsWidgetMixin)

class cola.Table.InnerTable extends cola.AbstractList
	@className: "inner-table"

	manageItemScope: false

	@attributes:
		type: null
		table: null
		columnsInfo: null

	constructor: (config)->
		@_itemsScope = config.table._itemsScope
		@_alias = config.table._alias

		config.allowNoCurrent = config.table._allowNoCurrent
		config.currentPageOnly = config.table._currentPageOnly
		config.highlightCurrentItem = config.table._highlightCurrentItem
		config.changeCurrentItem = config.table._changeCurrentItem

		super(config)
		@_focusParent = @_table
		@on("itemClick", (self, arg)=> @_table.fire("itemClick", @_table, arg))
		@on("itemDoubleClick", (self, arg)=> @_table.fire("itemDoubleClick", @_table, arg))
		@on("itemPress", (self, arg)=> @_table.fire("itemPress", @_table, arg))

	_createItemsScope: ()-> @_itemsScope

	_getItemScope: (parentScope, alias, item)->
		return @_table._getItemScope(parentScope, alias, item)

	_getItems: ()-> @_table._getItems()

	_createDom: ()->
		@_doms ?= {}
		dom = $.xCreate({
			tagName: "div"
			class: @_type
			content:
				class: "table-body"
				contextKey: "tableBody"
				content:
					tagName: "ul"
					contextKey: "itemsWrapper"
				mousewheel: (evt)=>
					evt = evt.originalEvent

					table = @_table
					centerTableDom = table._centerTable._dom
					scrollLeft = centerTableDom.scrollLeft + evt.deltaX

					centerTableBody = table._centerTable._doms.tableBody
					scrollTop = centerTableBody.scrollTop + evt.deltaY

					oldScrollLeft = centerTableDom.scrollLeft
					oldScrollTop = centerTableBody.scrollTop
					centerTableDom.scrollLeft = scrollLeft
					centerTableBody.scrollTop = scrollTop

					if centerTableDom.scrollLeft is oldScrollLeft and centerTableBody.scrollTop is oldScrollTop
						return true

					table._leftTable?._doms.tableBody.scrollTop = scrollTop
					table._rightTable?._doms.tableBody.scrollTop = scrollTop

					table._ignoreScrollbarMove = true
					if table._horiScrollBar
						table._horiScrollBar.scrollLeft = scrollLeft / centerTableDom.scrollWidth * table._horiScrollBar.scrollWidth
					if table._vertScrollBar
						table._vertScrollBar.scrollTop = scrollTop / centerTableBody.scrollHeight * table._vertScrollBar.scrollHeight
					table._ignoreScrollbarMove = false
					return false
		}, @_doms)

		$fly(@_doms.itemsWrapper).delegate(".cell", "click", (evt)=>
			return if @_readOnly

			cell = evt.currentTarget
			columnName = cell._name
			column = @_table.getColumn(columnName)
			item = @getItemByItemDom(cell.parentNode)
			@setCurrentCell(item, column)
			return
		)
		return dom

	_createNewItem: (itemType, item)->
		template = @_table.getTemplate(itemType + "-row")
		itemDom = @_table._cloneTemplate(template)
		$fly(itemDom).addClass("table item " + itemType)
		itemDom._itemType = itemType
		return itemDom

	_doRefreshItems: (itemsWrapper)->
		return unless @_dom and @_columnsInfo

		@hideCellEditor()

		if @_table._showHeader
			header = @_doms.header
			if not header
				$fly(@_doms.tableBody).xInsertBefore({
					class: "table-header"
					contextKey: "tableHeader"
					content:
						contextKey: "header"
					scroll: (evt)=>
						return unless @_table._innerDragging
						@_doms.tableBody?.scrollLeft = evt.target.scrollLeft
						return
				}, @_doms)
				header = @_doms.header

				$fly(header).delegate(".header-cell", "click", (evt)=>
					columnName = evt.currentTarget._name
					column = @_table.getColumn(columnName)
					eventArg =
						column: column
					if column.fire("headerClick", @, eventArg) isnt false
						if @_table.fire("headerClick", @, eventArg) isnt false
							@_table._sysHeaderClick(column)
					return
				)

			@_refreshHeader(header)
			@_doms.tableBody.className = "table-body header-" + @_columnsInfo.rows

		if @_table._showFooter
			footer = @_doms.footer
			if not footer
				$fly(@_doms.tableBody).xInsertAfter({
					class: "table-footer"
					contextKey: "tableFooter"
					content:
						contextKey: "footer"
				}, @_doms)

				footer = @_doms.footer
				$fly(footer).delegate(".footer-cell", "click", (evt)=>
					columnName = evt.currentTarget._name
					column = @_table.getColumn(columnName)
					eventArg =
						column: column
					if column.fire("footerClick", @, eventArg) isnt false
						@fire("footerClick", @, eventArg)
					return
				)
			@_refreshFooter(footer)
			@_doms.tableBody.style.paddingBottom = @_doms.tableFooter.offsetHeight + "px"

		super(itemsWrapper)

		if @_type is "center"
			@_table._realItems = @_realItems
			@_table._realOriginItems = @_realOriginItems
		return

	_refreshHeaderRow: (rowDom, colInfos, rowHeight)->
		for colInfo in colInfos
			column = colInfo.column
			cell = cola.xCreate(
				class: "header-cell " + column._id + " h-center"
				content:
					class: "content"
			)
			cell._name = column._name

			if column instanceof cola.TableGroupColumn
				cell.className += " rows-1"
				subRowDom = cola.xCreate(
					class: "header-row"
				)
				groupColumnCell = cola.xCreate(
					class: "header-group"
					content: [ cell, subRowDom ]
				)
				@_refreshHeaderRow(subRowDom, colInfo.colInfos, rowHeight - 1)
				rowDom.appendChild(groupColumnCell)
			else
				cell.className += " rows-" + rowHeight
				rowDom.appendChild(cell)

			@_refreshHeaderCell(cell.firstElementChild, colInfo)
		return

	_refreshHeader: (header)->
		return if @_headerTimestamp is @_columnsInfo.timestamp
		@_headerTimestamp = @_columnsInfo.timestamp

		$fly(header).empty()

		rowDom = $.xCreate(
			class: "header-row first-row"
		)
		@_refreshHeaderRow(rowDom, @_columnsInfo.colInfos, @_columnsInfo.rows)
		cola.xRender(rowDom, @_scope)
		header.appendChild(rowDom)
		return

	_refreshHeaderCell: (dom, columnInfo)->
		column = columnInfo.column

		$cell = $fly(dom.parentNode)
		$cell.toggleClass("sortable", !!column._sortable).removeClass("asc desc")
		if column._sortDirection then $cell.addClass(column._sortDirection)

		if column.renderHeader
			if column.renderHeader(dom) != true
				return

		if column.getListeners("renderHeader")
			if column.fire("renderHeader", column, { dom: dom }) == false
				return

		if @getListeners("renderHeaderCell")
			if @fire("renderHeaderCell", @, { column: column, dom: dom }) == false
				return

		template = column.getTemplate("headerTemplate")
		if template
			template = @_cloneTemplate(template)
			dom.appendChild(template)
		return if column._real_headerTemplate

		caption = column._caption or column._name
		if caption?.charCodeAt(0) is 95 # `_`
			caption = column._property or column._bind
		dom.innerText = caption or ""
		return

	_refreshFooter: (footer)->

	_doRefreshItemDom: (itemDom, item, itemScope)->
		itemType = itemDom._itemType

		if @_table.getListeners("renderItem")
			if @_table.fire("renderItem", @_table, { item: item, dom: itemDom, scope: itemScope }) == false
				return

		if itemType == "default"
			colInfos = @_columnsInfo.dataColumns
			for colInfo, i in colInfos
				column = colInfo.column
				cell = itemDom.childNodes[i]
				while cell and cell._name != column._name
					itemDom.removeChild(cell)
					cell = itemDom.childNodes[i]

				if not cell
					isNew = true
					cell = $.xCreate({
						tagName: "div"
						content:
							class: "content"
					})
					cell._name = column._name
					itemDom.appendChild(cell)

				exClass = ""
				if column._align
					exClass = " h-" + column._align
				if column._valign
					exClass += " v-" + column._valign

				cell.className = "cell " + column._id + (exClass or "")
				contentWrapper = cell.firstElementChild

				@_refreshCell(contentWrapper, item, colInfo, itemScope, isNew)

			while itemDom.lastChild and itemDom.lastChild != cell
				itemDom.removeChild(itemDom.lastChild)
		return

	_refreshCell: (dom, item, columnInfo, itemScope, isNew)->
		column = columnInfo.column

		if column.renderCell
			if column.renderCell(dom, item, itemScope) != true
				return

		if column.getListeners("renderCell")
			if column.fire("renderCell", column, { item: item, dom: dom, scope: itemScope }) == false
				return

		if @_table.getListeners("renderCell")
			if @_table.fire("renderCell", @_table,
			  { item: item, column: column, dom: dom, scope: itemScope }) == false
				return

		if isNew
			template = column.getTemplate("template")
			if template
				template = @_cloneTemplate(template)
				dom.appendChild(template)
				if column._property
					if column._format
						context = {
							defaultPath: "format(#{@_alias}.#{column._property},#{column._format})"
						}
					else
						context = {
							defaultPath: "#{@_alias}.#{column._property}"
						}
				cola.xRender(dom, itemScope, context)

		if item instanceof cola.Entity and column._property
			$cell = $fly(dom.parentNode)
			i = column._property.lastIndexOf(".")
			if i > 0
				subItem = item.get(column._property.substring(0, i))
				if subItem and subItem instanceof cola.Entity
					message = subItem.getKeyMessage(column._property.substring(i + 1))
			else
				message = item.getKeyMessage(column._property)

			if message
				if typeof message is "string"
					message =
						type: "error"
						text: message

				$cell.removeClass("info warn error").addClass(message.type)

				$cell.attr("data-content", message.text)
				if not dom._popupSetted
					$cell.popup({
						position: "bottom center"
					})
					dom._popupSetted = true
				dom._hasState = true
			else if dom._hasState
				$cell.removeClass("info warn error")
				if dom._popupSetted
					$cell.attr("data-content", "").popup("destroy")
				dom._hasState = false
				dom._popupSetted = false

		return if column._real_template

		$dom = $fly(dom).addClass("default-content")
		if columnInfo.expression
			$dom.attr("c-bind", columnInfo.expression.raw)
		else if column._property
			if item instanceof cola.Entity
				value = item.get(column._property)
			else
				value = item[column._property]

			if column._format
				value = cola.defaultAction.format(value, column._format)
			else
				if value instanceof Date
					defaultDateFormat = cola.setting("defaultDateFormat")
					if defaultDateFormat
						value = cola.defaultAction.formatDate(value, defaultDateFormat)
			value = "" if value is undefined or value is null
			$dom.text(value)
		return

	refreshItem: (item)->
		itemId = _getEntityId(item)
		itemDom = @_itemDomMap[itemId]
		if itemDom
			@_refreshItemDom(itemDom, item, @_itemsScope)
		return

	_getCurrentItem: ()->
		if @_currentItemDom
			return cola.util.userData(@_currentItemDom, "item")
		else
			return null

	setCurrentCell: (item, column)->
		@_table._currentInnerTable = @
		@_table._currentColumn = column
		if @_table._currentCell
			$fly(@_table._currentCell).removeClass("current")

		if item
			itemId = _getEntityId(item)
			itemDom = @_itemDomMap[itemId]
			if itemDom
				child = itemDom.firstElementChild
				while child
					if child._name is column._name
						cell = child
						break
					child = child.nextElementSibling

			@_table._currentCell = cell
			if cell
				$fly(cell).addClass("current")
				if column._property
					@showCellEditor(cell, item, column)
		return

	_getCellEditorPane: (create)->
		if not @_cellEditorPane and create
			@_cellEditorPane = cola.xCreate(
				class: "cell-editor-pane protected"
			)
			@_doms.itemsWrapper.appendChild(@_cellEditorPane)
		return @_cellEditorPane

	_resize: (editorPane, cell)->
		itemDom = cell.parentNode
		$fly(editorPane)
			.css("left", cell.offsetLeft)
			.css("top", itemDom.offsetTop)
			.width(cell.clientWidth)
			.height(cell.clientHeight)
		return

	showCellEditor: (cell, item, column)->
		if @_table._readOnly or column._readOnly
			return

		if not column._editTemplate
			propertyType = column._propertyDef?._dataType
			if propertyType instanceof cola.BooleanDataType
				template = "checkbox"
			else if propertyType instanceof cola.DateDataType
				template = "date-picker"
			else
				template = "input"
		template = column.getTemplate("editTemplate", template)

		if template
			editorPane = @_getCellEditorPane(true)
			$fly(editorPane).addClass("hidden")

			setTimeout(()=>
				templateDom = column._editTemplateDom
				if not templateDom
					scope = new cola.ItemScope(@_scope, @_table._alias)
					scope.data.setItemData(item, true)

					oldScope = cola.currentScope
					try
						cola.currentScope = scope
						column._editTemplateDom = templateDom = @_cloneTemplate(template)
						cola.util.userData(templateDom, "scope", scope)
						context = {
							defaultPath: "#{@_table._alias}.#{column._property}"
						}
						cola.xRender(templateDom, scope, context)

						if templateDom
							editor = cola.widget(templateDom)
							if editor instanceof cola.AbstractEditor and not editor._bindInfo
								editor.set("bind", "#{@_table._alias}.#{column._property}")
					finally
						cola.currentScope = oldScope
				else
					scope = cola.util.userData(templateDom, "scope")
					scope?.data.setItemData(item)

				$fly(editorPane).removeClass("hidden")

				cellWidget = cola.widget(cell.firstElementChild?.firstElementChild)
				if cellWidget instanceof cola.AbstractEditor
					cellWidget.focus()
				else
					if templateDom.parentNode isnt editorPane
						if editorPane.firstElementChild
							cola.util.cacheDom(editorPane.firstElementChild)
						editorPane.appendChild(templateDom)

					@_resize(editorPane, cell)

					if templateDom?.className is "editor-container"
						editContent = templateDom.firstElementChild
					else
						editContent = templateDom
					cellEditorWidget = cola.widget(editContent)
					cellEditorWidget?.focus()
				return
			, 0)
		return

	hideCellEditor: ()->
		editorPane = @_getCellEditorPane()
		if editorPane
			$fly(editorPane).addClass("hidden")
		return

	_onKeyDown: (evt)->