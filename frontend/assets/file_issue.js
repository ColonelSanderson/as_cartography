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
    var $table = $('#file_issue_requested_representations_ table');

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

    function clearTokens(linker) {
	// BITEME: this method adapted from linker.js
        var $tokenList = $(".token-input-list", linker.parent());
        for (var i=0; i < linker.tokenInput("get").length; i++) {
	    var id_to_remove = linker.tokenInput("get")[i].id.replace(/\//g,"_");
	    $("#"+id_to_remove + " :input", $tokenList).remove();
        }
        linker.tokenInput("clear");
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
            var dispatchedBy = JSON.parse($("input[name*=dispatched_by][name*=_resolved]", $modal).val());
            var expiryDate = $("#expiry_date", $modal).val();

            $table.find('tbody :checkbox:checked[id$=_id_]').each(function() {
                var $tr = $(this).closest('tr');
                $tr.find(':input[name*=dispatch_date]').val(dispatchDate).trigger('change');
		clearTokens($tr.find(':input.linker[data-path*=dispatched_by]'));
		$tr.find(':input.linker[data-path*=dispatched_by]').tokenInput('add',
									       {
										   id: dispatchedBy['uri'],
										   name: dispatchedBy['display_string'],
										   json: dispatchedBy
									       });


                $tr.find(':input[name*=expiry_date]').val(expiryDate).trigger('change');
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
            var receivedBy = JSON.parse($("input[name*=received_by][name*=_resolved]", $modal).val());

            $table.find('tbody :checkbox:checked[id$=_id_]').each(function() {
                var $tr = $(this).closest('tr');
                // Only change those that haven't been marked as "Not returned"
                if ($tr.find(':checkbox[name*=not_returned]').is(':not(:checked)')) {
                    $tr.find(':input[name*=returned_date]').val(returnedDate).trigger('change');
		    clearTokens($tr.find(':input.linker[data-path*=received_by]'));
		    $tr.find(':input.linker[data-path*=received_by]').tokenInput('add',
										 {
									             id: receivedBy['uri'],
									             name: receivedBy['display_string'],
									             json: receivedBy
									         });
                }
                $modal.modal('hide');
            });
        });
    }

    function toggleNotReturnedFields($tr) {
        var $receivedDate = $tr.find(':input[id$=_returned_date_]');
        var $notReturned = $tr.find(':checkbox[id$=_not_returned_]');
        if ($receivedDate.val() && $receivedDate.val().trim() != '') {
            $tr.find('.not-returned-fields').hide();
            $tr.find('.not-returned-fields :input').prop('disabled', true);
        } else if ($notReturned.is(':checked')) {
            $tr.find('.returned-fields').hide();
            $tr.find('.returned-fields :input').prop('disabled', true);
            $tr.find('.not-returned-note').show();
            $tr.find('.not-returned-fields :input').prop('disabled', false);
        } else {
            $tr.find('.not-returned-fields').show();
            $tr.find('.not-returned-fields :input').prop('disabled', false);
            $tr.find('.returned-fields').show();
            $tr.find('.returned-fields :input').prop('disabled', false);
            $tr.find('.not-returned-note').hide();
            $tr.find('.not-returned-note :input').prop('disabled', true);
        }
    }

    function setupNotReturnedFields() {
        $table.find('tbody tr').each(function() {
            toggleNotReturnedFields($(this));
        });

        $table.find('tbody tr .not-returned-fields :input, tbody tr .returned-fields :input').on('change', function() {
            toggleNotReturnedFields($(this).closest('tr'));
        });
    }

    if ($table.length > 0) {
        $table.find('thead :checkbox').on('click', toggleAll);
        $table.find('tbody :checkbox[id$=_id_]').on('change', function(event) {
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
                var $checkbox = $(this).closest('tr').find(':checkbox[id$=_id_]');
                $checkbox.prop('checked', !$checkbox.is(':checked'));
                $checkbox.trigger('change');
            } else {
                event.stopImmediatePropagation();
            }
        });

        $('#file_issue_requested_representations_ #dispatch').on('click', showDispatchModal);
        $('#file_issue_requested_representations_ #receive').on('click', showReceiveModal);

        setupNotReturnedFields();
    }
};


$(document).ready(function() {
    window.file_issue = new FileIssue();
});
