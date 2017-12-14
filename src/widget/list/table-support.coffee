cola.registerTypeResolver "table.column", (config)->
	return unless config and config.$type
	type = config.$type.toLowerCase()
	if type == "select" then return cola.TableSelectColumn
	else if type == "state" then return cola.TableStateColumn
	return

cola.registerTypeResolver "table.column", (config)->
	if config.columns?.length then return cola.TableGroupColumn
	return cola.TableDataColumn

class cola.TableColumn extends cola.Element
	@attributes:
		name:
			readOnlyAfterCreate: true
		caption: null
		align:
			enum: [ "left", "center", "right" ]
		visible:
			type: "boolean"
			defaultValue: true
			refreshStructure: true
		headerTemplate: null

	@events:
		renderHeader: null
		headerClick: null

	constructor: (config)->
		super(config)
		if not @_name then @_name = cola.uniqueId()

		@on("attributeChange", (self, arg)=>
			return unless @_table
			attrConfig = @constructor.attributes[arg.attribute]
			return unless attrConfig
			if attrConfig.refreshStructure
				@_table._collectionColumnsInfo()

			return
		)

	_setTable: (table)->
		@_table._unregColumn(@) if @_table
		@_table = table
		table._regColumn(@) if table
		return

	getTemplate: (property)->
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
			defaultValue: 80
		valign:
			enum: [ "top", "center", "bottom" ]
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
		itemChange: null
	@attributes:
		width:
			defaultValue: "42px"
		align:
			defaultValue: "center"

	renderHeader: (dom, item)->
		if not dom.firstElementChild
			@_headerCheckbox = checkbox = new cola.Checkbox(
				class: "in-cell"
				triState: true
				click: (self)=>
					checked = self.get("checked")
					@selectAll(checked)
					@fire("change", @, { checkbox: self, oldValue: not checked, value: checked })
					return
			)
			checkbox.appendTo(dom)
		return

	renderCell: (dom, item)->
		if not dom.firstElementChild
			checkbox = new cola.Checkbox(
				class: "in-cell"
				bind: @_table._alias + "." + @_table._selectedProperty
				click: (self, arg)=>
					if !@_ignoreCheckedChange
						@refreshHeaderCheckbox()
					arg.item = item
					@fire("itemChange", @, arg)
					return
			)
			oldRefreshValue = checkbox.refreshValue
			checkbox.refreshValue = ()=>
				oldValue = checkbox._value
				result = oldRefreshValue.call(checkbox)
				if checkbox._value != oldValue
					arg =
						model: checkbox.get("model")
						dom: checkbox._dom
						item: item
					@fire("itemChange", @, arg)
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

	selectAll: (selected)->
		table = @_table
		selectedProperty = table._selectedProperty
		if table._realItems
			@_ignoreCheckedChange = true
			cola.each(@_table._realItems, (item)->
				itemType = table._getItemType(item)
				if itemType == "default"
					if item instanceof cola.Entity
						item.set(selectedProperty, selected)
					else
						item[selectedProperty]
						table.refreshItem(item)
				return
			, { currentPage: true })

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