require 'datastreams/properties_datastream'
class SeniorThesis < ActiveFedora::Base
  include Hydra::ModelMixins::CommonMetadata
  include Hydra::ModelMixins::RightsMetadata
  include Sufia::ModelMethods
  include Sufia::Noid
  include Sufia::GenericFile::Permissions

  has_metadata :name => "properties", :type => PropertiesDatastream
  has_metadata :name => "descMetadata", :type => SeniorThesisMetadataDatastream

  has_many :generic_files, :property => :is_part_of

  delegate_to :descMetadata, [:title, :created, :description, :creator], :unique => true
  delegate_to :properties, [:relative_path, :depositor], :unique => true
  delegate_to :descMetadata, [:contributor]

  validates :title, presence: true
  attr_accessor :thesis_file

  def to_solr(solr_doc={}, opts={})
    super(solr_doc, opts)
    solr_doc["noid_s"] = noid
    return solr_doc
  end

end