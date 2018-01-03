@cola = cola = ()-> cola._rootFunc?.apply(cola, arguments)

cola.util = {}

cola.constants = {
	VARIABLE_NAME_REGEXP: /^[_a-zA-Z][_a-zA-Z0-9]*$/g

	VIEW_CLASS: "c-view"
	VIEW_PORT_CLASS: "c-viewport"
	IGNORE_DIRECTIVE: "c-ignore"

	SHOW_ON_READY_CLASS: "show-on-ready"
	LAZY_CLASS: "lazy"
	LAZY_CONTENT_CLASS: "lazy-content"
	COLLECTION_CURRENT_CLASS: "current"

	DEFAULT_PATH: "$root"
	REPEAT_INDEX: "$index"

	DOM_USER_DATA_KEY: "_d"
	DOM_BINDING_KEY: "_binding"
	DOM_INITIALIZER_KEY: "_initialize"
	REPEAT_TEMPLATE_KEY: "_template"
	REPEAT_TAIL_KEY: "_tail"
	DOM_ELEMENT_KEY: "_element"
	DOM_SKIP_CHILDREN: "_skipChildren"

	NOT_WHITE_REG: /\S+/g
	CLASS_REG: /[\t\r\n\f]/g
	WIDGET_DIMENSION_UNIT: "px"

	MESSAGE_REFRESH: 0
	MESSAGE_PROPERTY_CHANGE: 1

	MESSAGE_CURRENT_CHANGE: 10
	MESSAGE_EDITING_STATE_CHANGE: 11
	MESSAGE_VALIDATION_STATE_CHANGE: 15

	MESSAGE_INSERT: 20
	MESSAGE_REMOVE: 21

	MESSAGE_LOADING_START: 30
	MESSAGE_LOADING_END: 31
}
