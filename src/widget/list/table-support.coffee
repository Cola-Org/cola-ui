cola.registerTypeResolver "table.column", (config) ->
	return unless config and config.$type
	type = config.$type.toLowerCase()
	if type == "select" then return cola.TableSelectColumn
	return

cola.registerTypeResolver "table.column", (config) ->
	if config.columns?.length then return cola.TableGroupColumn
	return cola.TableDataColumn

class cola.TableColumn extends cola.Element
	@attributes:
		name:
			reaonlyAfterCreate: true
		caption: null
		align:
			enum: ["left", "center", "right"]
		visible:
			type: "boolean"
			defaultValue: true
			refreshStructure: true
		headerTemplate: null

	@events:
		renderHeader: null
		headerClick: null

	constructor: (config) ->
		super(config)
		if !@_name then @_name = cola.uniqueId()

		@on("attributeChange", (self, arg) =>
			return unless @_table
			attrConfig = @constructor.attributes[arg.attribute]
			return unless attrConfig
			if attrConfig.refreshStructure
				@_table._collectionColumnsInfo()

			return
		)

	_setTable: (table) ->
		@_table._unregColumn(@) if @_table
		@_table = table
		table._regColumn(@) if table
		return

	getTemplate: (property) ->
		template = @["_real_" + property]
		return template if template isnt undefined

		templateDef = @get(property)
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

		@["_real_" + property] = template or null
		return template

class cola.TableGroupColumn extends cola.TableColumn
	@attributes:
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
	@attributes:
		width:
			defaultValue: 80
		valign:
			enum: ["top", "center", "bottom"]
		footerTemplate: null

	@events:
		renderCell: null
		renderFooter: null
		cellClick: null
		footerClick: null

class cola.TableDataColumn extends cola.TableContentColumn
	@attributes:
		dataType:
			readOnlyAfterCreate: true
			setter: cola.DataType.dataTypeSetter
		property: null
		bind: null
		template: null
		sortable: null
		sortDirection: null

class cola.TableSelectColumn extends cola.TableContentColumn
	@events:
		change: null
	@attributes:
		width:
			defaultValue: "42px"
		align:
			defaultValue: "center"

	renderHeader: (dom, item) ->
		if not dom.firstElementChild
			@_headerCheckbox = checkbox = new cola.Checkbox(
				class: "in-cell"
				triState: true
				change: (self, arg) =>
					if typeof arg.value != "boolean"
						@fire("change", this, {checkbox: self, oldValue: arg.oldValue, value: arg.value})
				click: (self) =>
					checked = self.get("checked")
					@selectAll(checked)
					@fire("change", this, {checkbox: self, oldValue: not checked, value: checked})
					return
			)
			checkbox.appendTo(dom)
		return

	renderCell: (dom, item) ->
		if not dom.firstElementChild
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
			table = @_table
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
		table = @_table
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

class cola.AbstractTable extends cola.AbstractList
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

		columnStrecthable:
			type: "boolean"
			defaultValue: true
		selectedProperty:
			defaultValue: "selected"

		sortMode:
			defaultValue: "remote" # local/remote

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
		"default":
			tagName: "tr"
		"boolean-column":
			"c-display": "$default"
			content:
				tagName: "i"
				class: "green checkmark icon"
		"checkbox-column":
			tagName: "c-checkbox"
			class: "in-cell"
			bind: "$default"
		"input-column":
			tagName: "c-input"
			class: "in-cell"
			bind: "$default"
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
		return @_dataType = super()

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

		$fly(@_doms.tbody).delegate(">tr >td", "click", (evt) =>
			columnName = evt.currentTarget._name
			column = @getColumn(columnName)
			eventArg =
				column: column
			if column.fire("cellClick", @, eventArg) isnt false
				@fire("cellClick", @, eventArg)
			return
		)
		return

	_parseDom: (dom) ->
		return unless dom
		@_doms ?= {}

		child = dom.firstElementChild
		while child
			cola.xRender(child)
			child.setAttribute(cola.constants.IGNORE_DIRECTIVE, true)
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
					if column then columns.push(column)
				else if nodeName is "SELECT-COLUMN"
					column = @_parseColumnDom(child)
					column.$type = "select"
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

	_createNewItem: (itemType, item) ->
		template = @getTemplate(itemType)
		itemDom = @_cloneTemplate(template)
		$fly(itemDom).addClass("table item " + itemType)
		itemDom._itemType = itemType
		return itemDom