class cola.Grid extends cola.RenderableElement
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
		collectColumnInfo = (column, context, deepth) ->
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
						cols.push(collectColumnInfo(col, context, deepth + 1))
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

			for col in @_columns
				continue unless col._visible
				collectColumnInfo(col, columnsInfo, 0)

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

		columnsInfo.leftColumns = @_columns.slice(0, @_leftFixedCols)
		columnsInfo.rightColumns = @_columns.slice(@_columns.length - @_rightFixedCols, @_rightFixedCols)
		columnsInfo.centerColumns = @_columns.slice(@_leftFixedCols, @_columns.length - @_leftFixedCols - @_rightFixedCols)
		return

	_createDom: ()->
		dom = document.createElement("div")
		@_doms ?= {}
		@_createInnerDom(dom)
		return dom

	_createInnerDom: (dom) ->
		@_centerTable = new cola.Table.InnerTable(table: @)
		@_centerTable.appendTo(dom)
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

	_doRefreshDom: (dom) ->
		super(dom)

		if @_columnsTimestamp isnt @_columnsInfo.timestamp
			@_columnsTimestamp = @_columnsInfo.timestamp

			if @_columnsInfo.leftColumns.length and not @_leftTable
				@_leftTable = new cola.Table.InnerTable(table: @ )
				@_centerTable.get$Dom().before(@_leftTable.getDom())
			if @_columnsInfo.rightColumns.length and not @_leftTable
				@_rightTable = new cola.Table.InnerTable(table: @ )
				@_centerTable.get$Dom().after(@_rightTable.getDom())

			@_leftTable?.set("columns", @_columnsInfo.leftColumns)
			@_rightTable?.set("columns", @_columnsInfo.rightColumns)
			@_centerTable.set("columns", @_columnsInfo.centerColumns)
		return

	_createNewItem: (itemType, item) ->
		template = @getTemplate(itemType)
		itemDom = @_cloneTemplate(template)
		$fly(itemDom).addClass("table item " + itemType)
		itemDom._itemType = itemType
		return itemDom

class cola.Table.InnerTable extends cola.AbstractList

	@attributes:
		table: null,
		columns: null