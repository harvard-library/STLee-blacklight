$(function() {
  $('.toggle-all-facets .expand-text').hide();
  $('.toggle-all-facets .collapse-text').show();

  $('.toggle-all-facets').on('click', function () {
    $('#accordion .panel-collapse').collapse('toggle');
    $('.toggle-all-facets .expand-text').toggle();
    $('.toggle-all-facets .collapse-text').toggle();
  });

  $('.expand_caret').on('click', function () {
    if ($(this).find('.expand_caret').hasClass('fa-rotate-180')) {
      $(this).find('.expand_caret').removeClass('fa-rotate-180');
    }
    else {
      $(this).find('.expand_caret').addClass('fa-rotate-180');
    }
  });

  $('.facet__title').on('click', function () {
    if ($(this).find('.expand_caret').hasClass('fa-rotate-180')) {
      $(this).find('.expand_caret').removeClass('fa-rotate-180');
    }
    else {
      $(this).find('.expand_caret').addClass('fa-rotate-180');
    }
  });
  
  var windowWidth = $(window).width();
  if(windowWidth <= 992) { //for iPad & smaller devices
    $('.panel-collapse').removeClass('in');
    $('.toggle-all-facets .collapse-text').hide();
    $('.toggle-all-facets .expand-text').show();
  }
});
