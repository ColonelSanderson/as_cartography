function SearchRequest() {
    var self = this;

    this.setupNavigation();
    this.setupApprovalConfirmation();
};


SearchRequest.prototype.setupNavigation = function() {
    var $browseActions = $($('#MAPSearchRequestBrowseActions').html());
    $browseActions.appendTo('.repository-header .browse-container ul:first');
};

SearchRequest.prototype.setupApprovalConfirmation = function() {
    var self = this;

    $(document).on('submit', '.search-request-toolbar form', function () {
        var form = $(this);

        var template = (form.attr('id') === 'approve_search_request') ?
            'search_request_confirm_approval_template' :
            'search_request_confirm_cancel_template';

        if (form.data('confirmation_received')) {
            return true;
        } else {
            self.showConfirmation(form, template);
            return false;
        }
    });
};



$(document).ready(function() {
    window.search_request = new SearchRequest();
});
