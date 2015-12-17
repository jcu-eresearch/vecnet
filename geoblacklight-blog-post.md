# VecNET Digital Library Search using GeoBlacklight


We got on the GeoBlacklight bus when we joined with VecNET project.  VecNET was a Gates Foundation project to simulate, model to learn about malaria transmission and interventions.  Important and cool stuff!

[screenshot of malaria simulator page]

They used a digital library to search malaria literature for accurate values used in simulations.  

## What was the problem?

The search interface wasn't spatial, had some usability issues and needed some design love.  One usability issue was called 'pogosticking' by AirBnB: users had to look back and forth from filters to search to results as there was not enough information in results to make a informed decision. Another issue was filters that help narrow down a search were tucked away to the side. A map was non-existent.

[ screenshot of old dl homepage]

A big friendly map could easily show where papers are from.  A scientist could easily search for papers only from one country or region using a map.


## Oh AirBnB

Surprisingly the original VecNET search bore a striking resemeblance to the old AirBnB search.  They had recently done a resign to fix design and usability issues!  

[ old airbnb slide ]

[ new airbnb slide ]

We could learn from their experience and benefit from design work done by a talented team and company.  Our final proposal was iteratively formed by getting feedback from VecNET librarians on designs based around three main principles derived from AirBnB. 
We wanted search to be as simple as possible and have a natural flow from the top of the page downwards. We wanted a big friendly map that encouraged interaction and discovery of spatial data within.

[ vecnet proposal slide ]

## Enter GeoBlacklight 

However the stack at VecNET was inherited from a prototype Ruby on Rails app with an old Solr and Fedora backend.  For a spatial search we would need to integrate spatial values of records with the existing dataset.  On the front end we wanted to use Leaflet and GeoJSON and uses Rail's API ability to serve  a modern Javascript powered frontend with the slick UI goodness that users enjoy.

Just as the coffeescript and Backbone.js structure was being laid down, we noticed a fantastic project starting up with strong ideas about user friendly geospatial discovery.  

[ geoblacklight.org screenshot ]

GeoBlacklight!  GeoBlacklight builds on and extends the Blacklight project, itself a project for making discovery portals and digital libraries. Blacklight was a core part of the VecNET digital library's founding system.
Normally you don't get excited about Rails apps at version 0.4 but with institutions like Stanford, MIT and Princeton contributing to an active development community that encouraged new users - it was obvious.  

## Loving your upstream

The GeoBlacklight project was being developed in the open and allowed us to see where they were headed technically and strategically. That gave us confidence to use them as an upstream for a project without having worry about maintaining future compatibility.
Other institutions were also contributing which meant we could ask and recieve help.  Both projects published beginner friendly tutorials[] for their stacks.  What more could you ask for. Seriously.

## Customising GeoBlacklight

Geoblacklight is written on the Ruby on Rails framework and uses Leaflet.js for mapping.  If you have never used either, don't fear.  Both GeoBlacklight and Rails are written to be easily customised.  Even better, GeoBlacklight wrote a tutorial on exactly how to customise without breaking future upgrades and features.

Our customisations were primarily adding the new design work to the existing GeoBlacklight platform.  However, a few other issues did result in customisations:

* Single page with AJAX search and results
* Display of points and bounding boxes on map
* Animations and transitions between results and map marker
* Enhanced metadata on the results page 
* Progressive enhancement with fallback rendered HTML for SEO
* Retaining project branding and color schemes

