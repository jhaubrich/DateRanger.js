# DateRanger.js
I love the keyboard. So do you. Let's not click through datepicker. DateRanger provides sensible date range input aimed at the keyboard that *hopefully* just works.

Dates are always UTC

## Usage
Include the script:
    <script src='dateRanger.js'></script>

Specify the initial fields to populate, and a callback.
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

## Building

    coffee --bare --compile dateRanger.coffee

