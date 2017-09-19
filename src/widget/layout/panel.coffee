class cola.Panel extends cola.AbstractContainer
    @CLASS_NAME: "panel"
    @tagName: "c-panel"
    @attributes:
        collapsible:
            type: "boolean"
            defaultValue: true
        closable:
            type: "boolean"
            defaultValue: false
        caption:
            refreshDom: true
        icon:
            refreshDom: true
    @TEMPLATES:
        "tools":
            tagName: "div"
    @events:
        open: null
        collapsedChange: null
        close: null
        beforeOpen: null
        beforeCollapsedChange: null
        beforeClose: null

    collapsedChange: ()->
        $dom = @_$dom
        collapsed = @isCollapsed()
        return @ if @fire("beforeCollapsedChange", @, {}) is false
        initialHeight = @get("height")
        unless initialHeight
            currentHeight = $dom.outerHeight()
            $dom.css("height", "initial")
            height = $dom.outerHeight()
            $dom.css("height", currentHeight)

        $dom.toggleClass("collapsed", !collapsed)
        headerHeight = $(@_headerContent).outerHeight()

        $dom.transit({
            duration: 300,
            height: if collapsed then height or @get("height") else headerHeight
            complete: ()=>
                if collapsed and !initialHeight then $dom.css("height", "initial");
                @fire("collapsedChange", @, {})
        })
        return

    isCollapsed: ()->
        return @_$dom?.hasClass("collapsed")

    isClosed: ()->
        return @_$dom?.hasClass("transition hidden")

    open: ()->
        return unless @isClosed()
        @toggle()

    close: ()->
        return if @isClosed()
        @toggle()

    toggle: ()->
        beforeEvt = "beforeOpen"
        onEvt = "open"
        unless @isClosed
            beforeEvt = "beforeClose"
            onEvt = "close"
        if @fire(beforeEvt, @, {}) is false
            return
        @_$dom.transition({animation: 'scale', onComplete: ()=> @fire(onEvt, @, {})})

    getContentContainer: ()->
        return null unless @_dom
        unless @_doms.content
            @_makeContentDom("content")

        return @_doms.content

    _initDom: (dom)->
        @_regDefaultTemplates()
        super(dom)
        @_headerContent = headerContent = $.xCreate({
            tagName: "div"
            class: "content"
        })
        @_doms.icon = $.xCreate({
            tagName: "i"
            class: "panel-icon"
        })
        headerContent.appendChild(@_doms.icon)

        @_doms.caption = $.xCreate({
            tagName: "span"
            class: "caption"
        })
        headerContent.appendChild(@_doms.caption)

        template = @getTemplate("tools")
        cola.xRender(template, @_scope)
        toolsDom = @_doms.tools = $.xCreate({
            class: "tools"
        })
        toolsDom.appendChild(template)

        nodes = $.xCreate([
            {
                tagName: "i"
                click: ()=>
                    @collapsedChange()
                class: "icon chevron down collapse-btn"
            }
            {
                tagName: "i"
                click: ()=>
                    @toggle()
                class: "icon close close-btn"
            }
        ])
        toolsDom.appendChild(node) for node in nodes
        headerContent.appendChild(toolsDom)


        @_render(headerContent, "header")
        @_makeContentDom("content") unless @_doms.content
        return

    _doRefreshDom: ()->
        return unless @_dom
        super()
        $fly(@_doms.caption).text(@_caption || "")
        if @_icon
            $fly(@_doms.icon).show().removeClass(@_doms.icon._icon)
        else
            $fly(@_doms.icon).hide()

        $fly(@_doms.icon).addClass("icon #{@_icon || ""}")
        @_doms.icon._icon = @_icon
        $fly(@_doms.tools).find(".collapse-btn")[if @_collapsible then "show" else "hide"]()
        $fly(@_doms.tools).find(".close-btn")[if @_closable then "show" else "hide"]()

    _makeContentDom: (target)->
        @_doms ?= {}
        dom = document.createElement("div")
        dom.className = target

        if target is "header"
            $(@_dom).prepend(dom)
        else
            @_dom.appendChild(dom)
        @_doms[target] = dom
        return dom

    _parseDom: (dom)->
        @_doms ?= {}

        _parseChild = (node, target)=>
            childNode = node.firstElementChild
            while childNode
                if childNode.nodeType == 1
                    widget = cola.widget(childNode)
                    @_addContentElement(widget or childNode, target)
                childNode = childNode.nextElementSibling
            return

        child = dom.firstElementChild
        while child
            if child.nodeType == 1
                if child.nodeName == "TEMPLATE"
                    @regTemplate(child)
                else
                    $child = $(child)
                    unless $child.hasClass("content")
                        child = child.nextSibling
                        continue
                    @_doms["content"] = child
                    _parseChild(child, "content")
                    break
            child = child.nextElementSibling
        return

cola.Element.mixin(cola.Panel, cola.TemplateSupport)

class cola.FieldSet extends cola.Panel
    @CLASS_NAME: "panel fieldset"
    @tagName: "c-fieldset"

class cola.GroupBox extends cola.Panel
    @CLASS_NAME: "panel groupbox"
    @tagName: "c-groupbox"

cola.registerWidget(cola.Panel)
cola.registerWidget(cola.FieldSet)
cola.registerWidget(cola.GroupBox)
