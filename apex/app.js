// date picker for G_DATE item
$(function() {
    var g_date      = 'G_DATE';
    var $el         = $('#NAV_CALENDAR');
    //
    if (!$el.length) {
        return;
    }

    // get date from input field
    var original    = $el.val().substring(0, 10);
    var curr_date   = original.split('-');
    var curr_day    = new Date(curr_date[0] * 1, curr_date[1] * 1 - 1, curr_date[2] * 1);  // YYYY-MM-DD

    // convert link to input field
    $el.datepicker({
        showOtherMonths:    true,
        selectOtherMonths:  true,
        firstDay:           1,
        defaultDate:        '0',
        dateFormat:         'yy-mm-dd',
        nextText:           '&rarr;',
        prevText:           '&larr;',
        //
        onSelect: function(date) {
            var path = window.location.pathname + window.location.search.split('&' + g_date + '=')[0] + '&' + g_date + '=' + date;
            $el.val(date).datepicker('hide').blur();  // hide on pressing enter in input field
            window.location = path;
        }
    }).datepicker('setDate', curr_day);

    // show or hide calendar just on date field focus/blur
    $el.bind('blur', function() {
        $el.parent().removeClass('active_hover');
    });
    $el.bind('focus', function() {
        $el.parent().addClass('active_hover');
        var that = this;
        setTimeout(function() { that.selectionStart = that.selectionEnd = 100; }, 0);
    });
    $el.parent().mouseover(function() {
        $el.focus();
    });

    // hide calendar when other link is focused
    $('body a').not('.date_picker').mouseover(function() {
        $el.datepicker('hide');
        $el.blur();
    });
});

