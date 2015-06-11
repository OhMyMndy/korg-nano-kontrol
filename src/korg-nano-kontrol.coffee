unless window?  # for node.js
  midi      = require 'midi'

{Promise} = require 'es6-promise' # if typeof Promise isnt 'function'

_         = require 'lodash'
debug     = require('debug')('midi-control')

NanoKONTROL2 = require './nanoKONTROL2'
NanoKONTROL  = require './nanoKONTROL'

Devices = [NanoKONTROL2, NanoKONTROL]

module.exports =

  connect: (deviceName = null) ->
    if window?
      return @connectWebMidi deviceName
    else
      return @connectNodeMidi deviceName

  connectWebMidi: (deviceName) ->
    return new Promise (resolve, reject) ->
      if typeof navigator?.requestMIDIAccess isnt 'function'
        return reject new Error 'Web MIDI API is not supported'
      navigator.requestMIDIAccess()
      .then (webMidi) ->
        it = webMidi.inputs.values()
        loop
          input = it.next()
          break if input.done

          name = input.value.name
          for device in Devices
            if device.detect name
              return resolve new device input.value, name

        return reject "device not found"

  connectNodeMidi: (deviceName) ->
    return new Promise (resolve, reject) ->
      input = new midi.input
      for i in [0...input.getPortCount()]
        name = input.getPortName i
        debug "found device [#{i}] \"#{name}\""

        devices = Devices.filter (i) ->
          !deviceName? or i.deviceName is deviceName

        for device in devices
          if device.detect name
            debug "detect \"#{device.name}\""
            debug "openPort #{i}"
            input.openPort i
            return resolve new device input, name

      return reject "device not found"
