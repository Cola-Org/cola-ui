isIE11 = (/Trident\/7\./).test(navigator.userAgent)

class cola.Textarea extends cola.AbstractEditor
    @CLASS_NAME: "input textarea"
    @tagName: "c-textarea"
    @attributes:
        postOnInput:
            type: "boolean"
            defaultValue: false
        placeholder:
            refreshDom: true
        rows:
            type: "number"
            refreshDom: true

        value:
            setter: (value)->
                if @_dataType
                    value = @_dataType.parse(value)
                return @_setValue(value)

    @events:
        keyPress: null

    destroy: ()->
        unless @_destroyed
            super()
            delete @_doms
        return

    _bindSetter: (bindStr)->
        super(bindStr)
        dataType = @getBindingDataType()
        if dataType then cola.DataType.dataTypeSetter.call(@, dataType)
        return
    focus: ()->
        @_doms.input?.focus();
        return

    _initDom: (dom)->
        super(dom)
        @_doms ?= {}
        unless dom.nodeName is "TEXTAREA"
            input = $.xCreate({
                tagName: "textarea"
            })
            @_doms.input = input
            dom.appendChild(input)
        else
            @_doms.input = dom
        doPost = ()=>
            readOnly = @_readOnly
            if !readOnly
                value = $(@_doms.input).val()
                @set("value", value)
            return

        $(@_doms.input).on("change", ()=>
            doPost()
            return
        ).on("focus", ()=>
            @_focused = true
            @_refreshInputValue(@_value)
            @addClass("focused") if not @_finalReadOnly
            @fire("focus", @)
            return
        ).on("blur", ()=>
            @_focused = false
            @removeClass("focused")
            @_refreshInputValue(@_value)
            @fire("blur", @)

            if !@_value? or @_value is "" and @_bindInfo?.writeable
                propertyDef = @getBindingProperty()
                if propertyDef?._required and propertyDef._validators
                    entity = @_scope.get(@_bindInfo.entityPath)
                    entity.validate(@_bindInfo.property) if entity
            return
        ).on("input", ()=>
            if @_postOnInput then doPost()
            return
        ).on("keypress", (event)=>
            arg =
                keyCode: event.keyCode
                shiftKey: event.shiftKey
                ctrlKey: event.ctrlKey
                altlKey: event.altlKey
                event: event
            if @fire("keyPress", @, arg) == false then return
            if event.keyCode == 13 && isIE11 then doPost()
        )
        return

    _refreshInputValue: (value)->
        $fly(@_doms.input).val(if value? then value + "" or "")
        return

    _doRefreshDom: ()->
        return unless @_dom
        super()
        @_refreshInputValue(@_value)
        $fly(@_doms.input).prop("readOnly", @_readOnly).attr("placeholder", @_placeholder)
        @_rows and $fly(@_doms.input).attr("rows", @_rows)

    _resetDimension: ()->
        $dom = @get$Dom()
        unit = cola.constants.WIDGET_DIMENSION_UNIT

        height = @get("height")
        height = "#{+height}#{unit}" if isFinite(height)
        $fly(@_doms.input).css("height", height) if height

        width = @get("width")
        width = "#{+width}#{unit}" if isFinite(width)
        $dom.css("width", width) if width

        return

cola.registerWidget(cola.Textarea)

