/* Support adding multiple items to a collection
 */

function update_add_multiple_form_url() {
    var items = $('input.toggle_add_to_collection:checked').map(function() {
        return $(this).attr('data-document-id');
    }).get().join();
    $button = $('a#add_multiple_to_collectionLink');
    $placeholder= $('a#add_multiple_to_collectionPlaceholder');
    if (items.length) {
        $button.attr('href', '/catalog/' + items + '/add_to_collection');
        $button.show();
        $placeholder.hide();
    } else {
        $button.hide();
        $placeholder.show();
    }
}

/* Show the modal using the Foundation library, after the content has been loaded */
$(function() {
    $('input.toggle_add_to_collection').on('change', function () {
        update_add_multiple_form_url();
    });
    $('input.toggle_all_add_to_collection').on('change', function () {
        if ($(this).is(':checked')) {
            $('.toggle_add_to_collection').prop('checked', true);
        } else {
            $('.toggle_add_to_collection').prop('checked', false);
        }
        update_add_multiple_form_url();
    });

    $('a#add_multiple_to_collectionPlaceholder').click(function() {
        alert("You must select one or more items to add");
        return false;
    })
});

