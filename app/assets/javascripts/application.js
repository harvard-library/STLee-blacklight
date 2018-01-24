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
            toggleable: true
        }
    }, 'reflow'); });
});
