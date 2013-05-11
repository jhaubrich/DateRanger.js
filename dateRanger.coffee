 # requires JQuery, JQueryUI, and d3

# TODO
# - [X] highlight box that is changed by script
# - [X] turn invalid box red on keypress.enter
# - [X] allow duration to be entered as 3, :02, 3:
# - [X] replace hms d3 patterns with RegExps
# - [X] keep track of order in which user inputs
#   - [X] calculate accordingly
# - [X] squash delta math bug
# - [X] keep delta when edate < sdate
# - [X] Don't callback unless values actually change

dateRanger = (init) ->
    iso = d3.time.format.utc("%Y-%m-%d %H:%M")

    hms = (millisecs) ->
        # converts millisecs to %H:%M
        seconds = millisecs / 1000
        h = Math.floor(seconds / 3600)
        r_secs = seconds % 3600
        m = Math.floor(r_secs / 60)
        # s = Math.floor(r_secs % 60)
        return "#{h}:#{m}"#:#{s}"

    class LastUserInputs
        full_list: ['#sdate', '#delta', '#edate']
        history: ['#sdate', '#edate'], # ['#sdate', '#delta'], 
        update: (new_id) ->
            if new_id in @history
                # Allow user to submit the same id repeatedly
                # without destroying the history.
                # e.g. ["#delta", "#delta"]
                return @history
            else
                @history.push(new_id)
                @history = @history[-2..]  # keep only last 2
                return @history

        suggest: (current_id) ->
            # Smartly suggests the input box to be changed.
            if current_id in @history
                # find the inputbox the user didn't touch
                for id in @full_list
                    if id not in @history 
                        return id
            else
                # all three inputs have been changed.
                # Suggest changing the oldest.
                return @history[0]

    lui = new LastUserInputs
    # lui unittest:
    # console.log('#delta', lui.suggest('#delta')) # Output: #delta #edate
    # console.log('#sdate', lui.suggest('#sdate')) # Output: #sdate #edate
    # console.log('#edate', lui.suggest('#edate')) # Output: #edate #sdate 
    # TODO: look into javascript unittesting

    # Initialize State (don't hate)
    # console.log  init
    # defaults: edate = now, sdate = now - 24hrs
    edate = if (typeof init.edate == 'undefined') then new Date else init.edate
    sdate = if (typeof init.sdate == 'undefined') then new Date else init.sdate
    # since we don't deal with seconds, having them is havoc
    sdate.setSeconds(0)
    sdate.setMilliseconds(0)
    edate.setSeconds(0)
    edate.setMilliseconds(0)
    delta = edate - sdate

    # Set initigal datetime input boxes
    $("#sdate").val(iso sdate)
    $("#delta").val(hms delta)
    $("#edate").val(iso edate)


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
            get_valid_delta '#delta'
            get_valid_date '#sdate'
            get_valid_date '#edate'

    if init.focusout == true
        $('#info input').focusout (event) ->
            if not has_error()
                if update_boxes(event.target.id)
                    init.callback(sdate, edate)

    update_boxes = (id) ->
        if id == 'delta'
            old_delta = delta
            delta = get_valid_delta('#delta')
            if old_delta - delta != 0
                if delta  # null if not valid date
                    suggested = lui.suggest('#delta')
                    if suggested is "#sdate"
                        # update #sdate
                        sdate = new Date(edate - delta)
                        $('#sdate').val(iso sdate)
                        highlight_update '#sdate'
                    if suggested is "#edate"
                        # update #edate
                        edate = new Date(+sdate + delta)
                        $('#edate').val(iso edate)
                        highlight_update '#edate'
                    lui.update("#delta")
                    return yes
                else
                    highlight_error("#delta")

        if id == 'sdate'
            old_sdate = sdate
            sdate = get_valid_date('#sdate')
            if old_sdate - sdate != 0
                if sdate  # null if not valid date
                    suggested = lui.suggest('#sdate')
                    if suggested is "#delta"
                        # suggested is probably wrong in this case.
                        # We might instead change edate with existing delta.
                        # $('#edate').val(iso new Date(+sdate + delta))
                        if edate > sdate
                            delta = edate - sdate
                            $('#delta').val(hms delta)
                            highlight_update '#delta'
                        else if sdate > edate
                            $('#edate').val(iso new Date(+sdate + delta))
                            highlight_update '#edate'
                    if suggested is "#edate"
                        $('#edate').val(iso new Date(+sdate + delta))
                        highlight_update '#edate'
                    lui.update("#sdate")
                    return yes
                else
                    highlight_error("#sdate")

        if id == 'edate'
            old_edate = edate
            edate = get_valid_date('#edate')
            if old_edate - edate != 0
                if edate  # null if not valid date
                    suggested = lui.suggest('#edate')
                    if suggested is "#delta"
                        # suggested is probably wrong in this case.
                        # We might instead change edate with existing delta.
                        # $('#edate').val(iso new Date(+sdate + delta))
                        if edate > sdate
                            delta = edate - sdate
                            $('#delta').val(hms delta)
                            highlight_update '#delta'
                        else if sdate > edate
                            $('#sdate').val(iso new Date(edate - delta))
                            highlight_update '#edate'
                    if suggested is "#sdate"
                        $('#sdate').val(iso new Date(edate - delta))
                        highlight_update '#sdate'
                    lui.update("#edate")
                    return yes
                else
                    highlight_error("#sdate")

    reset_boxes = () ->
        # reset defaults
        $('#sdate').val(iso sdate)
        $('#delta').val(hms delta)
        $('#edate').val(iso edate)
        clear_highlighting()

    in_millisecs = () ->
        # convert various forms of %H:%M to millisecs
        hms_format = new RegExp("\d*:\d*")
        h_format =  new RegExp("\d*")
        gabe_h_format =  new RegExp("\d*:")
        gabe_m_format =  new RegExp(":\d*")
        # could check for bad chars [^\d:\.]
        # doesn't seem to be needed.
        return (hms) ->
            if hms_format.test(hms)
                hms = hms.split(":")
                ms = +hms[0] * 1000 * 3600  # hours
                ms += +hms[1] * 1000 * 60  # minutes
                return ms
            if gabe_h_format.test(hms)
                hms = hms.split(":")
                ms = +hms[0] * 1000 * 3600  # hours
                return ms
            if gabe_m_format.test(hms)
                hms = hms.split(":")
                ms = +hms[1] * 1000 * 60  # minutes
                return ms
            if h_format.test(hms)
                ms = +hms * 1000 * 3600  # hours
                return ms
    in_millisecs = in_millisecs()

    get_valid_date = (active_box) ->
        # pull timestamp from input box and convert to date obj
        timestamp = iso.parse($(active_box).val())
        if timestamp is null  # timestamp didn't parse
            d3.select(active_box).classed("error", true)
            return no
        else
            d3.select(active_box).classed("error", false)
            return timestamp

    get_valid_delta = (delta_box) ->
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
        $(id).effect("highlight", {color:'orange'}, 100)

    highlight_update = (id) ->
        $(id).effect("highlight", {color:'lightblue'}, 1500)

    clear_highlighting = () ->
        for box in ['#sdate', '#delta', '#edate']
            d3.select(box).classed("error", false)

