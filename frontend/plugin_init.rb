ArchivesSpace::Application.extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

Rails.application.config.after_initialize do
  Plugins.add_facet_group_i18n("controlling_record_u_sstr",
                               proc {|facet| "search_results.controlling_record.current" })

  # Eager load all JSON schemas
  Dir.glob(File.join(File.dirname(__FILE__), "..", "schemas", "*.rb")).each do |schema|
    next if schema.end_with?('_ext.rb')
    JSONModel(File.basename(schema, ".rb").intern)
  end

  Plugins.register_plugin_section(
    Plugins::PluginReadonlySearch.new(
      'as_cartography',
      'file_issues',
      ['digital_representation'],
      {
        filter_term_proc: proc { |record| { "file_issue_item_uri_u_sstr" => record.uri }.to_json },
        heading_text: I18n.t("file_issue._plural"),
        sidebar_label: "N/A",
      }
    )
  )

  class AlwaysReadOnlySection < Plugins::AbstractPluginSection
    def render_readonly(view_context, record, form_context)
      view_context.render_aspace_partial(
        :partial => @erb_template,
        :locals => {
          :record => record,
          :heading_text => @heading_text,
          :section_id => @section_id ? @section_id : build_section_id(form_context.obj['jsonmodel_type']),
          :form => form_context,
        }
      )
    end

    def render_edit(view_context, record, form_context)
      view_context.readonly_context record['jsonmodel_type'], record do |readonly_context|
        render_readonly(view_context, record, readonly_context)
      end
    end

    def supports?(record, mode)
      return false unless @jsonmodel_types.include?(record['jsonmodel_type'])
      # don't show on forms for new records 
      return false if record['uri'].nil? && record['existing_ref'].nil?

      super
    end

    private

    def parse_opts(opts)
      super

      @show_on_edit = true
      @show_on_readonly = true
      @heading_text = opts.fetch(:heading_text)
      @erb_template = opts.fetch(:erb_template)
    end
  end

  Plugins.register_plugin_section(
    AlwaysReadOnlySection.new(
      'as_cartography',
      'delegates',
      ['agent_corporate_entity'],
      {
        erb_template: 'agents/agency_delegates',
        heading_text:  I18n.t('agency_delegates._plural'),
        section_id: "agency_delegates",
        sidebar_label: I18n.t('agency_delegates._plural'),
      }
    )
  )

  # register models for qsa_ids
  require_relative '../common/qsa_id_registrations'
end
