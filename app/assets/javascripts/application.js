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

$(document).on('turbolinks:load', function() {

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

    function closeModal() {
        $('#ajax-modal').removeClass('open');
        $('.reveal-modal').removeClass('open').removeClass('in').hide();
        $('.reveal-modal-bg').hide();
        $('.modal-backdrop').hide();
        $('body').removeClass('modal-open');
    }

    $('body').on('click', '.ajax-modal-close', function () {
        closeModal();
    });

    $('body').on('keyup', function (e) {
        if (e.key === "Escape" && $('body').hasClass('modal-open')) {
            closeModal();   
        }
    });

    $('body').on('submit', 'form.range_limit', function (e) {
        return validateRangeLimits($(this));
    });

    $('body').on('blur', 'form.range_limit input', function (e) {
        validateRangeLimits($(this).parents('form'));
    });

    $('form.range_limit input.form-control').attr('placeholder', 'YYYY');

});

function validateRangeLimits($form) {
    startYear = $form.find('.form-control.range_begin').val();
    endYear = $form.find('.form-control.range_end').val();

    $form.find('.error').remove();

    if (startYear != '' && (isNaN(startYear) || startYear != parseInt(startYear))) {
        $form.append('<span class="error">Please enter a valid start year.</span>');
        return false;
    }

    if (endYear != '' && (isNaN(endYear) || endYear != parseInt(endYear))) {
        $form.append('<span class="error">Please enter a valid end year.</span>');
        return false;
    }
    
    if (startYear != '' && endYear != '' && parseInt(startYear) > parseInt(endYear)) {
        $form.append('<span class="error">End year should be less than or equal start year.</span>');
        return false;
    }
    
    return true;
}

// For blacklight_range_limit built-in JS, if you don't want it you don't need
// this:
//= require 'blacklight_range_limit'

