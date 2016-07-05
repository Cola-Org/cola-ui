#IMPORT_BEGIN
if exports?
	cola = require("./util")
	module?.exports = cola
else
	cola = @cola
#IMPORT_END

_$ = $()
_$.length = 1
this.$fly = (dom) ->
	_$[0] = dom
	return _$

cola.util.setText = (dom, text = "") ->
	if cola.browser.mozilla
		if typeof text is "string"
			text = text.replace(/&/g, "&amp;").replace(/>/g, "&gt;").replace(/</g, "&lt;").replace(/\n/g, "<br>")
		dom.innerHTML = text
	else
		dom.innerText = text
	return

doms = {}
cola.util.cacheDom = (ele) ->
	cola._ignoreNodeRemoved = true
	if not doms.hiddenDiv
		doms.hiddenDiv = $.xCreate(
			tagName: "div"
			id: "_hidden_div"
			style:
				display: "none"
		)
		doms.hiddenDiv.setAttribute(cola.constants.IGNORE_DIRECTIVE, "")
		document.body.appendChild(doms.hiddenDiv)
	doms.hiddenDiv.appendChild(ele)
	cola._ignoreNodeRemoved = false
	return

USER_DATA_KEY = cola.constants.DOM_USER_DATA_KEY

cola.util.userDataStore = {}

cola.util.userData = (node, key, data) ->
	return if node.nodeType == 3
	userData = cola.util.userDataStore
	if node.nodeType == 8
		text = node.nodeValue
		i = text.indexOf("|")
		id = text.substring(i + 1) if i > -1
	else
		id = node.getAttribute(USER_DATA_KEY)

	if arguments.length == 3
		if !id
			id = cola.uniqueId()
			if node.nodeType == 8
				if i > -1
					node.nodeValue = text.substring(0, i + 1) + id
				else
					node.nodeValue = if text then text + "|" + id else "|" + id
			else
				node.setAttribute(USER_DATA_KEY, id)

			userData[id] = store = {}
		else
			store = userData[id]
			if !store then userData[id] = store = {}

		store[key] = data
	else if arguments.length == 2
		if typeof key == "string"
			if id
				store = userData[id]
				return store?[key]
		else if key and typeof key == "object"
			id = cola.uniqueId()
			if node.nodeType == 8
				if i > -1
					node.nodeValue = text.substring(0, i + 1) + id
				else
					node.nodeValue = if text then text + "|" + id else "|" + id
			else
				node.setAttribute(USER_DATA_KEY, id)

			userData[id] = key
	else if arguments.length == 1
		if id
			return userData[id]
	return

cola.util.removeUserData = (node, key) ->
	id = node.getAttribute(USER_DATA_KEY)
	if id
		store = cola.util.userDataStore[id]
		if store
			value = store[key]
			delete store[key]
	return value

ON_NODE_REMOVED_KEY = "__onNodeRemoved"

cola.detachNode = (node) ->
	return unless node.parentNode
	cola._ignoreNodeRemoved = true
	node.parentNode.removeChild(node)
	cola._ignoreNodeRemoved = false
	return

cola.util.onNodeDispose = (node, listener) ->
	oldListener = cola.util.userData(node, ON_NODE_REMOVED_KEY)
	if oldListener
		if oldListener instanceof Array
			oldListener.push(listener)
		else
			cola.util.userData(node, ON_NODE_REMOVED_KEY, [oldListener, listener])
	else
		cola.util.userData(node, ON_NODE_REMOVED_KEY, listener)
	return

_nodesToBeRemove = {}

setInterval(() ->
	for id, node of _nodesToBeRemove
		store = cola.util.userDataStore[id]
		if store
			changed = true
			nodeRemovedListener = store[ON_NODE_REMOVED_KEY]
			if nodeRemovedListener
				if nodeRemovedListener instanceof Array
					for listener in nodeRemovedListener
						listener(node, store)
				else
					nodeRemovedListener(node, store)
			delete cola.util.userDataStore[id]

	if changed then _nodesToBeRemove = {}
	return
, 10000)

_getNodeDataId = (node) ->
	return if node.nodeType == 3

	if node.nodeType == 8
		text = node.nodeValue
		i = text.indexOf("|")
		id = text.substring(i + 1) if i > -1
	else
		id = node.getAttribute(USER_DATA_KEY)
	return id

_DOMNodeInsertedListener = (evt) ->
	node = evt.target
	return unless node

	child = node.firstChild
	while child
		id = _getNodeDataId(child)
		if id then delete _nodesToBeRemove[id]
		child = child.nextSibling

	id = _getNodeDataId(node)
	if id then delete _nodesToBeRemove[id]
	return

_DOMNodeRemovedListener = (evt) ->
	return if cola._ignoreNodeRemoved or window.closed

	node = evt.target
	return unless node

	child = node.firstChild
	while child
		id = _getNodeDataId(child)
		if id then _nodesToBeRemove[id] = child
		child = child.nextSibling

	id = _getNodeDataId(node)
	if id then _nodesToBeRemove[id] = node
	return

document.addEventListener("DOMNodeInserted", _DOMNodeInsertedListener)
document.addEventListener("DOMNodeRemoved", _DOMNodeRemovedListener)

$fly(window).on("unload", () ->
	document.removeEventListener("DOMNodeInserted", _DOMNodeInsertedListener)
	document.removeEventListener("DOMNodeRemoved", _DOMNodeRemovedListener)
	return
)

if cola.device.mobile
	$fly(window).on("load", () ->
		FastClick.attach(document.body)
		return
	)

if cola.browser.webkit
	browser = "webkit"
	if cola.browser.chrome
		browser += " chrome"
	else if cola.browser.safari
		browser += " safari"
#	else if cola.browser.qqbrowser
#		browser += " qqbrowser"
else if cola.browser.ie
	browser = "ie"
else if cola.browser.mozilla
	browser = "mozilla"
else
	browser = ""

if cola.os.android
	os = " android"
else if cola.os.ios
	os = " ios"
else if cola.os.windows
	os = " windows"
else
	os = ""

if cola.device.mobile
	os += " mobile"
else if cola.device.desktop
	os += " desktop"

if browser or os
	$fly(document.documentElement).addClass(browser + os)

if cola.os.mobile
	$ () ->
		FastClick?.attach(document.body)
		return
