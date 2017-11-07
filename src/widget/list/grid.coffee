class cola.Grid extends cola.Widget
	@tagName: "c-grid"
	@CLASS_NAME: "items-view widget-grid h-box"

	@attributes:
		items:
			refreshItems: true
			setter: (items) ->
				return if @_items is items
				@_set("bind", undefined)
				@_items = items
				return
		bind:
			setter: (bindStr) ->
				return if @_bindStr is bindStr
				@_set("items", undefined)
				@_bindSetter(bindStr)
				return

		columns:
			setter: (columnConfigs) ->
				if @_columns
					for column in @_columns
						column._setTable(null)

				columns = []
				if columnConfigs
					for columnConfig in columnConfigs
						continue unless columnConfig
						if columnConfig instanceof cola.TableColumn
							column = columnConfig
						else
							column = cola.create("table.column", columnConfig, cola.TableColumn)
						column._setTable(@)
						columns.push(column)
				@_columns = columns
				@_collectionColumnsInfo()
				return
		dataType:
			setter: cola.DataType.dataTypeSetter

		showHeader:
			type: "boolean"
			defaultValue: true
		showFooter:
			type: "boolean"

		columnStretchable:
			type: "boolean"
			defaultValue: true
		selectedProperty:
			defaultValue: "selected"

		sortMode:
			defaultValue: "remote" # local/remote

		leftFixedCols:
			defaultValue: 0
			setter: (value) ->
				@_leftFixedCols = value
				@_collectionColumnsInfo()
				return

		rightFixedCols:
			defaultValue: 0
			setter: (value) ->
				@_rightFixedCols = value
				@_collectionColumnsInfo()
				return

	@events:
		renderRow: null
		renderCell: null
		renderHeaderCell: null
		renderFooterCell: null
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
		"date-column":
			tagName: "c-datepicker"
			bind: "$default"

	constructor: (config) ->
		@_columnMap = {}
		super(config)

	_getItems: () ->
		if @_items
			return {items: @_items}
		else
			return super()

	_regColumn: (column) ->
		if column._name
			@_columnMap[column._name] = column
		return

	_unregColumn: (column) ->
		if column._name
			delete @_columnMap[column._name]
		return

	getColumn: (name) ->
		return @_columnMap[name]

	_collectionColumnsInfo: () ->

		collectColumnInfo = (column, context, deepth, rootIndex) ->
			info =
				level: deepth
				column: column
			if column instanceof cola.TableGroupColumn
				if column._columns
					info.columns = cols = []
					for col in column._columns
						continue unless col._visible
						if context.rows.length == deepth
							context.rows[deepth] = []
						cols.push(collectColumnInfo(col, context, deepth + 1, rootIndex))
					if cols.length
						if context.rows.length == deepth then context.rows[deepth] = []
						context.rows[deepth].push(info)
			else
				if column._bind
					bind = column._bind
					if bind.charCodeAt(0) == 46 # `.`
						if not column._property
							column._property = bind.substring(1)
					else
						info.expression = cola._compileExpression(@_scope, bind)

				if column._width
					width = column._width
					if typeof width == "string"
						if width.indexOf("px") > 0
							widthType = "px"
						else if width.indexOf("%") > 0
							widthType = "percent"
					info.widthType = widthType
					info.width = parseFloat(width)

					if not widthType and info.width
						context.totalWidth += info.width

				info.index = context.dataColumns.length
				info.rootIndex = rootIndex
				context.dataColumns.push(info)

				if column instanceof cola.TableSelectColumn
					context.selectColumns ?= []
					context.selectColumns.push(info)

				if context.rows.length == deepth then context.rows[deepth] = []
				context.rows[deepth].push(info)
			return info

		@_columnsInfo = columnsInfo = {
			timestamp: cola.sequenceNo()
			totalWidth: 0
			rows: [[]]
			dataColumns: []
			alias: "item"
		}
		if @_columns
			expression = @_itemsScope.expression
			if expression
				columnsInfo.alias = expression.alias

			for col, i in @_columns
				continue unless col._visible
				collectColumnInfo(col, columnsInfo, 0, i)

			if @_leftFixedCols > 0 or @_rightFixedCols > 0
				overflow = @_leftFixedCols + @_rightFixedCols - @_columns.length
				if overflow >= 0
					if @_rightFixedCols > overflow
						@_rightFixedCols -= (overflow + 1)
						overflow = -1
					else
						@_rightFixedCols = 0
						overflow -= @_rightFixedCols

					if overflow >= 0
						@_leftFixedCols -= (overflow + 1)

			if @_leftFixedCols < 0 then @_leftFixedCols = 0
			if @_rightFixedCols < 0 then @_rightFixedCols = 0

			if @_leftFixedCols > 0 or @_rightFixedCols > 0
				if @_leftFixedCols > 0
					columnsInfo.left =
						start: 0
						rows: columnsInfo.rows
						columns: @_columns.slice(0, @_leftFixedCols)
						dataColumns: []
				else
					delete columnsInfo.left

				if @_rightFixedCols > 0
					columnsInfo.right =
						start: @_columns.length - @_rightFixedCols
						rows: columnsInfo.rows
						columns: @_columns.slice(@_columns.length - @_rightFixedCols, @_rightFixedCols)
						dataColumns: []
				else
					delete columnsInfo.right

				columnsInfo.center =
					start: @_leftFixedCols
					rows: columnsInfo.rows
					columns: @_columns.slice(@_leftFixedCols, @_columns.length - @_leftFixedCols - @_rightFixedCols)
					dataColumns: []

				for col in columnsInfo.dataColumns
					if col < @_leftFixedCols
						columnsInfo.left.dataColumns.push(col)
					else if col >= @_columns.length - @_rightFixedCols
						columnsInfo.right.dataColumns.push(col)
					else
						columnsInfo.center.dataColumns.push(col)
			else
				delete columnsInfo.left
				delete columnsInfo.right
				columnsInfo.center =
					start: 0
					rows: columnsInfo.rows
					columns: @_columns
					dataColumns: columnsInfo.dataColumns
		return

	_createDom: ()->
		dom = document.createElement("div")
		@_doms ?= {}
		@_createInnerDom(dom)
		return dom

	_createInnerDom: (dom) ->
		@_centerTable = new cola.Table.InnerTable(
			table: @
			class: "flex-box"
		)
		@_centerTable.appendTo(dom)
		return

	_initDom: (dom) ->
		@_regDefaultTemplates()
		@_templateContext ?= {}
		return

	_parseDom: (dom) ->
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

	_parseColumnDom: (dom) ->
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
				else
					templateName = "template"
				column[templateName] = @trimTemplate(child)
			else if child.nodeType is 1
				subColumn = @_parseColumnDom(child)
				column.columns ?= []
				column.columns.push(subColumn)
			child = next
		return column

	_doSet: (attr, attrConfig, value) ->
		if attrConfig?.refreshItems
			attrConfig.refreshDom = true
			@_refreshItemsScheduled = true
		return super(attr, attrConfig, value)

	buildStyleSheet: () ->
		return

	_doRefreshDom: (dom)->
		if @_columnsTimestamp isnt @_columnsInfo.timestamp
			@_columnsTimestamp = @_columnsInfo.timestamp

			if @_columnsInfo.left and not @_leftTable
				@_leftTable = new cola.Table.InnerTable(
					table: @
					class: "box"
				)
				@_centerTable.get$Dom().before(@_leftTable.getDom())
			if @_columnsInfo.right and not @_leftTable
				@_rightTable = new cola.Table.InnerTablee(
					table: @
					class: "box"
				)
				@_centerTable.get$Dom().after(@_rightTable.getDom())

			@_leftTable?.set("columnsInfo", @_columnsInfo.left)
			@_rightTable?.set("columnsInfo", @_columnsInfo.right)
			@_centerTable.set("columnsInfo", @_columnsInfo.center)

		super(dom)

		if @_refreshItemsScheduled
			delete @_refreshItemsScheduled
			@_refreshItems()
		return

	_onItemsRefresh: () ->
		return @_refreshItems()

	_refreshItems: () ->
		@_leftTable?._refreshItems()
		@_rightTable?._refreshItems()
		@_centerTable._refreshItems()
		return

cola.Element.mixin(cola.Grid, cola.TemplateSupport)
cola.Element.mixin(cola.Grid, cola.DataItemsWidgetMixin)

class cola.Table.InnerTable extends cola.AbstractList
	@CLASS_NAME: "inner-table"

	@attributes:
		table: null
		columnsInfo: null

	_getItems: () -> @_table._getItems()

	_createNewItem: (itemType, item) ->
		template = @_table.getTemplate(itemType + "-row")
		itemDom = @_table._cloneTemplate(template)
		$fly(itemDom).addClass("table item " + itemType)
		itemDom._itemType = itemType
		return itemDom

	_doRefreshItemDom: (itemDom, item, itemScope) ->
		itemType = itemDom._itemType

		if @getListeners("renderRow")
			if @fire("renderRow", @, {item: item, dom: itemDom, scope: itemScope}) == false
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
							tagName: "div"
					})
					cell._name = column._name
					itemDom.appendChild(cell)
				cell.className = "cell col-" + (colInfo.index + 1)
				contentWrapper = cell.firstElementChild

				@_refreshCell(contentWrapper, item, colInfo, itemScope, isNew)

			while itemDom.lastChild and itemDom.lastChild != cell
				itemDom.removeChild(itemDom.lastChild)
		return

	_refreshCell: (dom, item, columnInfo, itemScope, isNew) ->
		column = columnInfo.column
		dom.style.textAlign = column._align or ""

		if column.renderCell
			if column.renderCell(dom, item, itemScope) != true
				return

		if column.getListeners("renderCell")
			if column.fire("renderCell", column, {item: item, dom: dom, scope: itemScope}) == false
				return

		if @getListeners("renderCell")
			if @fire("renderCell", @,
			  {item: item, column: column, dom: dom, scope: itemScope}) == false
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
			message = item.getKeyMessage(column._property)
			if message
				if typeof message is "string"
					message =
						type: "error"
						text: message
				$cell.removeClass("info warn error").addClass(message.type)
				$cell.attr("data-content", message.text).popup({
					position: "bottom center"
				})
			else
				$cell.removeClass("info warn error").attr("data-content", "").popup("destroy")

		return if column._real_template

		$dom = $fly(dom).addClass("default-content")
		if columnInfo.expression
			$dom.attr("c-bind", columnInfo.expression.raw)
		else if column._property
			value = item.get(column._property)
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