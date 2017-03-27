class LocationCheckController < ApplicationController
  before_filter :authenticate_user!

  def find_location
    location = Geokit::Geocoders::IpGeocoder.geocode(request.remote_ip)
    render json: {longitude: location.longitude, latitude: location.latitude}
  end
end
