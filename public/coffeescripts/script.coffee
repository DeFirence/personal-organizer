show_error = (error_message) -> $('#flash_error').html(error_message).show('slow') unless $.page_unloaded
hide_error = -> $('#flash_error').text('').hide 'slow'
show_notice = (notice, time=false) ->
  $('#flash_notice').text(notice).show 'slow'
  setTimeout hide_notice, time * 1000 unless time == false
hide_notice = -> $('#flash_notice').text('').hide 'slow'
set_timeout = (seconds, callback) -> setTimeout callback, seconds * 1000
set_interval = (seconds, callback) -> setInterval callback, seconds * 1000

render_event = (event) -> $('#calendar').fullCalendar 'renderEvent', event, true

every_second = ->
  now     = new Date()
  hours   = now.getHours()
  minutes = now.getMinutes()
  minutes = "0" + minutes if minutes < 10
  seconds = now.getSeconds()
  seconds = "0" + seconds if seconds < 10
  suffix  = if hours > 11 then hours -= 12; 'PM' else 'AM'
  $('.info-box').text "#{hours}:#{minutes}:#{seconds} #{suffix}"

String.prototype.capitalize = -> this.charAt(0).toUpperCase() + this.slice(1)

$(document).ready ->
  set_interval 1, -> every_second()

  $('#calendar').fullCalendar
    theme: true,
    editable: true,
    selectable: true,
    selectHelper: true,
    select: (start, end, allDay) ->
      $('#calendar').fullCalendar 'unselect'
      title = prompt 'Event Title:'
      return unless title
      render_event title: title, start: start, end: end, allDay: allDay
    header:
      left: 'prev,next today',
      center: 'title',
      right: 'month,agendaWeek,agendaDay'
    events: []

  # Long polling ajax updates
  listen = (last_modified, etag) ->
    $.ajax
      'beforeSend': (xhr) ->
        xhr.setRequestHeader "If-None-Match", etag
        xhr.setRequestHeader "If-Modified-Since", last_modified
      url: '/ajax/updates',
      dataType: 'json',
      type: 'get',
      cache: 'false',
      success: (packet, textStatus, xhr) ->
        hide_error()
        etag = xhr.getResponseHeader('Etag')
        last_modified = xhr.getResponseHeader('Last-Modified')
        packet = new Array(packet) unless $.isArray(packet)
        for data in packet
          console.log "received data: type=#{data.type} id=#{data.id} updated_at=#{data.updated_at} status='#{data.status if data.status?}'"

          switch data.type
            when 'status'
              switch data.status
                when 'online'
                  hide_error()
                when 'offline'
                  show_error "The server has lost connectivity to #{data.target}."

        listen last_modified, etag
      error: (xhr, textStatus, errorThrown) ->
        console.log textStatus + ': ' + errorThrown
        show_error "Connection to server has been lost. Either you have an issue with your internet connectivity or the server is offline."
        set_timeout 10, -> listen last_modified, etag

  #set_timeout 0.5, -> listen 'Thu, 1 Jan 1970 00:00:00 GMT', '0'

  window.onbeforeunload = ->
    show_notice "Page has been unloaded. Refresh page to reload application."
    $.page_unloaded = true
    null