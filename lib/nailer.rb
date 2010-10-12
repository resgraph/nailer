require 'rubygems'
require 'rwebthumb'
require 'RMagick'
require 'fileutils'

$LOAD_PATH.unshift(File.dirname(__FILE__))

require "nailer/nailer"
require "nailer/synchronized_buffer"

$LOAD_PATH.shift
