/* Override some functionality in the Blacklight ajax_modal.js to allow display of the modal dialog
   using the Foundation framework rather than Bootstrap
 */

/* Show the modal using the Foundation library, after the content has been loaded */
$(document).on('loaded.blacklight.blacklight-modal', function() {
    jQuery('#ajax-modal').foundation('reveal', 'open');
});