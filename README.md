# Vecnet Metadata Catalog

This application provides the [Vecnet Metadata Catalog](http://dl-vecnet.crc.nd.edu).
It handles the curation and indexing of the data generated by the Vecnet [cyberinfrastructure](http://vecnet-web.crc.nd.edu/).

## Dependencies

 * [Fedora Commons](http://fedora-commons.org/) 3.6
 * Solr 4.2
 * Redis (version?)
 * Postgresql or other SQL database
 * nginx
 * [chruby](https://github.com/postmodern/chruby) Ruby version manager

## Deployment

To deploy to QA:

    cap qa deploy

## Other server admin tasks

To rebuild the Fedora object store:

    sudo service tomcat6 stop
    cd /opt/fedora/server/bin
    sudo FEDORA_HOME=/opt/fedora CATALINA_HOME=/usr/share/tomcat6 ./fedora-rebuild.sh
    # choose option 1 to rebuild the resource index
    sudo FEDORA_HOME=/opt/fedora CATALINA_HOME=/usr/share/tomcat6 ./fedora-rebuild.sh
    # choose option 2 to rebuild the SQL database
    sudo service tomcat6 start

To resolarize everything...it will take a LONG time to complete.

    chruby 1.9.3-p392
    RAILS_ENV=qa bundle exec rake solrizer:fedora:solrize_objects

To load and build the MeSH trees run. This will run for a while (~0.5--1 hours)

    chruby 1.9.3-p392
    RAILS_ENV=qa bundle exec rake vecnet:import:mesh_subjects vecnet:import:eval_mesh_trees

To resolrize with mesh synonyms...it will take a LONG time to complete.

    chruby 1.9.3-p392
    # This builds the synonyms.txt file if needed.
    # you could skip this if synonyms did not change
    RAILS_ENV=qa bundle exec rake vecnet:solrize_synonym:get_synonyms FILE=solr_conf/conf/synonyms.txt
    #copy this file to solr core
    sudo  cp solr_conf/conf/synonyms.txt /opt/solr-4.3.0/vecnet/conf/synonyms.txt
    #copy schema and solrconfig
    sudo  cp solr_conf/conf/schema.xml /opt/solr-4.3.0/vecnet/conf/schema.xml
    sudo  cp solr_conf/conf/solrconfig.xml /opt/solr-4.3.0/vecnet/conf/solrconfig.xml
    #change owner to be tomcat
    sudo chown tomcat:tomcat -R /opt/solr-4.3.0
    #restart solr
    sudo service tomcat6 restart
    #resolrize all objects
    RAILS_ENV=qa bundle exec rake solrizer:fedora:solrize_objects

Initializing new production environment

 1. Do system setup as in `SETUP` file
 2. Get capistrano deploy working to new site
 3. on production machine:
  * setup ruby: `chruby 1.9.3-p392`
  * Setup mesh terms: `RAILS_ENV=production bundle exec rake vecnet:import:mesh_subjects vecnet:import:eval_mesh_trees`
  * Migrate user table: See below
  * Resolrize: `RAILS_ENV=production bundle exec rake solrizer:fedora:solrize_objects`
  * Migrate fedora objects: `RAILS_ENV=production bundle exec rake vecnet:migrate:batch_to_collection`
 7. Done!
