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

        var template = undefined;

        if (form.attr('id') === 'approve_search_request') {
            template = 'search_request_confirm_approval_template';
        } else if (form.attr('id') === 'cancel_search_request') {
            template = 'search_request_confirm_cancel_template';
        } else if (form.attr('id') === 'close_search_request') {
            template = 'search_request_confirm_close_template';
        } else if (form.attr('id') === 'reopen_search_request') {
            template = 'search_request_confirm_reopen_template';
        }

        if (template === undefined) {
            throw "confirmation template not found: " + form.attr('id');
        }

        if (form.data('confirmation_received')) {
            return true;
        } else {
            self.showConfirmation(form, template);
            return false;
        }
    });
};

SearchRequest.prototype.showConfirmation = function(form, templateId) {
    var self = this;

    AS.openCustomModal("confirmSearchRequestWorkflowModal",
        $('#' + templateId).data("title"),
        AS.renderTemplate(templateId),
        null,
        {},
        form.find('.btn'));

    $(".confirmButton", "#confirmSearchRequestWorkflowModal").click(function() {
        $(".btn", "#confirmSearchRequestWorkflowModal").attr("disabled", "disabled");
        form.data('confirmation_received', true).submit();
    });
};



$(document).ready(function() {
    window.search_request = new SearchRequest();
});
