function FileIssue() {
    var self = this;

    this.setupNavigation();
    this.setupApprovalConfirmation();
    this.setupRepresentationListForm();
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

FileIssue.prototype.setupRepresentationListForm = function() {
    var $table = $('#requested_representations table');

    function toggleAll(event) {
        var checked = $(event.currentTarget).is(':checked');
        $table.find('tbody :checkbox').each(function() {
            $(this).prop('checked', checked);
            $(this).trigger('change');
        });
    }

    function disableActions() {
        $table.closest('section').find('.btn-group .btn').addClass('disabled');
    }

    function enableActions() {
        $table.closest('section').find('.btn-group .btn').removeClass('disabled');
    }

    function showDispatchModal() {
        var $modal = AS.openCustomModal("dispatchModal",
                        $('#requested_representations_dispatch_template').data("title"),
                        AS.renderTemplate('requested_representations_dispatch_template'),
                        null,
                        {},
                        $(this));

        $(".confirmButton", $modal).click(function() {
            var dispatchDate = $("#dispatch_date", $modal).val();
            var dispatchedBy = $("#dispatched_by", $modal).val();
            var expiryDate = $("#expiry_date", $modal).val();

            $table.find('tbody :checkbox:checked').each(function() {
                var $tr = $(this).closest('tr');
                $tr.find(':input[name*=dispatch_date]').val(dispatchDate);
                $tr.find(':input[name*=dispatched_by]').val(dispatchedBy);
                $tr.find(':input[name*=expiry_date]').val(expiryDate);
                $modal.modal('hide');
            });
        });
    }

    function showReceiveModal() {
        var $modal = AS.openCustomModal("receiveModal",
            $('#requested_representations_receive_template').data("title"),
            AS.renderTemplate('requested_representations_receive_template'),
            null,
            {},
            $(this));

        $(".confirmButton", $modal).click(function() {
            var returnedDate = $("#returned_date", $modal).val();
            var receivedBy= $("#received_by", $modal).val();

            $table.find('tbody :checkbox:checked').each(function() {
                var $tr = $(this).closest('tr');
                $tr.find(':input[name*=returned_date]').val(returnedDate);
                $tr.find(':input[name*=received_by]').val(receivedBy);
                $modal.modal('hide');
            });
        });
    }

    if ($table.length > 0) {
        $table.find('thead :checkbox').on('click', toggleAll);
        $table.find('tbody :checkbox').on('change', function(event) {
            if ($(event.currentTarget).is(':checked')) {
                $(this).closest('tr').addClass('info');
            } else {
                $(this).closest('tr').removeClass('info');
            }
            if ($table.find('tbody :checkbox:checked').length > 0) {
                enableActions();
            } else {
                disableActions();
            }
        });
        $table.find('tbody td').on('click', function(event) {
            if ($(event.target).is('td')) {
                var $checkbox = $(this).closest('tr').find(':checkbox');
                $checkbox.prop('checked', !$checkbox.is(':checked'));
                $checkbox.trigger('change');
            }
        });

        $('#requested_representations #dispatch').on('click', showDispatchModal);
        $('#requested_representations #receive').on('click', showReceiveModal);
    }
};


$(document).ready(function() {
    window.file_issue = new FileIssue();
});
