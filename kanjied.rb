#!/bin/env ruby
require 'rubygems'
require 'memcache'
require 'optparse'

options = {}
OptionParser.new do |opts|
   opts.banner = "Usage: kanjied.rb [options]"

   opts.on("-c", "--config", "Config file") do |config|
     options[:config_file] = config
   end
end.parse!

exit(1) unless File.exist?(config)
# loading config
config = YAML::load(File.open(options[:config_file]))[:config]

site_path = config[:site_path]
memcached_hosts = %w[]
config[:memcached_hosts].split(',').each { |host| memcached_hosts << host}
file_extensions = Array.new
config[:file_extensions].split(',').each { |ext| file_extensions << ext}
#namespace = "rubyied"

def get_files(a_dir)
  files = Array.new
  Dir.chdir(a_dir)
  Dir.glob('*').each do |a_file|
    if File.directory?(a_file)
      get_files(a_file).each { |b_file| files << "#{a_dir}/" + b_file }
    else
      if file_extensions.size > 0
        file_extensions.each do |ext|
          files << "#{a_dir}/" + a_file if a_file ~= /#{ext}$/
        end
      else
        files << "#{a_dir}/" + a_file
      end
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
CACHE = MemCache.new memcached_hosts

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