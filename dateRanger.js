// Generated by CoffeeScript 1.6.2
/* Date range selector with a sixth sense.

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
*/

var dateRanger,
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

dateRanger = function(init) {
  var LastUserInputs, clear_highlighting, delta, edate, get_valid_date, get_valid_delta, has_error, highlight_error, highlight_update, hms, in_millisecs, iso, lui, reset_boxes, sdate, update_boxes;

  iso = d3.time.format.utc("%Y-%m-%d %H:%M");
  iso.parse = function(t) {
    var parsed_iso, parsed_no_HM;

    parsed_iso = d3.time.format.utc("%Y-%m-%d %H:%M").parse(t);
    parsed_no_HM = d3.time.format.utc("%Y-%m-%d").parse(t);
    if (parsed_iso) {
      return parsed_iso;
    }
    if (parsed_no_HM) {
      return parsed_no_HM;
    }
    return null;
  };
  hms = function(millisecs) {
    var h, m, r_secs, seconds;

    seconds = millisecs / 1000;
    h = Math.floor(seconds / 3600);
    r_secs = seconds % 3600;
    m = Math.floor(r_secs / 60);
    return "" + h + ":" + m;
  };
  in_millisecs = (function() {
    /* convert various forms of %H:%M to millisecs.
    We use a closure so RegExp objects on created on every keystroke.
    */

    var gabe_h_format, gabe_m_format, h_format, hms_format;

    hms_format = new RegExp(/\d+:\d+/);
    h_format = new RegExp(/\d+/);
    gabe_h_format = new RegExp(/\d+:/);
    gabe_m_format = new RegExp(/:\d+/);
    return function(hms) {
      var ms;

      if (hms_format.test(hms)) {
        hms = hms.split(":");
        ms = +hms[0] * 1000 * 3600;
        ms += +hms[1] * 1000 * 60;
        return ms;
      }
      if (gabe_h_format.test(hms)) {
        hms = hms.split(":");
        ms = +hms[0] * 1000 * 3600;
        return ms;
      }
      if (gabe_m_format.test(hms)) {
        hms = hms.split(":");
        ms = +hms[1] * 1000 * 60;
        return ms;
      }
      if (h_format.test(hms)) {
        ms = +hms * 1000 * 3600;
        return ms;
      }
    };
  })();
  get_valid_date = function(active_box) {
    /* pull timestamp from input box and convert to date obj
    */

    var timestamp;

    timestamp = iso.parse($(active_box).val());
    if (timestamp === null) {
      d3.select(active_box).classed("error", true);
      return false;
    } else {
      d3.select(active_box).classed("error", false);
      return timestamp;
    }
  };
  get_valid_delta = function(delta_box) {
    /* pull timestamp from input box and convert to date obj
    */

    var ms;

    if (ms = in_millisecs($(delta_box).val())) {
      d3.select(delta_box).classed("error", false);
      return ms;
    } else {
      d3.select(delta_box).classed("error", true);
      return false;
    }
  };
  has_error = function() {
    /* Determine if an error has been raised by checking each
    input box for the error class.
    */

    var input_box, _i, _len, _ref;

    _ref = ['#sdate', '#delta', '#edate'];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      input_box = _ref[_i];
      if ($(input_box).hasClass('error')) {
        $(input_box).effect("highlight", {
          color: 'orange'
        }, 500);
        return true;
      } else {
        false;
      }
    }
  };
  edate = typeof init.edate === 'undefined' ? new Date : init.edate;
  sdate = typeof init.sdate === 'undefined' ? new Date(edate - 3600 * 24 * 1000) : init.sdate;
  sdate.setSeconds(0);
  sdate.setMilliseconds(0);
  edate.setSeconds(0);
  edate.setMilliseconds(0);
  delta = edate - sdate;
  $("#sdate").val(iso(sdate));
  $("#delta").val(hms(delta));
  $("#edate").val(iso(edate));
  $('#info input').keyup(function(event) {
    if (event.keyCode === 13) {
      if (!has_error()) {
        if (update_boxes(event.target.id)) {
          return init.callback(sdate, edate);
        }
      }
    } else if (event.keyCode === 27) {
      return reset_boxes();
    } else {
      get_valid_delta('#delta');
      get_valid_date('#sdate');
      return get_valid_date('#edate');
    }
  });
  if (init.focusout === true) {
    $('#info input').focusout(function(event) {
      if (!has_error()) {
        if (update_boxes(event.target.id)) {
          return init.callback(sdate, edate);
        }
      }
    });
  }
  reset_boxes = function() {
    /* reset defaults
    */
    $('#sdate').val(iso(sdate));
    $('#delta').val(hms(delta));
    $('#edate').val(iso(edate));
    return clear_highlighting();
  };
  update_boxes = function(id) {
    var old_delta, old_edate, old_sdate, suggested;

    if (id === 'delta') {
      old_delta = delta;
      delta = get_valid_delta('#delta');
      if ((old_delta - delta) !== 0) {
        if (delta) {
          suggested = lui.suggest('#delta');
          if (suggested === "#sdate") {
            sdate = new Date(edate - delta);
            $('#sdate').val(iso(sdate));
            highlight_update('#sdate');
          }
          if (suggested === "#edate") {
            edate = new Date(+sdate + delta);
            $('#edate').val(iso(edate));
            highlight_update('#edate');
          }
          lui.updated("#delta");
          return true;
        } else {
          highlight_error("#delta");
        }
      }
    }
    if (id === 'sdate') {
      old_sdate = sdate;
      sdate = get_valid_date('#sdate');
      if ((old_sdate - sdate) !== 0) {
        if (sdate) {
          suggested = lui.suggest('#sdate');
          if (suggested === "#delta") {
            if (edate > sdate) {
              delta = edate - sdate;
              $('#delta').val(hms(delta));
              highlight_update('#delta');
            } else if (sdate > edate) {
              $('#edate').val(iso(new Date(+sdate + delta)));
              highlight_update('#edate');
            }
          }
          if (suggested === "#edate") {
            $('#edate').val(iso(new Date(+sdate + delta)));
            highlight_update('#edate');
          }
          lui.updated("#sdate");
          return true;
        } else {
          highlight_error("#sdate");
        }
      }
    }
    if (id === 'edate') {
      old_edate = edate;
      edate = get_valid_date('#edate');
      if ((old_edate - edate) !== 0) {
        if (edate) {
          suggested = lui.suggest('#edate');
          if (suggested === "#delta") {
            if (edate > sdate) {
              delta = edate - sdate;
              $('#delta').val(hms(delta));
              highlight_update('#delta');
            } else if (sdate > edate) {
              $('#sdate').val(iso(new Date(edate - delta)));
              highlight_update('#sdate');
            }
          }
          if (suggested === "#sdate") {
            $('#sdate').val(iso(new Date(edate - delta)));
            highlight_update('#sdate');
          }
          lui.updated("#edate");
          return true;
        } else {
          return highlight_error("#sdate");
        }
      }
    }
  };
  highlight_error = function(id) {
    return $(id).effect("highlight", {
      color: 'orange'
    }, 100);
  };
  highlight_update = function(id) {
    return $(id).effect("highlight", {
      color: 'lightblue'
    }, 1500);
  };
  clear_highlighting = function() {
    var box, _i, _len, _ref, _results;

    _ref = ['#sdate', '#delta', '#edate'];
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      box = _ref[_i];
      _results.push(d3.select(box).classed("error", false));
    }
    return _results;
  };
  LastUserInputs = (function() {
    function LastUserInputs() {}

    /* keep track of the order in which boxes are edited,
    and provide suggestions.
    */


    LastUserInputs.prototype.full_list = ['#sdate', '#delta', '#edate'];

    LastUserInputs.prototype.first_change = ['#delta', '#sdate'];

    LastUserInputs.prototype.history = [];

    LastUserInputs.prototype.updated = function(new_id) {
      if (__indexOf.call(this.history, new_id) >= 0) {
        /* Allow user to submit the same id repeatedly
        without destroying the history.
        */

        return this.history;
      } else {
        this.history.push(new_id);
        this.history = this.history.slice(-2);
        return this.history;
      }
    };

    LastUserInputs.prototype.absent = function(list) {
      /* return the first value in full_list, not in argument list
      */

      var id, _i, _len, _ref;

      _ref = this.full_list;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        id = _ref[_i];
        if (__indexOf.call(list, id) < 0) {
          return id;
        }
      }
    };

    LastUserInputs.prototype.suggest = function(current_id) {
      /* Smartly suggests the input box to be changed.
      */

      var absent_id;

      if (this.history.length === 0) {
        if (__indexOf.call(this.first_change, current_id) >= 0) {
          if (current_id !== this.first_change[0]) {
            return this.first_change[0];
          } else {
            return this.first_change[1];
          }
        } else {
          return this.first_change[0];
        }
      }
      if (this.history.length === 1) {
        if (absent_id = this.absent(this.history.concat(current_id))) {
          return absent_id;
        } else {
          return this.first_change[0];
        }
      }
      if (__indexOf.call(this.history, current_id) >= 0) {
        return this.absent(this.history);
      } else {
        return this.history[0];
      }
    };

    return LastUserInputs;

  })();
  return lui = new LastUserInputs;
};
