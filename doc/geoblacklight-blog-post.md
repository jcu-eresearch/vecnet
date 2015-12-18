# VecNET Digital Library Search using GeoBlacklight


We joined the GeoBlacklight party back when we start collaboration with the VecNET project.  VecNET was a Gates Foundation project by the University of Notre Dame.  VecNET used models and simulations to learn about malaria vectors, transmission and interventions.  Important and cool stuff!

![screenshot of VecNET simulator page]
(https://github.com/jcu-eresearch/vecnet/blob/blog-post/doc/vecnet-home.png)

Digital librarians used their collated digital library to search malaria literature for accurate values used in simulations.

## What was the problem?

The search interface wasn't spatial, had some usability issues and needed some design love.  One usability issue was called 'pogosticking' by AirBnB: users had to look back and forth from filters to search to results as there was not enough information in results to make a informed decision. Another issue was filters that help narrow down a search were tucked away to the side. A map was non-existent.

![screenshot of old DL homepage]
(https://github.com/jcu-eresearch/vecnet/blob/blog-post/doc/dl-old.png)

## Oh Airbnb

Surprisingly the original VecNET search bore a striking resemeblance to the old AirBnB search.  They had recently done a resign to fix design and usability issues!  

![ old airbnb slide ]
(https://github.com/jcu-eresearch/vecnet/blob/blog-post/doc/airbnb-old.png)

![ new airbnb slide ]
(https://github.com/jcu-eresearch/vecnet/blob/blog-post/doc/airbnb-new.png)

We could learn from their experience and benefit from design work done by a talented team and company.  Our final proposal was iteratively formed by getting feedback from VecNET librarians on designs based around three main principles derived from AirBnB. 
We wanted search to be as simple as possible and have a natural flow from the top of the page downwards. We wanted a big friendly map that encouraged interaction and discovery of spatial data within.
A well designed map could easily display information about where papers were from.  Any user or scientist could easily search for papers from a particular country or region using an intuitive map.

![ vecnet proposal slide ]
(https://github.com/jcu-eresearch/vecnet/blob/blog-post/doc/dl-proposal.png)

## Enter GeoBlacklight 

However the stack at VecNET was inherited from a prototype Ruby on Rails app with an old Solr and Fedora backend.  For a spatial search we would need to integrate spatial values of records with the existing dataset.  On the front end we wanted to use Leaflet and GeoJSON and uses Rail's API ability to serve  a modern Javascript powered frontend with the slick UI goodness that users enjoy.

Just as the coffeescript and Backbone.js structure was being laid down, we noticed a fantastic project starting up with strong progress and ideas about user friendly geospatial discovery.  

![ geoblacklight.org screenshot ]
(https://github.com/jcu-eresearch/vecnet/blob/blog-post/doc/geoblacklight.png)

GeoBlacklight!  GeoBlacklight builds on and extends the Blacklight project, a project for making discovery portals and digital libraries. Blacklight was a core part of the VecNET digital library's founding system.
Normally you don't get excited about Rails apps at version 0.4 but with institutions like Stanford, MIT and Princeton contributing to an active development community that encouraged new users - it was obvious.  

## Customising GeoBlacklight

Geoblacklight is written on the Ruby on Rails framework and uses Leaflet.js for mapping.  Both are written to be easily customised.  Even better, GeoBlacklight wrote a tutorial on exactly how to customise without breaking future upgrades and features.

Our customisations were primarily adding the new design work to the existing GeoBlacklight platform.  However, a few other issues did result in customisations:

* Single page with AJAX search and results
* Display of points and bounding boxes on map
* Animations and transitions between results and map marker
* Enhanced metadata on the results page 
* Progressive enhancement with fallback rendered HTML for SEO
* Retaining project branding and color schemes

## Javascript, microschema CSS variables oh my

// Dan if you want to write some here

  * single page + ajax
  * microschema?
  * points and bounding boxes


## Results

![current DL screenshot]
(https://github.com/jcu-eresearch/vecnet/blob/blog-post/doc/dl-new-map.png)

We got a modern codebase and design that encourages the discovery of spatial data and uses a platform that is easily extended for more data types, metadata, or spacial presentation features.  Any future development can easily modify the loosely coupled view layer, the map layer, and the metadata microschema without touching Solr or backend code.  GeoBlacklight's architecture and hard work on the geospatial discovery made it possible without writing from scratch.