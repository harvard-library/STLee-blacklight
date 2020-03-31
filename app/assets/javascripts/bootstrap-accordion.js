$(document).on('turbolinks:load', function () {
  
  var windowWidth = $(window).width();
  if (windowWidth <= 992) { //for iPad & smaller devices
    $('#accordion .panel-collapse').collapse('hide');
    $('#accordion .expand_caret').addClass('fa-rotate-180');
  } else {
    $('.toggle-all-facets .expand-text').hide();
    $('.toggle-all-facets .collapse-text').show();
    $('.toggle-all-facets').attr('aria-expanded', 'true');
  }


  $('.toggle-all-facets').on('click', function () {
    if ($(this).attr('aria-expanded') === 'true') {
      setToggleCollapsed();
    } else {
      $('.toggle-all-facets').attr('aria-expanded', 'true');
      $('#accordion .panel-collapse').collapse('show');
      $('.toggle-all-facets').find('.expand-text').hide();
      $('.toggle-all-facets').find('.collapse-text').show();
    }
  });

  $('#accordion .panel-collapse').on('show.bs.collapse', function () {
    $(this).parent().find('.expand_caret').removeClass('fa-rotate-180');
  });
  $('#accordion .panel-collapse').on('hide.bs.collapse', function () {
    $(this).parent().find('.expand_caret').addClass('fa-rotate-180');
  });
  $('#accordion .panel-collapse').on('hidden.bs.collapse', function () {
    if ($('.facets__container .panel-collapse.in').length == 0) {
      setToggleCollapsed();
    }
  });
  $('#details dd.collapse').on('show.bs.collapse', function () {
    $(this).prev().find('.field-toggle .fa').removeClass('fa-plus').addClass('fa-minus');
  });
  $('#details dd.collapse').on('hide.bs.collapse', function () {
    $(this).prev().find('.field-toggle .fa').removeClass('fa-minus').addClass('fa-plus');
  });
});

function setToggleCollapsed() {
  $('.toggle-all-facets').attr('aria-expanded', 'false');
  $('#accordion .panel-collapse').collapse('hide');
  $('.toggle-all-facets').find('.expand-text').show();
  $('.toggle-all-facets').find('.collapse-text').hide();
}
