// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require rails-ujs
//= require turbolinks
//
// Required by Blacklight
//= require jquery
//= require blacklight/blacklight

//= require_tree .
//= require foundation

$(document).on('turbolinks:load', function() {
    $(function(){ $(document).foundation({
        accordion: {
            active_class: 'active',
            // allow multiple accordion panels to be active at the same time
            multi_expand: true,
            // allow accordion panels to be closed by clicking on their headers
            // setting to false only closes accordion panels when another is opened
            toggleable: true,
            callback: function (accordion) {
                setFacetAccordionState($('#facets .accordion-navigation.active').length > 0);
            }
        }
        
        }, 'reflow');
    });

    setFacetAccordionState($('#facets .accordion-navigation.active').length > 0);

    $('.toggle-all-facets').click(function () {
        if ($(this).attr('aria-expanded') == 'true') {
            $('#facets .accordion-navigation.active > a').trigger('click');
        } else {
            $('#facets .accordion-navigation:not(.active) > a').trigger('click');
        }
        return false;
    });

    function setFacetAccordionState(expanded) {
        if (expanded) {
            $(".toggle-all-facets").attr('aria-expanded', 'true');
        }
        else {
            $(".toggle-all-facets").attr('aria-expanded', 'false');
        }
    }

    $(".view-mode__list").click(function() {
        $('#documents').toggleClass('list-mode', true);
        $(this).toggleClass('active', true);
        $(".view-mode__grid").toggleClass('active', false);
        return false;
    });
    $(".view-mode__grid").click(function() {
        $('#documents').toggleClass('list-mode', false);
        $(this).toggleClass('active', true);
        $(".view-mode__list").toggleClass('active', false);
        return false;
    });

});

