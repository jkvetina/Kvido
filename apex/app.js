// INTERACTIVE GRIDS - look for css change on Edit button and apply it to Save button
var apex_page_loaded = function() {
    var observer = new MutationObserver(function(mutations) {
        mutations.forEach(function(mutation) {
            var $target = $(mutation.target);
            if ($target.hasClass('is-active')) {
                var $save = $target.parent().parent().find('button.a-Button.a-Toolbar-item.js-actionButton[data-action="save"]');
                $save.addClass('is-active');
                // remove observer when fired ?
            }
        });
    });
    //
    $.each($('div.a-Toolbar-toggleButton.js-actionCheckbox.a-Toolbar-item[data-action="edit"] > label'), function(i, el) {
        // assign unique ID + apply tracker/observer
        $el = $(el);
        $el.attr('id', 'OBSERVE_' + $el.attr('for'));
        observer.observe($el[0], {
            attributes: true
        });
    });
};



// common toolbar for all grids
// just put following code in Region - Attributes - JavaScript Initialization Code
// and assign Static ID to region
/**
function(config) {
    return unified_ig_toolbar(config, 'REGION_STATIC_ID');
}
 */
var unified_ig_toolbar = function(config, grid_id) {
    var $ = apex.jQuery;
    var toolbarData = $.apex.interactiveGrid.copyDefaultToolbar();
    var toolbarGroup = toolbarData.toolbarFind('actions4');

    // only for developers
    // add a filter button after the actions menu
    toolbarGroup.controls.push({
        type            : 'BUTTON',
        action          : 'save-report',
        label           : 'Save as Default',
        icon            : ''  // no icon
    });
    config.toolbarData = toolbarData;

    // add upload button
    if (grid_id != '') {
        toolbarGroup = toolbarData.toolbarFind('actions3');
        toolbarGroup.controls.push( {
            type: 'BUTTON',
            action: 'upload_button'
        });
        config.toolbarData = toolbarData;
        config.initActions = function(actions) {
            actions.add({
                name    : 'upload_button',
                label   : 'Upload',
                action  : function(event, focusElement) {
                    //console.log(this, event, focusElement);
                    location.href = apex.util.makeApplicationUrl({
                        pageId      : 800,
                        itemNames   : ['P800_RESET', 'P800_TARGET'],
                        itemValues  : ['Y', grid_id]
                    });
                }
            });
        }
    }

    return config;
};



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

