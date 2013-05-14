### Date range selector with a sixth sense.

Needs to be compiled with `--bare`
  coffee --bare --compile dateRanger.coffee

# Options
- `sdate` (optional, default: 24rs ago) - Initial value for the
starting date.
- `edate` (optional, default: now) - Initial value for the ending
date.
- `focusout` (optional, default: true) - When true, ranges are
calculated and callback
called when an input loses focus.
- `callback` (arguments: sdate, edate) - called after date range
changes and is validated.
###

# requires JQuery, JQueryUI, and d3


dateRanger = (init) ->
  ####################################################################
  # Date and Time Parsers
  ####################################################################
  iso = d3.time.format.utc("%Y-%m-%d %H:%M")
  iso.parse = (t) ->
    parsed_iso = d3.time.format.utc("%Y-%m-%d %H:%M").parse(t)
    parsed_no_HM = d3.time.format.utc("%Y-%m-%d").parse(t)
    if parsed_iso then return parsed_iso
    if parsed_no_HM then return parsed_no_HM
    return null

  hms = (millisecs) ->
    # converts millisecs to %H:%M
    seconds = millisecs / 1000
    h = Math.floor(seconds / 3600)
    r_secs = seconds % 3600
    m = Math.floor(r_secs / 60)
    # s = Math.floor(r_secs % 60)
    return "#{h}:#{m}"#:#{s}"

  in_millisecs =  do () ->
    ### convert various forms of %H:%M to millisecs.
    We use a closure so RegExp objects on created on every keystroke.
    ###
    hms_format = new RegExp("\d*:\d*")
    h_format =  new RegExp("\d*")
    gabe_h_format =  new RegExp("\d*:")
    gabe_m_format =  new RegExp(":\d*")
    # could check for bad chars [^\d:\.]... meh
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


  ####################################################################
  # Date validators
  ####################################################################
  get_valid_date = (active_box) ->
    ### pull timestamp from input box and convert to date obj
    ###
    timestamp = iso.parse($(active_box).val())
    if timestamp is null  # timestamp didn't parse
      d3.select(active_box).classed("error", true)
      return no
    else
      d3.select(active_box).classed("error", false)
      return timestamp

  get_valid_delta = (delta_box) ->
    ### pull timestamp from input box and convert to date obj
    ###
    if ms = in_millisecs $(delta_box).val()
      d3.select(delta_box).classed("error", false)
      return ms
    else
      d3.select(delta_box).classed("error", true)
      return no

  has_error = () ->
    ### Determine if an error has been raised by checking each
    input box for the error class.
    ###
    for input_box in ['#sdate', '#delta', '#edate']
      if $(input_box).hasClass('error')
        $(input_box).effect("highlight", {color:'orange'}, 500)
        return true
      else no


  ####################################################################
  # Initialize State (don't hate)
  ####################################################################
  # console.log  init
  # defaults: edate = now, sdate = now - 24hrs
  edate = if (typeof init.edate == 'undefined') then new Date else init.edate
  sdate = if (typeof init.sdate == 'undefined') then new Date(edate - 3600 * 24 * 1000) else init.sdate
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


  ####################################################################
  # Event listeners
  ####################################################################
  $('#info input').keyup (event) ->
    if event.keyCode == 13 # Enter Key
      if !has_error()
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
      if !has_error()
        if update_boxes(event.target.id)
          init.callback(sdate, edate)


  ####################################################################
  # Input box manipulators
  ####################################################################
  reset_boxes = () ->
    ### reset defaults
    ###
    $('#sdate').val(iso sdate)
    $('#delta').val(hms delta)
    $('#edate').val(iso edate)
    clear_highlighting()

  update_boxes = (id) ->
    # Decide which boxes to update and how.
    # FIXME: There is allot of code duplication that
    # should be turfed out to functions.
    if id == 'delta'
      old_delta = delta
      delta = get_valid_delta('#delta')
      if (old_delta - delta) != 0
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
          lui.updated("#delta")
          return yes
        else
          highlight_error("#delta")

    if id == 'sdate'
      old_sdate = sdate
      sdate = get_valid_date('#sdate')
      if (old_sdate - sdate) != 0
        if sdate  # null if not valid date
          suggested = lui.suggest('#sdate')
          if suggested is "#delta"
            # update #delta
            if edate > sdate
              delta = edate - sdate
              $('#delta').val(hms delta)
              highlight_update '#delta'
            else if sdate > edate
              # update edate
              $('#edate').val(iso new Date(+sdate + delta))
              highlight_update '#edate'
          if suggested is "#edate"
            # update edate
            $('#edate').val(iso new Date(+sdate + delta))
            highlight_update '#edate'
          lui.updated("#sdate")
          return yes
        else
          highlight_error("#sdate")

    if id == 'edate'
      old_edate = edate
      edate = get_valid_date('#edate')
      if (old_edate - edate) != 0
        if edate  # null if not valid date
          suggested = lui.suggest('#edate')
          if suggested is "#delta"
            if edate > sdate
              # update #delta
              delta = edate - sdate
              $('#delta').val(hms delta)
              highlight_update '#delta'
            else if sdate > edate
              # update #sdate
              $('#sdate').val(iso new Date(edate - delta))
              highlight_update '#sdate'
          if suggested is "#sdate"
            # update #sdate
            $('#sdate').val(iso new Date(edate - delta))
            highlight_update '#sdate'
          lui.updated("#edate")
          return yes
        else
          highlight_error("#sdate")


  ####################################################################
  # Highlighting effects!
  ####################################################################
  highlight_error = (id) ->
    $(id).effect("highlight", {color:'orange'}, 100)

  highlight_update = (id) ->
    $(id).effect("highlight", {color:'lightblue'}, 1500)

  clear_highlighting = () ->
    for box in ['#sdate', '#delta', '#edate']
      d3.select(box).classed("error", false)


  ####################################################################
  # Sixth Sense DateRange
  ####################################################################
  class LastUserInputs
    ### keep track of the order in which boxes are edited,
    and provide suggestions.
    ###
    full_list: ['#sdate', '#delta', '#edate']
    first_change: ['#delta', '#sdate'],  # init state
    history: []
    updated: (new_id) ->
      if new_id in @history
        ### Allow user to submit the same id repeatedly
        without destroying the history.
        ###
        return @history
      else
        @history.push(new_id)
        @history = @history[-2..]  # keep only last 2
        return @history

    absent: (list) ->
      ### return the first value in full_list, not in argument list
      ###
      for id in @full_list
        if id not in list
          return id

    suggest: (current_id) ->
      ### Smartly suggests the input box to be changed.
      ###
      if @history.length == 0
        if current_id in @first_change
          if current_id != @first_change[0]
            return @first_change[0]
          else
            return @first_change[1]
        else
          return @first_change[0]

      if @history.length == 1
        if absent_id = @absent(@history.concat current_id)
          return absent_id
        else
          return @first_change[0]

      if current_id in @history
        # find the inputbox the user didn't touch
        return @absent(@history)
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

