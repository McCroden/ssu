#
# Allows getting, setting, serializing, and deserializing preferences.
#

type    = require 'lang/type'
func    = require 'lang/func'
File    = require 'io/File'
inspect = require 'util/inspect'
{tryCatch, tryThrow} = require 'util/try'

fallbackPreferencesRoot =
  _values: {}

  getCharPref: (key) ->
    @_values[key]

  getIntPref: (key) ->
    @_values[key]

  getBoolPref: (key) ->
    @_values[key]

  setCharPref: (key, value) ->
    @_values[key] = value

  setIntPref: (key, value) ->
    @_values[key] = value

  setBoolPref: (key, value) ->
    @_values[key] = value

getPreferencesRoot = ->
  try
    service = Cc['@mozilla.org/preferences-service;1']
      .getService(Ci.nsIPrefService)
    service.getBranch('')
  catch ex
    fallbackPreferencesRoot

#
# Loads preferences from a Mozilla prefs.js format preference file.
# Example:
#
#   $ cat prefs.js
#   # Mozilla Preference File
#   pref('network.proxy.http', 'proxy.oak.wesabe.com');
#   pref('network.proxy.http_port', 8080);
#   pref('network.proxy.type', 1);
#
#   prefs.load('prefs.js');
#   prefs.get('network.proxy.type'); // => 1
#
# WARNING: At this point this function is NOT SAFE and will eval the
# contents of the file in a non-safe way. Please know what you're doing.
#
load = (file) ->
  tryCatch "prefs.load(#{file})", (log) =>
    data = File.read file

    if /^#/.test(data)
      # data includes unparseable first line, remove it
      data = data.replace(/^#[^\n]*/, '')

    func.callWithScope data, this, pref: set

#
# Get a preference by its full name. Example:
#
#   prefs.get 'browser.dom.window.dump.enabled' // => false
#
# NOTE: because this is used in logging, this function may not use `logger'.
#
get = (key, defaultValue) ->
  root = getPreferencesRoot()

  # maybe it's a String
  try
    return root.getCharPref(key)
  catch e

  # maybe it's a Boolean
  try
    return root.getBoolPref(key)
  catch e

  # maybe it's a Number
  try
    return root.getIntPref(key)
  catch e

  # not found
  return defaultValue

#
# Set a preference by its full name. Example:
#
#   prefs.set 'browser.dom.window.dump.enabled', true
#
set = (key, value) ->
  root = getPreferencesRoot()

  if type.isBoolean value
    root.setBoolPref key, value
  else if type.isString value
    root.setCharPref key, value
  else if type.isNumber value
    root.setIntPref key, value
  else
    throw new Error "Could not set preference for key=#{key}, unknown type for value=#{inspect value}"

#
# Clears a preference by its full name. Example:
#
#   prefs.clear('general.useragent.override');
#
clear = (key) ->
  try
    getPreferencesRoot().clearUserPref(key)
  catch e
    # pref probably didn't exist, but make sure it's gone
    if not type.isUndefined get(key)
      logger.error "Could not clear pref with key=", key, " due to an error: ", e

module.exports = {load, get, set, clear}
