function Transfers() {
    var self = this;

    this.setupNavigation();

    $(document).on('submit', '.transfers-toolbar form', function () {
        var form = $(this);

        var template = (form.attr('id') == 'approve_transfer_proposal') ?
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

Transfers.prototype.setupNavigation = function() {
    var $browseActions = $($('#MAPTransferBrowseActions').html());

    $browseActions.appendTo('.repository-header .browse-container ul:first');
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
