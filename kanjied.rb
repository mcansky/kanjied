##!/bin/env ruby
#Copyright (c) 2010 Thomas Riboulet riboulet@gmail.com
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in
#all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#THE SOFTWARE.


require 'rubygems'
require 'memcache'

# change this
site_path = "_site"
memcache_hosts = %w[localhost:11211]
# memcache_hosts = %w[localhost:11211 two.example.com:11211]
#namespace = "rubyied"

def get_files(a_dir)
  files = Array.new
  Dir.chdir(a_dir)
  Dir.glob('*').each do |a_file|
    if File.directory?(a_file)
      get_files(a_file).each { |b_file| files << "#{a_dir}/" + b_file }
    else
      files << "#{a_dir}/" + a_file
    end
  end
  Dir.chdir("..")
  return files
end

### don't change pass this point ###
files = Array.new
files = get_files(site_path)
files.each { |file| file.gsub!("#{site_path}/", '') }

# ok we got the files we want to put in cache
## let's go to the site
Dir.chdir(site_path)

# memcached stuff
## connection :
CACHE = MemCache.new memcache_hosts

# going throught all the files
files.each do |a_file|
  printf("Checking #{a_file} :")
  # get content
  content = IO.read(a_file)
  a_file = "/" + a_file
  # let's check if it's the CACHE already
  if CACHE.get(a_file)
    printf(" in")
    # ook it's there, let's check content
    cached = CACHE.get(a_file)
    if content != cached
      printf(" too old !")
      # ooh bad, it's old, remove and reinsert new data
      CACHE.delete(a_file)
      printf(" deleted")
      CACHE.add("/" + a_file,content)
      printf(" added !\n")
    end
  else
    # not in there yet ?! come on jump in!
    printf(" absent")
    CACHE.add("/" + a_file,content)
    printf(" added !\n")
  end
end