 # requires JQuery, JQueryUI, and d3

# TODO
# - [X] highlight box that is changed by script
# - [X] turn invalid box red on keypress.enter
# - [X] allow duration to be entered as 3, :02, 3:
# - [ ] keep track of order in which user inputs, calculate accordingly
# - [X] squash delta math bug
# - [X] keep delta when edate < sdate

dateRanger = (init) ->
    iso = d3.time.format.utc("%Y-%m-%d %H:%M")

    hms = (millisecs) ->
        # converts millisecs to %H:%M
        seconds = millisecs / 1000
        h = Math.floor(seconds / 3600)
        r_secs = seconds % 3600
        m = Math.floor(r_secs / 60)
        # s = Math.floor(r_secs % 60)
        "#{h}:#{m}"#:#{s}"

    # Initialize State (don't hate)
    console.log  init
    # defaults: edate = now, sdate = now - 24hrs
    edate = if (typeof init.edate == 'undefined') then new Date else init.edate
    sdate = if (typeof init.sdate == 'undefined') then new Date else init.sdate
    # since we don't deal with seconds, having them is havoc
    sdate.setSeconds(0)
    sdate.setMilliseconds(0)
    edate.setSeconds(0)
    edate.setMilliseconds(0)
    delta = edate - sdate
    console.log init.sdate
    console.log(sdate, edate, delta)
    # Set initial datetime input boxes
    $("#info #sdate").val(iso sdate)
    $("#info #delta").val(hms delta)
    $("#info #edate").val(iso edate)

    # Event listener for changing datetime input boxes
    $('#info input').keyup (event) ->
        if event.keyCode == 13 # Enter Key
            if not has_error()
                if update_boxes(event.target.id)
                    init.callback(sdate, edate)
        else if event.keyCode == 27  # Escape Key
            reset_boxes()
        else
            # validate on every keystroke, eh?
            delta_validates '#delta'
            date_validates '#sdate'
            date_validates '#edate'

    if init.focusout == true
        $('#info input').focusout (event) ->
            if not has_error()
                if update_boxes(event.target.id)
                    init.callback(sdate, edate)

    update_boxes = (id) ->
        if id == 'delta'
            if delta = delta_validates '#delta'
                sdate = new Date(edate - delta)
                $('#sdate').val(iso sdate)
                return yes
            else
                highlight_error "#delta"

        if id == 'sdate'
            if sdate = date_validates '#sdate'
                if sdate > edate
                    $('#edate').val(iso d3.time.second.offset(sdate, delta/1000))
                else
                    delta = edate - sdate
                    $('#delta').val(hms delta)
                return yes
            else
                highlight_error "#sdate"

        if id == 'edate'
            if edate = date_validates '#edate'
                if sdate > edate
                    $('#sdate').val(iso d3.time.second.offset(edate, delta/1000))
                    $('#sdate').val(iso new Date(edate - delta))
                else
                    delta = edate - sdate
                    $('#delta').val(hms delta)
                return yes
            else
                highlight_error "#edate"

    reset_boxes = () ->
        # reset defaults
        $('#sdate').val(iso sdate)
        $('#delta').val(hms delta)
        $('#edate').val(iso edate)
        clear_highlighting()


    in_millisecs = (hms) ->
        # convert various forms of %H:%M to millisecs
        hms_format = d3.time.format("%H:%M")
        h_format = d3.time.format("%H")
        gabe_h_format = d3.time.format("%H:")
        gabe_m_format = d3.time.format(":%M")

        if hms_format.parse hms
            hms = hms.split(":")
            ms = +hms[0] * 1000 * 3600  # hours
            ms += +hms[1] * 1000 * 60  # minutes
            return ms
        if gabe_h_format.parse hms
            hms = hms.split(":")
            ms = +hms[0] * 1000 * 3600  # hours
            return ms
        if gabe_m_format.parse hms
            hms = hms.split(":")
            ms = +hms[1] * 1000 * 60  # minutes
            return ms
        if h_format.parse hms
            ms = +hms * 1000 * 3600  # hours
            return ms


    date_validates = (active_box) ->
        # pull timestamp from input box and convert to date obj
        timestamp = iso.parse($(active_box).val())
        if timestamp is null  # timestamp didn't parse
            d3.select(active_box).classed("error", true)
            return no
        else
            d3.select(active_box).classed("error", false)
            return timestamp

    delta_validates = (delta_box) ->
        # pull timestamp from input box and convert to date obj
        if ms = in_millisecs $(delta_box).val()
            d3.select(delta_box).classed("error", false)
            return ms
        else
            d3.select(delta_box).classed("error", true)
            return no

    has_error = () ->
        for input_box in ['#sdate', '#delta', '#edate']
            if $(input_box).hasClass('error')
                $(input_box).effect("highlight", {color:'orange'}, 500)
                return true
            else no

    highlight_error = (id) ->
        $(id).effect("highlight", {color:'orange'}, 500)
    clear_highlighting = () ->
        for box in ['#sdate', '#delta', '#edate']
            d3.select(box).classed("error", false)

