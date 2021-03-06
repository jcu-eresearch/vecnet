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

require 'rdf'
require 'cgi'
require File.expand_path('../../models/local_authority', __FILE__)

class AuthoritiesController < ApplicationController
  def query
    s = params.fetch("q", "")
    case params[:term]
    when "location"
      hits = GeoNamesResource.find_location(s)
    when "species"
      hits = LocalAuthority.entries_by_species(params[:term], s) #rescue []
    when "subject"
      hits = LocalAuthority.entries_by_subject_mesh_term(params[:model], params[:term], s) #rescue []
    else
      hits = []
    end
    render :json=>hits
  end
end
