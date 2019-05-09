// FIXME: i18n

function ConversationWidget(opts) {
    this.elt = $(opts.el);
    this.handle_id = opts.handle_id;

    this.messagesElt = $('<div class="conversation_messages" />');

    this.inputElt = $('<div class="conversation_message_input">' +
                      '<label class="label label-primary" for="conversation_message_textarea">Type your message below</label>' +
                      '<textarea name="conversation_message_textarea" id="conversation_message_textarea"></textarea>' +
                      '<button class="btn btn-primary conversation_message_send">Send message</button>' +
                      '</div>');

    this.sendFailureElt = $('<div style="display: none;" class="conversation_message_send_failed">Your message could not be sent. Please retry!</div>');

    this.elt.append(this.messagesElt);
    this.elt.append(this.inputElt);
    this.elt.append(this.sendFailureElt);

    this.bindEvents();
    this.fetch();

    var self = this;

    this.refreshTimer = setInterval(function () {
        self.fetch();
    }, 10000);
}

ConversationWidget.prototype.bindEvents = function() {
    var self = this;

    this.inputElt.find('.conversation_message_send').on('click', function () {
        self.sendFailureElt.hide();

        var textbox = self.inputElt.find('textarea');
        var message = textbox.val();

        if (message) {
            message = message.trim();
        }

        if (message) {
            self.sendMessage(message,
                             function success() {
                                 textbox.val('');
                                 self.fetch();
                             },
                             function failure()  {
                                 self.sendFailureElt.show();
                             });
        }
    });
};

ConversationWidget.prototype.fetch = function() {
    var self = this;

    $.ajax({
        url: AS.app_prefix("/transfer_conversation"),
        type: 'GET',
        dataType: 'json',
        data: {
            handle_id: self.handle_id
        },
        success: function (conversation) {
            self.messagesElt.empty();

            $(conversation).each(function () {
                self.renderMessage(this);
            });
        },
    });
};


ConversationWidget.prototype.renderMessage = function(message) {
    var container = $('<div class="conversation_message">' +
                      '  <div class="conversation_message_text"></div>' +
                      '  <div class="conversation_message_info">' +
                      '    <span class="conversation_message_sender"></span> - ' +
                      '    <span class="conversation_message_date"></span>' +
                      '  </div>' +
                      '</div>');

    container.find('.conversation_message_text').text(message.message);
    container.find('.conversation_message_sender').text(message.created_by);
    container.find('.conversation_message_date').text(new Date(message.create_time).toLocaleString());

    this.messagesElt.append(container);
};

ConversationWidget.prototype.sendMessage = function (text, success_callback, failure_callback) {
    var self = this;

    $.ajax({
        url: AS.app_prefix("/transfer_conversation_send"),
        type: 'POST',
        dataType: 'json',
        data: {
            handle_id: self.handle_id,
            message: text,
        },
        success: function () {
            success_callback();
        },
        error: function () {
            failure_callback();
        }
    });
};
