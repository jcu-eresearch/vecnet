# -*- coding: utf-8 -*-
# Copyright © 2012 The Pennsylvania State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# -*- encoding : utf-8 -*-
require 'blacklight/catalog'
require 'blacklight_advanced_search'

# bl_advanced_search 1.2.4 is doing unitialized constant on these because we're calling ParseBasicQ directly
require 'parslet'
require 'parsing_nesting/tree'
require 'blacklight/join_solr_params'

class CatalogController < ApplicationController
  include Blacklight::Catalog
  # Extend Blacklight::Catalog with Hydra behaviors (primarily editing).
  include Hydra::Controller::ControllerBehavior
  include BlacklightAdvancedSearch::ParseBasicQ
  include BlacklightAdvancedSearch::Controller
  include JoinSolrParams

  with_themed_layout 'catalog'

  # These before_filters apply the hydra access controls
  before_filter :enforce_show_permissions, :only=>:show
  # This applies appropriate access controls to all solr queries
  CatalogController.solr_search_params_logic += [:add_access_controls_to_solr_params]
  # This filters out objects that you want to exclude from search results, like FileAssets
  CatalogController.solr_search_params_logic += [:exclude_unwanted_models]

  skip_before_filter :default_html_head

  def index
    #require 'debugger'; debugger; true;
    super
  end

  def subject_facet
    @pagination = get_facet_pagination(params[:id], params)
    (@response, @document_list) = get_search_results
    respond_to do |format|
      format.html
      format.js { render :layout => false }
    end
  end

  def location_facet
    @pagination = get_facet_pagination(params[:id], params)
    (@response, @document_list) = get_search_results
    respond_to do |format|
      format.html
      format.js { render :layout => false }
    end
  end

  def species_facet
    @pagination = get_facet_pagination(params[:id], params)
    (@response, @document_list) = get_search_results
    respond_to do |format|
      format.html
      format.js { render :layout => false }
    end
  end

  def recent
    if user_signed_in?
      # grab other people's documents
      (resp, doc_list) = get_search_results(:q =>'{!lucene q.op=AND df=depositor_t}-'+current_user.user_key, :sort=>"system_create_dt desc", :rows=>3)
    else
      # grab any documents we do not know who you are
      (resp, doc_list) = get_search_results(:q =>'', :sort=>"system_create_dt desc", :rows=>3)
    end
    @recent_documents = doc_list[0..3]
  end

  def recent_me
    if user_signed_in?
      (resp, doc_list) = get_search_results(:q =>'{!lucene q.op=AND df=depositor_t}'+current_user.user_key, :sort=>"system_create_dt desc", :rows=>3)
      @recent_user_documents = doc_list[0..3]
    else
       @recent_user_documents = nil
    end
  end

  configure_blacklight do |config|
    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    config.default_solr_params = {
      :qt => "search",
      :rows => 10
    }

    # name of Solr request handler, leave unset to use the same one as your Blacklight.config[:default_qt]
    #config.advanced_search= {
    #    :qt => 'search'
    #}

    # solr field configuration for search results/index views
    config.index.show_link = "desc_metadata__title_display"
    config.index.record_display_type = "id"

    # solr field configuration for document/show views
    config.show.html_title = "desc_metadata__title_display"
    config.show.heading = "desc_metadata__title_display"
    config.show.display_type = "has_model_s"

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    config.add_facet_field "desc_metadata__resource_type_facet", :label => "Resource Type", :limit => 5, :sort => 'index'
    config.add_facet_field "desc_metadata__contributor_facet", :label => "Contributor", :limit => 5
    config.add_facet_field "desc_metadata__creator_facet", :label => "Author", :limit => 5, :sort => 'index'
    config.add_facet_field "desc_metadata__tag_facet", :label => "Keyword", :limit => 5, :sort => 'index'
    config.add_facet_field "desc_metadata__publisher_facet", :label => "Publisher", :limit => 5, :sort => 'index'
    config.add_facet_field "desc_metadata__source_facet", :label => "Journal", :limit =>5, :sort=> 'index'
    config.add_facet_field 'hierarchy_facet', :label => 'Subject Hierarchy', :partial => 'blacklight/hierarchy/facet_hierarchy', :limit => 100000, :show=> false, :sort => 'index'
    config.add_facet_field 'location_hierarchy_facet', :label => 'Location Hierarchy', :partial => 'blacklight/hierarchy/facet_hierarchy', :limit => 100000, :show=> false, :sort => 'index'
    config.add_facet_field 'species_hierarchy_facet', :label => 'Species Hierarchy', :partial => 'blacklight/hierarchy/facet_hierarchy', :limit => 100000, :show=> false, :sort => 'index'
    config.facet_display = {
        :hierarchy => {
            'hierarchy' => [nil],
            'location_hierarchy' => [nil],
            'species_hierarchy' => [nil]
        }
    }

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    #config.add_index_field 'desc_metadata__title_display', :helper_method => :get_first_title, :show=>false
    config.add_index_field "desc_metadata__creator_display", :label => "Author"
    config.add_index_field "desc_metadata__bibliographic_citation_display", :label => "Bibliographic Citation"
    config.add_index_field "desc_metadata__contributor_display", :label => "Contributor"
    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field "desc_metadata__title_display", :label => "Title", :helper_method => :get_first_title
    config.add_show_field "desc_metadata__description_display", :label => "Description"
    config.add_show_field "desc_metadata__tag_display", :label => "Keyword"
    config.add_show_field "desc_metadata__subject_display", :label => "Subject"
    config.add_show_field "desc_metadata__creator_display", :label => "Creator"
    config.add_show_field "desc_metadata__contributor_display", :label => "Contributor"
    config.add_show_field "desc_metadata__publisher_display", :label => "Publisher"
    config.add_show_field "desc_metadata__based_near_display", :label => "Location"
    config.add_show_field "desc_metadata__language_display", :label => "Language"
    config.add_show_field "desc_metadata__date_uploaded_display", :label => "Date Uploaded"
    config.add_show_field "desc_metadata__date_modified_display", :label => "Date Modified"
    config.add_show_field "desc_metadata__date_created_display", :label => "Date Created"
    config.add_show_field "desc_metadata__rights_display", :label => "Rights"
    config.add_show_field "desc_metadata__resource_type_display", :label => "Resource Type"
    config.add_show_field "desc_metadata__file_format_display", :label => "File Format"
    config.add_show_field "desc_metadata__identifier_display", :label => "Identifier"

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.
    #
    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.
    config.add_search_field 'all_fields', :label => 'All Fields', :include_in_advanced_search => false


    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.
    # creator, title, description, publisher, date_created,
    # subject, language, resource_type, format, identifier, based_near,
    config.add_search_field('contributor') do |field|
      field.include_in_advanced_search = false
      # solr_parameters hash are sent to Solr as ordinary url query params.
      field.solr_parameters = { :"spellcheck.dictionary" => "contributor" }

      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      field.solr_local_parameters = {
        :qf => "desc_metadata__contributor_t",
        :pf => "desc_metadata__contributor_t"
      }
    end

    config.add_search_field('creator') do |field|
      field.solr_parameters = { :"spellcheck.dictionary" => "creator" }
      field.include_in_advanced_search = false
      field.solr_local_parameters = {
        :qf => "desc_metadata__creator_t",
        :pf => "desc_metadata__creator_t"
      }
    end

    config.add_search_field('title') do |field|
      field.solr_parameters = {
        :"spellcheck.dictionary" => "title"
      }
      field.include_in_advanced_search = false
      field.solr_local_parameters = {
        :qf => "$title_qf",
        :pf => "$title_pf"
      }
    end

    config.add_search_field('description') do |field|
      field.include_in_advanced_search = false
      field.label = "Abstract or Summary"
      field.solr_parameters = {
        :"spellcheck.dictionary" => "description"
      }
      field.solr_local_parameters = {
        :qf => "desc_metadata__description_t",
        :pf => "desc_metadata__description_t"
      }
    end

    config.add_search_field('publisher') do |field|
      field.include_in_advanced_search = false
      field.solr_parameters = {
        :"spellcheck.dictionary" => "publisher"
      }
      field.solr_local_parameters = {
        :qf => "desc_metadata__publisher_t",
        :pf => "desc_metadata__publisher_t"
      }
    end

    config.add_search_field('date_created') do |field|
      field.include_in_advanced_search = false
      field.solr_parameters = {
        :"spellcheck.dictionary" => "date_created"
      }
      field.solr_local_parameters = {
        :qf => "desc_metadata__date_created_t",
        :pf => "desc_metadata__date_created_t"
      }
    end

    config.add_search_field('subject') do |field|
      field.include_in_advanced_search = false
      field.solr_parameters = {
        :"spellcheck.dictionary" => "subject"
      }
      field.solr_local_parameters = {
        :qf => "desc_metadata__subject_t",
        :pf => "desc_metadata__subject_t"
      }
    end

    config.add_search_field('language') do |field|
      field.include_in_advanced_search = false
      field.solr_parameters = {
        :"spellcheck.dictionary" => "language"
      }
      field.solr_local_parameters = {
        :qf => "desc_metadata__language_t",
        :pf => "desc_metadata__language_t"
      }
    end

    config.add_search_field('resource_type') do |field|
      field.include_in_advanced_search = false
      field.solr_parameters = {
        :"spellcheck.dictionary" => "resource_type"
      }
      field.solr_local_parameters = {
        :qf => "desc_metadata__resource_type_t",
        :pf => "desc_metadata__resource_type_t"
      }
    end

    config.add_search_field('citation') do |field|
      field.include_in_simple_select = false
      field.solr_local_parameters = {
          :qf => "$qf_citation",
          :pf => "$pf_citation"
      }
    end

    config.add_search_field('full_text_citation') do |field|
      field.include_in_simple_select = false
      field.include_in_advanced_search = false
      field.qt = 'fulltext'
      field.solr_local_parameters = {
          :qf => "$qf_full_text_citation",
          :pf => "$pf_full_text_citation"
      }
    end

    config.add_search_field('format') do |field|
      field.include_in_advanced_search = false
      field.solr_parameters = {
        :"spellcheck.dictionary" => "format"
      }
      field.solr_local_parameters = {
        :qf => "file_format_t",
        :pf => "file_format_t"
      }
    end

    config.add_search_field('identifier') do |field|
      field.include_in_advanced_search = false
      field.solr_parameters = {
        :"spellcheck.dictionary" => "identifier"
      }
      field.solr_local_parameters = {
        :qf => "id_t",
        :pf => "id_t"
      }
    end

    config.add_search_field('based_near') do |field|
      field.include_in_advanced_search = false
      field.label = "Location"
      field.solr_parameters = {
        :"spellcheck.dictionary" => "based_near"
      }
      field.solr_local_parameters = {
        :qf => "desc_metadata__based_near_t",
        :pf => "desc_metadata__based_near_t"
      }
    end

    config.add_search_field('tag') do |field|
      field.include_in_advanced_search = false
      field.solr_parameters = {
        :"spellcheck.dictionary" => "tag"
      }
      field.solr_local_parameters = {
        :qf => "desc_metadata__tag_t",
        :pf => "desc_metadata__tag_t"
      }
    end

    config.add_search_field('depositor') do |field|
      field.include_in_advanced_search = false
      field.solr_local_parameters = {
        :qf => "depositor_t",
        :pf => "depositor_t"
      }
    end

    config.add_search_field('rights') do |field|
      field.include_in_advanced_search = false
      field.solr_local_parameters = {
        :qf => "desc_metadata__rights_t",
        :pf => "desc_metadata__rights_t"
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    # label is key, solr field is value
    config.add_sort_field 'score desc, pub_date_sort desc, title_sort asc', :label => 'Relevancy'
    config.add_sort_field 'pub_date_sort desc', :label => "Publish Date \u25BC"
    config.add_sort_field 'pub_date_sort asc', :label => "Publish Date \u25B2"
    config.add_sort_field 'title_alpha_sort asc', :label => "Title"
    config.add_sort_field 'desc_metadata__date_uploaded_dt desc', :label => "Date Uploaded \u25BC"
    config.add_sort_field 'desc_metadata__date_uploaded_dt asc', :label => "Date Uploaded \u25B2"
    config.add_sort_field 'desc_metadata__date_modified_dt desc', :label => "Date Modified \u25BC"
    config.add_sort_field 'desc_metadata__date_modified_dt asc', :label => "Date Modified \u25B2"

    #config.add_sort_field 'desc_metadata__based_near_t asc', :label => "Location \u25B2"
    #config.add_sort_field 'desc_metadata__creator_t desc', :label => "Creator \u25BC"
    #config.add_sort_field 'desc_metadata__creator_t asc', :label => "Creator \u25B2"

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5
  end

  protected

  def add_access_controls_to_solr_params(solr_parameters, user_parameters)
    apply_gated_discovery(solr_parameters, user_parameters) unless check_permission?
  end

  def check_permission?
    return current_user && current_user.admin?
  end

  def exclude_unwanted_models(solr_parameters, user_parameters)
    super
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "-has_model_s:\"info:fedora/afmodel:Collection\""
    solr_parameters[:fq] << "-has_model_s:\"info:fedora/afmodel:Batch\""
    solr_parameters[:fq] << "-has_model_s:\"info:fedora/afmodel:CitationFile\""
    return solr_parameters
  end



  private

  def show_site_search?
    false
  end
end
