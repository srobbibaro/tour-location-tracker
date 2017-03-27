$(document).ready () ->
  return unless $.find('#map-section').length > 0
  locations = []
  marker    = null

  # Temporary - these coordinates are essentially the mid point of the United States
  current_pos = {latitude: 40.44183, longitude: -80.01278, range: 50.0}

  map = new google.maps.Map($(".location-map-canvas").get(0), {
    zoom:        18,
    mapTypeId:   google.maps.MapTypeId.HYBRID,
    center:      {lat: current_pos.latitude, lng: current_pos.longitude},
    tilt:        0,
    scrollwheel: false
  })

  $('#save').on 'click', () ->
    name = $('#name').val()
    current_pos.longitude = marker.getPosition().lng()
    current_pos.latitude = marker.getPosition().lat()

    if !name
      displayAlert("You must enter a location name.", 'danger')
    else if !current_pos.longitude or !current_pos.latitude
      $('.location').html("Invalid location")
      displayAlert("Could not save invalid location", 'danger')
    else
      selected = $('.saved-locations > table > tbody').find('.selected')
      id = if selected.length > 0 then selected.parent().attr('data-id') else null

      $.ajax {
        type: 'POST',
        url: '/tour_locations/add_location',
        contentType: "application/json",
        data: JSON.stringify({
          location: {
            longitude: current_pos.longitude,
            latitude:  current_pos.latitude,
            name:      name,
            id:        id
          }
        }),
        success: (data) ->
          if data.result
            addLocation(data)
            data.marker = addMarker(data, map)
            locations.push(data)
            clickFirst()
            displayAlert(data.message)
          else
            displayAlert(data.message, 'danger')
      }

  $('#fetch').on 'click', () ->
    success = (position) ->
      updateLocation({
        latitude:  position.coords.latitude,
        longitude: position.coords.longitude,
      })

    error = (err) ->
      $('.location').html("Could not load location (#{err.code}): #{err.message}")

    if navigator.geolocation
      $('.location').html("Loading...")

      navigator.geolocation.getCurrentPosition(success, error, {
        enableHighAccuracy: true,
        timeout:            20000,
        maximumAge:         0
      })
    else
      $('.location').html("Feature not supported")

  $('[data-hide]').on 'click', () ->
    $('.alert').hide()

  searchBox = new google.maps.places.SearchBox($('#search_text').get(0))

  map.addListener('bounds_changed', () ->
    searchBox.setBounds(map.getBounds())
  )

  searchBox.addListener('places_changed', () ->
    places = searchBox.getPlaces()

    return if places.length == 0

    $('.location').html("Loading...")

    updateLocation({
      name:      places[0].name,
      latitude:  places[0].geometry.location.lat(),
      longitude: places[0].geometry.location.lng()
    })
  )

  selectLocationHandler = () ->
    id = $(this).parent().attr('data-id')
    updateLocation(_.find(locations, (l) -> "#{l.id}" == "#{id}"))
    _.each(locations, (l) -> l.marker.setOpacity(if "#{l.id}" != "#{id}" then 1.0 else .4))
    $(this).addClass('selected')

  removeLocationHandler = () ->
    id = $(this).parent().attr('data-id')
    $('#delete_location_confirm').on 'click', () ->
      $('#delete_location_modal').modal('hide')
      if id
        $.ajax {
          type: 'POST',
          url: '/tour_locations/remove_location',
          data: {
            id: id
          },
          success: (data) ->
            if data and data.result
              removeLocation(id)
              locations = _.reject(locations, (l) -> "#{l.id}" == "#{id}")
              if locations.length == 0
                $('.saved-locations').css('display', 'none')
                $('.no-saved-locations').css('display', 'block')
                updateLocationSettings()
              else
                clickFirst()
        }
    $('#delete_location_modal').modal('show')

  findIpBasedLocation = () ->
    $('.location').html("Loading...")
    $.ajax {
      type: 'POST',
      url: '/location_check/find_location',
      success: (data) ->
        if data && data.longitude && data.latitude
          updateLocation({
            latitude:  data.latitude,
            longitude: data.longitude,
          })
        else
          $('.location').html("Location: Default")
      error: (err) ->
        $('.location').html("Could not load location (#{err.code}): #{err.message}")
    }

  updateLocation = (location) ->
    $('.saved-location').removeClass('selected')
    if location
      current_pos.latitude  = location.latitude
      current_pos.longitude = location.longitude

      $('.location').html(if location.name then "Location: #{location.name}" else "Your current position")

      pos = new google.maps.LatLng(current_pos.latitude, current_pos.longitude)
      map.setCenter(pos)
      marker.setPosition(pos)

      updateLocationSettings(location)
    else
      $('.location').html("Invalid location")

  clickFirst = () ->
    if ('.saved-location').length > 0
      $('.saved-location').first().click()

  updateLocationSettings = (location={}) ->
    name = if location.name then location.name else ''

    $('#name').val(name)

  addLocation = (data) ->
    removeLocation(data.id)
    locations = _.reject(locations, (l) -> "#{l.id}" == "#{data.id}")
    $('.saved-locations > table > tbody:first').prepend( "<tr data-id=\"#{data.id}\">" +
      "<td class=\"location-table-cell-fixed saved-location\">#{data.name}</td>" +
      "<td class=\"remove-location\">" +
      "<img src=\"/delete.png\" alt=\"Remove this location\" title=\"Remove this location\" height=\"16\" width=\"16\"/></td>" +
      "</tr>"
    )

    $('.saved-locations').css('display', 'block')
    $('.no-saved-locations').css('display', 'none')

    $('.saved-location').first().on 'click', selectLocationHandler
    $('.remove-location').first().on 'click', removeLocationHandler

  removeLocation = (id) ->
    selected_location = _.find(locations, (l) -> "#{l.id}" == "#{id}")
    selected_location.marker.setMap(null) if selected_location
    $("[data-id='#{id}']").remove()

  addMarker = (location, map, draggable=false) ->
    new google.maps.Marker({
      position:  {lat: location.latitude, lng: location.longitude},
      map:       map,
      draggable: draggable
      title:     if draggable then "Drag to location" else "Location: #{location.name}",
      opacity:   1.0
    })

  fetchLocations = () ->
    $.ajax {
      type: 'POST',
      url: '/tour_locations/locations',
      success: (data) ->
        if data
          locations = _.map(data.reverse(), (d) ->
            addLocation(d)
            add_marker = addMarker(d, map)
            $.extend({}, d, {marker: add_marker})
          )
          if locations.length > 0
            clickFirst()
          else
            findIpBasedLocation()
    }

  displayAlert = (text, alert_class='success') ->
    alert_bar = $('.alert')
    alert_bar.removeClass("alert-danger alert-success")
    alert_bar.addClass("alert-#{alert_class}")
    alert_bar.find('.text').first().html(text)
    $(".alert").show()
    $('html, body').animate({ scrollTop: alert_bar.offset().top - 20})

  # Ensure that the map is is proper width -- scale it manually
  setMapWidth()

  marker = addMarker(current_pos, map, true)

  google.maps.event.addListener(map, "click", (event) ->
    marker.setPosition(event.latLng)
  )

  fetchLocations()

setMapWidth = () ->
  return unless $.find('#map-section').length > 0
  width = $('#map-section').width()
  $('.location-map').css({width: width})

$(window).resize () ->
  setMapWidth()
