module ResourceTransfers
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      transfers = ArchivalObject.filter(:root_record_id => objs.map{|obj| obj[:id]})
                                .filter(Sequel.~(:transfer_id => nil))
                                .select(:root_record_id, :transfer_id).distinct.all

      objs.zip(jsons).each do |obj, json|
        json['transfers'] = transfers.select{|tr| tr[:root_record_id] == obj[:id]}
                                     .map{|tr| {'ref' => JSONModel(:transfer).uri_for(tr[:transfer_id])}}
      end

      jsons
    end
  end
end
