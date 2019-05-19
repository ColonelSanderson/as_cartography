function FileIssue() {
    var self = this;

    this.setupNavigation();
};


FileIssue.prototype.setupNavigation = function() {
    var $browseActions = $($('#MAPFileIssueBrowseActions').html());
    $browseActions.appendTo('.repository-header .browse-container ul:first');
};

$(document).ready(function() {
    window.file_issue = new FileIssue();
});
