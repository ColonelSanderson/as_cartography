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
	this.editingFlag = !!value;

	if (this.editingFlag) {
	    this.section.find('.quote-button').attr('disabled', true);
	} else {
	    this.section.find('.quote-button').removeAttr('disabled');
	}
    }
    return this.editingFlag;
}

QuoteEditor.prototype.edited = function() {
    this.section.find('input[name=quote_json]').val(JSON.stringify(this.json));

    this.updateCosts();

    this.section.find('.quote-issue-button').hide();
    this.section.find('.quote-regenerate-button').hide();
    this.section.find('.quote-revert-button').show();
    this.section.find('.quote-save-button').show();

    this.message("Value set. Click 'Save Quote' to save.");
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
    this.quote.find('tr').each(function(row) {
	    if (typeof($(this).data('index')) !== 'undefined') {
		var cents = parseInt($(this).find('td[data-field=charge_per_unit_cents]').data('value'));
		var q = parseInt($(this).find('td[data-field=quantity]').data('value'));
		var cost = cents * q;
		total += cost;
		$(this).find('td.quote-cost').html(self.centsToDollars(cost));
	    }
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
	str = '$' + value;
	return str.slice(0, str.length - 2) + '.' + str.slice(str.length - 2);
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

QuoteEditor.prototype.save = function(cell, value) {
    cell.addClass('edited-quote-field');
    var val = this.dataFor(cell.data('field'), value);
    cell.data('value', val);

    var ix = parseInt(cell.parent().data('index'));
    this.json['line_items'][ix][cell.data('field')] = val;
}

QuoteEditor.prototype.bindEvents = function() {
    var self = this;

    self.quote.on('mouseenter', function () {
	    self.message('Click a cell to edit. Return to set, escape to exit');
	});

    self.quote.find('td.editable-quote-field').on('click', function () {
	if (self.editing()) {
	    return;
	}
	self.editing(true);
	
        var inputElt = self.inputFor($(this).data('field'));
        inputElt.val(self.editFor($(this).data('field'), $(this).data('value')));
        inputElt.css('width', '100%');

	inputElt.keypress(function( event ) {
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
			    self.edited();
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
