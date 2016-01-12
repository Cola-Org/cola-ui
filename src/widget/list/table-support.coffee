cola.registerTypeResolver "table.column", (config) ->
	return unless config and config.$type
	type = config.$type.toLowerCase()
	if type == "select" then return SelectColumn
	return

cola.registerTypeResolver "table.column", (config) ->
	if config.columns?.length then return cola.TableGroupColumn
	return cola.TableDataColumn

class cola.TableColumn extends cola.Element
	@ATTRIBUTES:
		name:
			reaonlyAfterCreate: true
		caption: null
		visible:
			type:"boolean"
			defaultValue: true
		headerTemplate: null

	@EVENTS:
		renderHeader: null

	constructor: (config) ->
		super(config)
		if !@_name then @_name = cola.uniqueId()

	_setTable: (table) ->
		@_table._unregColumn(@) if @_table
		@_table = table
		table._regColumn(@) if table
		return

class cola.TableGroupColumn extends cola.TableColumn
	@ATTRIBUTES:
		columns:
			setter: (columnConfigs) ->
				_columnsSetter.call(@, @_table, columnConfigs)
				return

	_setTable: (table) ->
		super(table)
		if @_columns
			for column in @_columns
				column._setTable(table)
		return

class cola.TableContentColumn extends cola.TableColumn
	@ATTRIBUTES:
		width:
			defaultValue: 80
		align:
			enum: ["left", "center", "right"]
		valign:
			enum: ["top", "center", "bottom"]
		footerTemplate: null

	@EVENTS:
		renderCell: null
		renderFooter: null

class cola.TableDataColumn extends cola.TableContentColumn
	@ATTRIBUTES:
		dataType:
			readOnlyAfterCreate: true
			setter: cola.DataType.dataTypeSetter
		bind: null
		template: null

class cola.TableSelectColumn extends cola.TableContentColumn
	@ATTRIBUTES:
		width:
			defaultValue: "34px"
		align:
			defaultValue: "center"

	renderHeader: (dom, item) ->
		if !dom.firstChild
			@_headerCheckbox = checkbox = new cola.Checkbox(
				class: "in-cell"
				triState: true
				click: (self) =>
					@selectAll(self.get("checked"))
					return
			)
			checkbox.appendTo(dom)
		return

	renderCell: (dom, item) ->
		if !dom.firstChild
			checkbox = new cola.Checkbox(
				class: "in-cell"
				bind: @_table._alias + "." + @_table._selectedProperty
				change: () =>
					if !@_ignoreCheckedChange
						@refreshHeaderCheckbox()
					return
			)
			checkbox.appendTo(dom)
		return

	refreshHeaderCheckbox: () ->
		return unless @_headerCheckbox
		cola.util.delay(@, "refreshHeaderCheckbox", 50, () ->
			table =  @_table
			selectedProperty = table._selectedProperty
			if table._realItems
				i = 0
				selected = undefined
				cola.each @_table._realItems, (item) ->
					itemType = table._getItemType(item)
					if itemType == "default"
						i++
						if item instanceof cola.Entity
							s = item.get(selectedProperty)
						else
							s = item[selectedProperty]

						if i == 1
							selected = s
						else if selected != s
							selected = undefined
							return false
					return

				@_headerCheckbox.set("value", selected)
			return
		)
		return

	selectAll: (selected) ->
		table =  @_table
		selectedProperty = table._selectedProperty
		if table._realItems
			@_ignoreCheckedChange = true
			cola.each @_table._realItems, (item) ->
				itemType = table._getItemType(item)
				if itemType == "default"
					if item instanceof cola.Entity
						item.set(selectedProperty, selected)
					else
						item[selectedProperty]
						table.refreshItem(item)
				return

			setTimeout(() =>
				@_ignoreCheckedChange = false
				return
			, 100)
		return

_columnsSetter = (table, columnConfigs) ->
	if table?._columns
		for column in table._columns
			column._setTable(null)

	columns = []
	if columnConfigs
		for columnConfig in columnConfigs
			continue unless columnConfig
			if columnConfig instanceof cola.TableColumn
				column = columnConfig
			else
				column = cola.create("table.column", columnConfig, cola.TableColumn)
			column._setTable(table)
			columns.push(column)
	@_columns = columns
	return

class cola.AbstractTable extends cola.ItemsView
	@ATTRIBUTES:
		items:
			refreshItems: true
			setter: (items) ->
				return if @_items == items
				@_set("bind", undefined)
				@_items = items
				return
		bind:
			setter: (bindStr) ->
				@_set("items", undefined)
				@_bindSetter(bindStr)
				return

		columns:
			setter: (columnConfigs) ->
				_columnsSetter.call(@, @, columnConfigs)
				@_collectionColumnsInfo()
				return
		dataType:
			setter: cola.DataType.dataTypeSetter

		showHeader:
			type:"boolean"
			defaultValue: true
		showFooter:
			type:"boolean"

		columnStrecthable:
			type:"boolean"
			defaultValue: true
		selectedProperty:
			defaultValue: "selected"

	@EVENTS:
		renderRow: null
		renderCell: null
		renderHeader: null
		renderFooter: null

	@TEMPLATES:
		"default":
			tagName: "tr"
		"checkbox-column":
			tagName: "div"
			"c-widget": "checkbox;class:in-cell;bind:$default"
		"input-column":
			tagName: "div"
			"c-widget": "input;class:in-cell;bind:$default"
			style:
				width: "100%"
		"group-header":
			tagName: "tr"
			content:
				tagName: "td"
				colSpan: 100

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
						convertorIndex = bind.indexOf("|")
						if convertorIndex < 0
							info.property = bind.substring(1)
						else
							info.property = bind.substring(1, convertorIndex)
							info.expression = cola._compileExpression(context.alias + bind)
					else
						info.expression = cola._compileExpression(bind)
						path = info.expression?.path
						if path instanceof Array then path = path[0]
						if path and path.indexOf("*") < 0
							info.property = path

				if column._width
					width = column._width
					if typeof width == "string"
						if width.indexOf("px") > 0
							widthType = "px"
						else if width.indexOf("%") > 0
							widthType = "percent"
					info.widthType = widthType
					info.width = parseInt(width, 10)

					if !widthType and info.width
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
		return

	_getBindDataType: () ->
		return @_dataType if @_dataType

		items = @_getItems().originItems
		if items
			if items instanceof cola.EntityList
				dataType = items.dataType
			else if items instanceof Array and items.length
				item = items[0]
				if item and item instanceof cola.Entity
					dataType = item.dataType
		return @_dataType = dataType

	_createDom: ()->
		dom = document.createElement("div")
		@_doms ?= {}
		@_createInnerDom(dom)
		return dom

	_createInnerDom: (dom) ->
		$fly(dom).xAppend({
			tagName: "div"
			class: "table-wrapper"
			contextKey: "itemsWrapper"
			content:
				tagName: "table"
				contextKey: "table"
				content: [
					{
						tagName: "colgroup"
						contextKey: "colgroup"
						span: 100
					},
					{
						tagName: "tbody"
						class: "items"
						contextKey: "tbody"
					}
				]
		}, @_doms)
		return

	_parseDom: (dom)->
		return unless dom
		@_doms ?= {}
		child = dom.firstChild
		while child
			next = child.nextSibling
			nodeName = child.nodeName.toLowerCase()
			if nodeName == "template"
				@_regTemplate(child)
			else
				dom.removeChild(child)
			child = next
		@_createInnerDom(dom)
		return

	_createNewItem: (itemType, item) ->
		template = @_getTemplate(itemType)
		itemDom = @_cloneTemplate(template)
		$fly(itemDom).addClass("table item " + itemType)
		itemDom._itemType = itemType
		return itemDom