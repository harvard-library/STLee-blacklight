$(document).on('turbolinks:load', function () {
  
  var windowWidth = $(window).width();
  if (windowWidth <= 992) { //for iPad & smaller devices
    $('.panel-collapse').removeClass('in');
    $('.toggle-all-facets .collapse-text').hide();
    $('.toggle-all-facets .expand-text').show();
    $('.toggle-all-facets').attr('aria-expanded', 'false');
  } else {
    $('.toggle-all-facets .expand-text').hide();
    $('.toggle-all-facets .collapse-text').show();
    $('.toggle-all-facets').attr('aria-expanded', 'true');
  }


  $('.toggle-all-facets').on('click', function () {
    if ($(this).attr('aria-expanded') === 'true') {
      $(this).attr('aria-expanded', 'false');
      $('#accordion .panel-collapse').collapse('hide');
      $(this).find('.expand-text').show();
      $(this).find('.collapse-text').hide();
    } else {
      $(this).attr('aria-expanded', 'true');
      $('#accordion .panel-collapse').collapse('show');
      $(this).find('.expand-text').hide();
      $(this).find('.collapse-text').show();
    }
  });

  $('#accordion .panel-collapse').on('show.bs.collapse', function () {
    $(this).parent().find('.expand_caret').removeClass('fa-rotate-180')
  });
  $('#accordion .panel-collapse').on('hide.bs.collapse', function () {
    $(this).parent().find('.expand_caret').addClass('fa-rotate-180')
  });
});
