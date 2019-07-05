function Transfers() {
    var self = this;

    this.setupNavigation();
    this.setupApprovalConfirmation();
    this.setupTransferReplaceFile();
    this.setupValidateMetadataButtons();
    this.setupImportJobMonitor();
};

Transfers.prototype.setupValidateMetadataButtons = function() {
    var self = this;

    $(document).on('click', '.validate-metadata-btn', function (event) {
        event.preventDefault();
        var button = $(this);

        if (button.hasClass('has-errors')) {
            AS.openCustomModal("validationErrorsModal",
                               $('#validation_errors').data("title"),
                               AS.renderTemplate('transfer_validation_errors', {
                                   errors: button.data('validation-errors'),
                               }),
                               null,
                               {},
                               button);
            return;
        }

        // Validate this Import
        var fileKey = button.data('file-key');

        button.text(button.data('validating-label'));
        button.attr('disabled', 'disabled');

        $.ajax({
            url: AS.app_prefix("/transfer_files/validate"),
            type: 'GET',
            dataType: 'json',
            data: {
                key: fileKey,
            },
            success: function (validationResult) {
                if (validationResult.valid) {
                    button.removeClass('btn-default').addClass('btn-success');
                    button.text(button.data('valid-label'));
                } else {
                    button.prop('disabled', false);
                    button.removeClass('btn-default').addClass('btn-warning').addClass('has-errors');
                    button.text(button.data('not-valid-label'));
                    button.data('validation-errors', validationResult.errors);
                }
            },
        });

        return false;
    });

    this.resetValidateButtons();

    $(document).on('change', '.file-role', function () {
        self.resetValidateButtons();
    });
};

Transfers.prototype.setupApprovalConfirmation = function() {
    var self = this;

    $(document).on('submit', '.transfers-toolbar form', function () {
        var form = $(this);

        var template = (form.attr('id') === 'approve_transfer_proposal') ?
                       'transfer_confirm_approval_template' :
                       'transfer_confirm_cancel_template';

        if (form.data('confirmation_received')) {
            return true;
        } else {
            self.showConfirmation(form, template);
            return false;
        }
    });
};


Transfers.prototype.resetValidateButtons = function() {
    $('.validate-metadata-btn').each(function () {
        var button = $(this);
        if (button.closest('tr').find('.file-role-cell .file-role').val() == 'IMPORT') {
            button.text(button.data('default-label'));
            button.removeClass('has-errors').removeClass('btn-warning').removeClass('btn-success').addClass('btn-default');
            button.show();
        } else {
            button.hide();
        }
    });
};

Transfers.prototype.setupTransferReplaceFile = function() {
    var self = this;

    $(document).on('click', '.transfer_replace_file', function () {
        var button = $(this);

        AS.openCustomModal("confirmReplaceModal",
                           $('#transfer_replace_file').data("title"),
                           AS.renderTemplate('transfer_replace_file', {
                               key: button.data('key'),
                               filename: button.data('filename'),
                               role: button.data('role'),
                               rowId: button.data('row-id'),
                           }),
                           null,
                           {},
                           button);

        return false;
    });
};

Transfers.prototype.setupNavigation = function() {
    var $browseActions = $($('#MAPTransferBrowseActions').html());

    $browseActions.appendTo('.repository-header .browse-container ul:first');
};

Transfers.prototype.setupImportJobMonitor = function() {
    var job = $('#transfer-import-job');

    if (!job.length) {
	return;
    }

    var status = job.data('status');
    // it's an API uri for the job, convert it to the frontend uri for the status
    var statusUri = '/' + job.data('uri').split('/').slice(3,5).join('/') + '/status';

    if (status == 'queued' || status == 'running') {
     this.checkJobStatus(statusUri);
    }
};

Transfers.prototype.checkJobStatus = function(uri) {
    var self = this;

    setTimeout(function() {
        $.ajax({
            url: AS.app_prefix(uri),
            type: 'GET',
            dataType: 'json',
            data: {
            },
            success: function (result) {
		    var status = result.status;

		    self.updateJobStatus(status);

		    if (status == 'queued' || status == 'running') {
			self.checkJobStatus(uri);
		    }
            },
            error: function () {
		    console.log('Import job monitor failed.');
            },
	});

        }, 3000);

};

Transfers.prototype.updateJobStatus = function(status) {
    var but = $('#transfer-import-button');

    but.text(but.data('import_' + status));

    if (status == 'running' || status == 'queued') {
	but.attr('disabled', 'disabled');
    } else {
	but.removeAttr('disabled');
    }

    var job = $('#transfer-import-job');
    var text = job.find('.token').text();
    newText = text.slice(0, text.lastIndexOf(':') + 2) + status;
    job.find('.token').text(newText);
};

Transfers.prototype.showConfirmation = function(form, templateId) {
    var self = this;

    AS.openCustomModal("confirmTransferModal",
                       $('#' + templateId).data("title"),
                       AS.renderTemplate(templateId),
                       null,
                       {},
                       form.find('.btn'));

    $(".confirmButton", "#confirmTransferModal").click(function() {
        $(".btn", "#confirmTransferModal").attr("disabled", "disabled");
        form.data('confirmation_received', true).submit();
    });
};


$(document).ready(function() {
    window.transfers = new Transfers();
});
