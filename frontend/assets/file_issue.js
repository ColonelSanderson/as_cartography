function FileIssue() {
    var self = this;

    this.setupNavigation();
    this.setupApprovalConfirmation();
};


FileIssue.prototype.setupNavigation = function() {
    var $browseActions = $($('#MAPFileIssueBrowseActions').html());
    $browseActions.appendTo('.repository-header .browse-container ul:first');
};

FileIssue.prototype.setupApprovalConfirmation = function() {
    var self = this;

    $(document).on('submit', '.file-issue-toolbar .file_issue_request_cancel_form', function () {
        var form = $(this);

        var template = 'file_issue_request_confirm_cancel_' + form.data('cancel-target') + '_template';

        if (form.data('confirmation_received')) {
            return true;
        } else {
            self.showConfirmation(form, template);
            return false;
        }
    });
};

FileIssue.prototype.showConfirmation = function(form, templateId) {
    var self = this;

    AS.openCustomModal("confirmFileIssueCancelModal",
                       $('#' + templateId).data("title"),
                       AS.renderTemplate(templateId),
                       null,
                       {},
                       form.find('.btn'));

    $(".confirmButton", "#confirmFileIssueCancelModal").click(function() {
        $(".btn", "#confirmFileIssueCancelModal").attr("disabled", "disabled");
        form.data('confirmation_received', true).submit();
    });
};


$(document).ready(function() {
    window.file_issue = new FileIssue();
});
