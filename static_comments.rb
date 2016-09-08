# Store and render comments as a static part of a Jekyll site
#
# See README.mdwn for detailed documentation on this plugin.
#
# Homepage: http://theshed.hezmatt.org/jekyll-static-comments
#
#  Copyright (C) 2011 Matt Palmer <mpalmer@hezmatt.org>
#
#  This program is free software; you can redistribute it and/or modify it
#  under the terms of the GNU General Public License version 3, as
#  published by the Free Software Foundation.
#
#  This program is distributed in the hope that it will be useful, but
#  WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  General Public License for more details.
#
#  You should have received a copy of the GNU General Public License along
#  with this program; if not, see <http://www.gnu.org/licences/>

class Jekyll::Document
	alias :to_liquid_without_comments :to_liquid
	
	def to_liquid(*args)
		data = to_liquid_without_comments(*args)
		data['comments'] = StaticComments::find_for_post(self)
		data['comment_count'] = data['comments'].length
		# we need to do the following to get syntax highlighting in comments
		payload  = self.site.site_payload
		data['comments'].each { |x|
		                        x["content"] = site.liquid_renderer.file(path).parse(x["content"]).render!(payload, {:filters   => [Jekyll::Filters],:registers => { :site => self.site, :page => self }})
		                      }
		data
	end
end

module StaticComments
	# Find all the comments for a post
	def self.find_for_post(post)
		@comments ||= read_comments(post.site.source)
		@comments[post.id]
	end
	
	# Read all the comments files in the site, and return them as a hash of
	# arrays containing the comments, where the key to the array is the value
	# of the 'post_id' field in the YAML data in the comments files.
	def self.read_comments(source)
		comments = Hash.new() { |h, k| h[k] = Array.new }
		
		Dir["#{source}/**/_comments/**/*"].sort.each do |comment|
			next unless File.file?(comment) and File.readable?(comment)
			content = File.read(comment)
			if content =~ /\A(---\s*\n.*?\n?)^(---\s*$\n?)(.*\S.*)/m
				yaml_data = YAML.safe_load($1)
				yaml_data["content"] = $3
			else
				# It's all YAML!?
				yaml_data = YAML.safe_load(content)
				if (yaml_data.has_key?('comment'))
					yaml_data["content"] = yaml_data['comment']
				else
					yaml_data["content"] = ""
					puts "[StaticComments::Comment] WARNING: I don't know how to parse #{comment}; there doesn't seem to be any content or 'comment' property."
				end
			end
			post_id = yaml_data.delete('post_id')
			comments[post_id] << yaml_data
		end
		comments
	end
end
