class VecnetArticle < ActiveFedora::Base
  include Hydra::ModelMixins::CommonMetadata
  include Hydra::ModelMixins::RightsMetadata
  include Sufia::ModelMethods
  include Sufia::Noid
  include Sufia::GenericFile::Permissions

  has_metadata name: "properties", type: PropertiesDatastream
  has_metadata name: "descMetadata", type: VecnetArticleMetadataDatastream

  has_many :generic_files, property: :is_part_of

  delegate_to(
      :descMetadata,
      [   :title,
          :created,
          :description,
          :date_uploaded,
          :date_modified,
          :available,
          :archived_object_type,
          :creator,
          :content_format,
          :identifier,
          :contributor,
          :contributor,
          :publisher,
          :bibliographic_citation,
          :source,
          :language,
          :extent,
          :requires,
          :subject
      ]
  )
  delegate_to :properties, [:relative_path, :depositor], unique: true
  validates :title, presence: true

  before_save {|obj| obj.archived_object_type = self.class.to_s }

  def to_solr(solr_doc={}, opts={})
    super(solr_doc, opts)
    solr_doc["noid_s"] = noid
    return solr_doc
  end


  def current_file
    generic_files.first
  end

  def to_param
    noid
  end

end