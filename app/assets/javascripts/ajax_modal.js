/* Override some functionality in the Blacklight ajax_modal.js to allow display of the modal dialog
   using the Foundation framework rather than Bootstrap
 */


var HarvardLibraryCloudModal = {};

HarvardLibraryCloudModal.setup_modal = function() {
  console.log('modal setup');
};

$(document).on('setup.blacklight.ajax-modal', function() {

    console.log('aaaaa');
});

/* Show the modal using the Foundation library, after the content has been loaded */
$(document).on('loaded.blacklight.blacklight-modal', function() {
    jQuery('#ajax-modal').foundation('reveal', 'open');
});