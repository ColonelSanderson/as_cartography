function QuoteEditor(opts) {
    this.quote = $(opts.quote);
    this.section = this.quote.parent();
    this.editing(false);
    this.clearMessage();
    this.json = JSON.parse(this.section.find('.quote-json').text());
    this.bindEvents();
}

QuoteEditor.prototype.editing = function(value) {
    if (typeof(value) != 'undefined') {
	this.editingElt = value;

	if (this.editingElt) {
	    this.section.find('.quote-button').attr('disabled', true);
	} else {
	    this.section.find('.quote-button').removeAttr('disabled');
	}
    }
    return this.editingElt;
}

QuoteEditor.prototype.edited = function(msg) {
    this.section.find('input[name=quote_json]').val(JSON.stringify(this.json));

    this.updateCosts();

    this.section.find('.quote-issue-button').hide();
    this.section.find('.quote-regenerate-button').hide();
    this.section.find('.quote-revert-button').show();
    this.section.find('.quote-save-button').show();

    this.message(msg + ". Click 'Save Quote' to save.");
}

QuoteEditor.prototype.message = function(msg, sticky) {
    var self = this;

    this.section.find('.quote-message').html(msg).show();

    if (!sticky) {
	setTimeout(function() {
	    if (self.section.find('.quote-message').html() == msg) {
		self.clearMessage();
	    }
	}, 3000);
    }
}

QuoteEditor.prototype.clearMessage = function(msg) {
    this.section.find('.quote-message').fadeOut();
}

QuoteEditor.prototype.centsToDollars = function(cents) {
    var str = cents.toString();
    str = '$' + str.padStart(3, '0');
    return str.slice(0, str.length - 2) + '.' + str.slice(str.length - 2);
}

QuoteEditor.prototype.updateCosts = function() {
    var self = this;
    var total = 0;
    this.lines().each(function(row) {
        var cents = parseInt($(this).find('td[data-field=charge_per_unit_cents]').data('value'));
	var q = parseInt($(this).find('td[data-field=quantity]').data('value'));
	var cost = cents * q;
	total += cost;
	$(this).find('td.quote-cost').html(self.centsToDollars(cost));
    });

    this.quote.find('.quote-total').html(self.centsToDollars(total));
}

QuoteEditor.prototype.inputFor = function(field) {
    return this.section.find('.quote-form-elements').find('[name=' + field + ']').clone();
}

QuoteEditor.prototype.displayFor = function(field, value) {
    elt = this.section.find('.quote-form-elements').find('[name=' + field + ']');

    if (elt.is('select')) {
	return elt.find('option[value=' + value + ']').text();
    }

    if (elt.attr('name').endsWith('_cents')) {
	return this.centsToDollars(value);
    }

    return value;
}

QuoteEditor.prototype.editFor = function(field, value) {
    elt = this.section.find('.quote-form-elements').find('[name=' + field + ']');

    if (elt.attr('name').endsWith('_cents')) {
	return this.centsToDollars(value);
    }

    return value;
}

QuoteEditor.prototype.dataFor = function(field, value) {
    elt = this.section.find('.quote-form-elements').find('[name=' + field + ']');

    if (elt.attr('name').endsWith('_cents')) {
	return parseInt(value.replace(/\D/g, ''));
    }

    if (elt.attr('name') == 'quantity') {
	return parseInt(value);
    }

    return value;
}

QuoteEditor.prototype.validate = function(field, value) {
    var valid = true;

    elt = this.section.find('.quote-form-elements').find('[name=' + field + ']');

    if (field == 'description') {
	if (value.length == 0) {
	    valid = false;
	    this.message('Cannot be empty');
	} else if (value.length > 255) {
	    valid = false;
	    this.message('Too long');
	}
    }

    if (elt.attr('name').endsWith('_cents')) {
	valid = !!value.match(/^\$\d+\.\d\d$/);
	if (!valid) {
	    this.message('Cost must be in the form: $123.45', true);
	}
    }

    if (elt.attr('name') == 'quantity') {
	valid = value.length > 0 && !!parseInt(value + 1) && !value.match(/\D/); // add one bc zero is false
	if (!valid) {
	    this.message('Quantity must be an integer', true);
	}
    }

    return valid;
}

QuoteEditor.prototype.lines = function() {
    return this.quote.find('tr.quote-line:not(.quote-line-flagged-for-delete)');
}

QuoteEditor.prototype.save = function(cell, value) {
    cell.addClass('edited-quote-field');
    var val = this.dataFor(cell.data('field'), value);
    cell.data('value', val);

    var ix = this.lines().index(cell.parent());

    this.json['line_items'][ix][cell.data('field')] = val;
}

QuoteEditor.prototype.deleteLine = function(line) {
    this.json['line_items'].splice(this.lines().index(line), 1);

    line.addClass('quote-line-flagged-for-delete');
    line.find('td').removeClass('editable-quote-field');

    this.edited('Line flagged for deletion');
}

QuoteEditor.prototype.addLine = function(line) {
    var line_obj = {};

    line.find('td.editable-quote-field').each(function() {
	    line_obj[$(this).data('field')] = $(this).data('value');
    });

    this.json['line_items'].push(line_obj);

    this.lines().last().after(line);

    this.edited('Line added');
}

QuoteEditor.prototype.bindEvents = function() {
    var self = this;

    self.quote.on('mouseenter', function () {
	    self.message('Click a cell to edit. Return to set, escape to exit');
	});

    self.quote.find('tr').on('mouseenter', function () {
	    if (!$(this).hasClass('quote-line-flagged-for-delete')) {
	        $(this).find('.quote-line-delete-button').show();
	    }
	});

    self.quote.find('tr').on('mouseleave', function () {
	    $(this).find('.quote-line-delete-button').hide();
	});

    self.quote.find('.quote-line-delete-button').on('click', function () {
	    self.deleteLine($(this).closest('tr'));
	});

    self.quote.find('.quote-line-add-button').on('click', function () {
	    self.addLine(self.section.find('.quote-new-line').find('tr').clone(true, true));
	});

    self.section.find('td.editable-quote-field').on('click', function () {
	if (self.editing()) {
	    if (self.editing().parent()[0] == $(this)[0]) {
		return;
	    }
	    var evt = jQuery.Event('keypress');
	    evt.which = 13;  // return
	    self.editing().trigger(evt);
	}

        var inputElt = self.inputFor($(this).data('field'));
        inputElt.val(self.editFor($(this).data('field'), $(this).data('value')));
        inputElt.css('width', '100%');

	self.editing(inputElt);
	
	inputElt.keypress(function( event ) {
		if ( event.which == 9 ) {  // tab
		    event.preventDefault();
		    console.log('weeeee');
		}

		if ( event.which == 27 ) {  // escape
		    event.preventDefault();
		    $(this).parent().html(self.displayFor($(this).parent().data('field'), $(this).parent().data('value')));
		    self.editing(false);
		    self.message('No change');
		}
		if ( event.which == 13 ) {  // return
		    event.preventDefault();
		    var cell = $(this).parent();
		    if (self.validate(cell.data('field'), $(this).val())) {
			if (cell.data('value') != self.dataFor(cell.data('field'), $(this).val())) {
			    self.save(cell, $(this).val());
			    self.edited('Value set');
			}
			cell.html(self.displayFor(cell.data('field'), cell.data('value')));
			self.editing(false);
		    }
		}
	    });

        $(this).html(inputElt);
	inputElt.focus();
	inputElt.select();
    });
};
