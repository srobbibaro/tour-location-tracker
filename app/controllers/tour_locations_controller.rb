class TourLocationsController < ApplicationController
  before_filter :authenticate_user!

  def index
  end

  def locations
    render json: locations_for_user(current_user)
  end

  def add_location
    unless TourLocation.valid?(tour_location_params)
      render json: {result: false, message: t('tour_location.error.invalid_params')}
      return
    end

    # Build/Update and save tour location record
    unless tour_location_params[:id].nil?
      s = TourLocation.where(user_id: current_user.id)
                      .where(id: tour_location_params[:id]).first 
    end

    # Only allow one record with a particular name for each user
    saved_locations_with_name = s && s[:id] ?
      TourLocation.where(user_id: current_user.id).where(name: tour_location_params[:name]).where.not(id: s[:id]) :
      TourLocation.where(user_id: current_user.id).where(name: tour_location_params[:name])

    if saved_locations_with_name.count > 0
      render json: {result: false, message: t('tour_location.error.duplicate_name')}
      return
    end

    updated_params = tour_location_params.merge({
      user_id: current_user.id,
    })

    if s
      s.update_attributes!(updated_params)
    else
      s = TourLocation.create(updated_params)
    end

    render json: location_map(s).merge({result: true, message: t('tour_location.saved')})
  end

  def remove_location
    s = TourLocation.where(user_id: current_user.id).where(id: params[:id]).first
    if s
      s.destroy()
      render json: {
        result:  true,
        message: t('tour_location.removed')
      }
    else
      render json: {
        result: false
      }
    end
  end

  private
  def valid_params
    params.require(:location).permit(:id, :name, :longitude, :latitude)
  end

  def tour_location_params
    @tour_location_params ||= valid_params
  end

  def location_map(location)
    {
      id:        location.id,
      name:      location.name,
      longitude: location.longitude,
      latitude:  location.latitude
    }
  end

  def locations_for_user(user)
    TourLocation.where(user_id: user.id).order(updated_at: :desc).map { |tl|
      location_map tl
    }
  end
end
