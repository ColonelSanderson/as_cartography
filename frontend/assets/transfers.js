function Transfers() {
    this.setupNavigation();
};

Transfers.prototype.setupNavigation = function() {
    var $browseActions = $($('#MAPTransferBrowseActions').html());

    $browseActions.appendTo('.repository-header .browse-container ul:first');
};


$(document).ready(function() {
    window.transfers = new Transfers();
});
