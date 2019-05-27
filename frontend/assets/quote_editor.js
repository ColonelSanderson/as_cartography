function QuoteEditor(opts) {
    this.elt = $(opts.el);
    this.editing = false;
    this.clearMessage();
    this.json = JSON.parse(this.elt.parent().find('.quote-json').text());
    this.bindEvents();
}

QuoteEditor.prototype.edited = function() {
    this.elt.parent().find('input[name=quote_json]').val(JSON.stringify(this.json));

    this.updateCosts();

    this.elt.parent().find('.quote-issue-button').hide();
    this.elt.parent().find('.quote-revert-button').show();
    this.elt.parent().find('.quote-save-button').show();
}

QuoteEditor.prototype.message = function(msg, clear) {
    var self = this;

    this.elt.parent().find('.quote-message').html(msg).show();

    if (clear) {
	setTimeout(function() {
	    if (self.elt.parent().find('.quote-message').html() == msg) {
		self.clearMessage();
	    }
	}, 3000);
    }
}

QuoteEditor.prototype.clearMessage = function(msg) {
    this.elt.parent().find('.quote-message').fadeOut();
}

QuoteEditor.prototype.centsToDollars = function(cents) {
    var str = cents.toString();
    str = '$' + str.padStart(3, '0');
    return str.slice(0, str.length - 2) + '.' + str.slice(str.length - 2);
}

QuoteEditor.prototype.updateCosts = function() {
    var self = this;
    var total = 0;
    this.elt.find('tr').each(function(row) {
	    if (typeof($(this).data('index')) !== 'undefined') {
		var cents = parseInt($(this).find('td[data-field=charge_per_unit_cents]').data('value'));
		var q = parseInt($(this).find('td[data-field=quantity]').data('value'));
		var cost = cents * q;
		total += cost;
		$(this).find('td.quote-cost').html(self.centsToDollars(cost));
	    }
	});

    this.elt.find('.quote-total').html(self.centsToDollars(total));
}

QuoteEditor.prototype.inputFor = function(field) {
    return this.elt.parent().find('.quote-form-elements').find('[name=' + field + ']').clone();
}

QuoteEditor.prototype.displayFor = function(field, value) {
    elt = this.elt.parent().find('.quote-form-elements').find('[name=' + field + ']');

    if (elt.is('select')) {
	return elt.find('option[value=' + value + ']').text();
    }

    if (elt.attr('name').endsWith('_cents')) {
	return this.centsToDollars(value);
    }

    return value;
}

QuoteEditor.prototype.editFor = function(field, value) {
    elt = this.elt.parent().find('.quote-form-elements').find('[name=' + field + ']');

    if (elt.attr('name').endsWith('_cents')) {
	str = '$' + value;
	return str.slice(0, str.length - 2) + '.' + str.slice(str.length - 2);
    }

    return value;
}

QuoteEditor.prototype.dataFor = function(field, value) {
    elt = this.elt.parent().find('.quote-form-elements').find('[name=' + field + ']');

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

    elt = this.elt.parent().find('.quote-form-elements').find('[name=' + field + ']');

    if (elt.attr('name').endsWith('_cents')) {
	valid = !!value.match(/^\$\d+\.\d\d$/);
	if (valid) {
	    this.clearMessage();
	} else {
	    this.message('Cost must be in the form: $123.45');
	}
    }

    if (elt.attr('name') == 'quantity') {
	valid = value.length > 0 && !!parseInt(value + 1) && !value.match(/\D/); // add one bc zero is false
	if (valid) {
	    this.clearMessage();
	} else {
	    this.message('Quantity must be an integer');
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

    self.elt.on('mouseenter', function () {
	    self.message('Click a cell to edit. Return to set, escape to exit', true);
	});

    self.elt.find('td.editable-quote-field').on('click', function () {
	if (self.editing) {
	    return;
	}
	self.editing = true;

	
        var inputElt = self.inputFor($(this).data('field'));
        inputElt.val(self.editFor($(this).data('field'), $(this).data('value')));
        inputElt.css('width', '100%');

	inputElt.keypress(function( event ) {
		if ( event.which == 27 ) {
		    event.preventDefault();
		    $(this).parent().html(self.displayFor($(this).parent().data('field'), $(this).parent().data('value')));
		    self.editing = false;
		}
		if ( event.which == 13 ) {
		    event.preventDefault();
		    var cell = $(this).parent();
		    if (self.validate(cell.data('field'), $(this).val())) {
			if (cell.data('value') != self.dataFor(cell.data('field'), $(this).val())) {
			    self.save(cell, $(this).val());
			    self.edited();
			}
			cell.html(self.displayFor(cell.data('field'), cell.data('value')));
			self.editing = false;
		    } else {
			// FIXME
			console.log('BAD');
		    }
		}
	    });

        $(this).html(inputElt);
	inputElt.focus();
	inputElt.select();
    });
};
