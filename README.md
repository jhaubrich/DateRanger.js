# DateRanger.js
[Checkout the example](http://jhaubrich.github.io/DateRanger.js/). I love the keyboard. So do you. Let's not click through datepicker. DateRanger provides sensible date range input aimed at the keyboard that *hopefully* just works.

Dates are always UTC

## Features
- Predicts which values you want to keep, and which you wish changed. (Still needs work)
- Validation on each keystroke
- Error and change highlighting
- Input delta as H:M, H, :M, H:

## Usage
Be sure you have three input boxes with the IDs sdate, delta, edate:
``` html
    <input id="sdate" />
    <input id="delta" />
    <input id="edate" />
```
Include the script:
``` html
    <script src='dateRanger.js'></script>
```
Specify the initial fields to populate and a callback.
``` html
    <script src='dateRanger.js'></script>
    <script type="text/javascript">
        dateRanger({
            sdate: new Date("May 5, 2013"),  // optional. Default: 24hrs ago
            edate: new Date(),               // optional. Default: now
            focusout: false,                 // optional. Default: true
            callback: function (sdate, edate){
                        console.log(sdate, " to ", edate)
                    }
        });
    </script>
```
### Options
- `sdate` (optional, default: 24rs ago) - Initial value for the starting date.
- `edate` (optional, default: now) - Initial value for the ending date.
- `focusout` (optional, default: true) - When true, ranges are calculated and callback called when an input loses focus.
- `callback` (arguments: sdate, edate) - called after date range changes and is validated.

## Build
Coffee script needs to be compiled as bare:

    coffee --bare --compile dateRanger.coffee

