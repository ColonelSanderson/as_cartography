function SearchRequest() {
    var self = this;

    this.setupNavigation();
    this.setupApprovalConfirmation();
    this.setupFilesForm();
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

SearchRequest.prototype.setupFilesForm = function() {
    var $section = $('#search_request_files');
    var index = $('#search_request_files').find('tbody tr').length;

    function handleUploadClick(e) {
        e.preventDefault();
        var button = $(this);
        var buttonLabel = button.text();
        var uploadingLabel = button.data('uploading-label');
        var errorLabel = button.data('uploading-error-label');
        var container = button.closest('.form-group');

        var fileInput = $('<input type="file" style="display: none;"></input>');

        var formSubmit = button.closest('form').find(':submit:enabled');

        fileInput.on('change', function () {
            button.prop('disabled', true);
            formSubmit.prop('disabled', true);

            button.text(uploadingLabel);

            var formData = new FormData();
            formData.append('file', this.files[0]);

            $(fileInput).remove();

            var promise = $.ajax({
                type: "POST",
                url: AS.app_prefix('/search_requests/' + $('form#search_request_form').data('id') + '/upload'),
                data: formData,
                processData: false,
                contentType: false,
            });

            promise
                .done(function (data) {
                    index = index + 1;
                    button.prop('disabled', false).text(buttonLabel);
                    formSubmit.prop('disabled', false);
                    $section.find('table tbody').append(AS.renderTemplate('search_request_file_template', {file: data, index: index}));
                })
                .fail(function () {
                    button.removeClass('btn-primary').addClass('btn-danger').text(errorLabel).prop('disabled', false);
                    formSubmit.prop('disabled', false);
                });
        });

        $(document.body).append(fileInput);
        fileInput.click();
    }

    function handleRemoveClick(e) {
        $(this).closest('tr').remove();
    }

    $section.on('click', '#searchRequestFileUpload', handleUploadClick);
    $section.on('click', '.search-request-file-remove', handleRemoveClick);
};


$(document).ready(function() {
    window.search_request = new SearchRequest();
});
