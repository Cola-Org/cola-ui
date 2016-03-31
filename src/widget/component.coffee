_extendsWidget = (superCls, definition) ->
	cls = () ->
		cls.__super__.constructor.apply(this, arguments)
		definition.constructor?.apply(this, arguments)

	`__extends(cls, superCls)`

	for prop, def of definition
		if definition.hasOwnProperty(prop)
			if prop is "ATTRIBUTES"
				for attr, attrDef of def
					cls.ATTRIBUTES[attr] = attrDef
			else if prop is "EVENTS"
				for evt, evtDef of def
					cls.EVENTS[evt] = evtDef
			else
				cls::[prop] = def

	return cls

cola.component = (name, type, definition) ->
	if not cola.util.isSuperClass(cola.widget, type)
		definition = type
		type = cola.TemplateWidget
	if definition
		type = _extendsWidget(type, definition)
	cola.component.tagNames[name] = type
	return type

cola.component.tagNames = {}


