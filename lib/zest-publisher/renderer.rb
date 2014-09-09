require 'handlebars'
require 'zest-publisher/nodes_walker'

module Zest
  class Renderer < Zest::Nodes::Walker
    attr_reader :rendered

    def self.render(node, language, context)
      context[:language] = language
      renderer = Zest::Renderer.new(context)
      renderer.walk_node(node)
      renderer.rendered[node]
    end

    def initialize(context)
      super(:children_first)
      @rendered = {}
      @context = context
      @handlebars = Handlebars::Context.new
      register_handlebars_helpers
    end

    def register_handlebars_helpers
      string_helpers = [
        :literate,
        :normalize,
        :underscore,
        :camelize,
        :camelize_lower]

      string_helpers.each do |helper|
        @handlebars.register_helper(helper) do |context, value|
          "#{value.send(helper)}"
        end
      end

      @handlebars.register_helper(:to_string) do |context, value|
        "#{value.to_s}"
      end

      @handlebars.register_helper(:join) do |context, items, joiner|
        "#{items.join(joiner)}"
      end

      @handlebars.register_helper(:indent) do |context, block|
        indentation = @context[:indentation] || '  '
        block.fn(context).split("\n").map do |line|
          indented = "#{indentation}#{line}"
          indented = "" if indented.strip.empty?
          indented
        end.join("\n")
      end

      @handlebars.register_helper(:clear_empty_lines) do |context, block|
        block.fn(context).split("\n").map do |line|
          line unless line.strip.empty?
        end.compact.join("\n")
      end

      @handlebars.register_helper(:remove_quotes) do |context, s|
        "#{s.gsub('"', '')}"
      end

      @handlebars.register_helper(:escape_quotes) do |context, s|
        "#{s.gsub(/"/) {|_| '\\"' }}"
      end

      @handlebars.register_helper(:comment) do |context, commenter, block|
        block.fn(context).split("\n").map do |line|
          "#{commenter} #{line}"
        end.join("\n")
      end

      @handlebars.register_helper(:curly) do |context, block|
        "{#{block.fn(context)}}"
      end
    end

    def call_node_walker(node)
      if node.is_a? Zest::Nodes::Node
        @rendered_children = {}
        node.children.each {|name, child| @rendered_children[name] = @rendered[child]}

        render_context = super(node)
        @rendered[node] = render_node(node, render_context)
      elsif node.is_a? Array
        @rendered[node] = node.map {|item| @rendered[item]}
      else
        @rendered[node] = node
      end
    end

    def render_node(node, render_context = {})
      handlebars_template = get_template_path(node, 'hbs')

      if handlebars_template.nil?
        render_erb(node, get_template_path(node, 'erb'), render_context)
      else
        render_handlebars(node, handlebars_template, render_context)
      end
    end

    def render_erb(node, template, render_context)
      ERB.new(File.read(template), nil, "%<>").result(binding)
    end

    def render_handlebars(node, template, render_context)
      render_context = {} if render_context.nil?
      render_context[:node] = node
      render_context[:rendered_children] = @rendered_children

      @handlebars.compile(File.read(template)).send(:call, render_context)
    end

    def get_template_path(node, extension)
      normalized_name = node.class.name.split('::').last.downcase

      searched_folders = []
      if @context.has_key?(:framework)
        searched_folders << "#{@context[:language]}/#{@context[:framework]}"
      end
      searched_folders << [@context[:language], 'common']

      searched_folders.flatten.map do |path|
        template_path = "#{zest_publisher_path}/lib/templates/#{path}/#{normalized_name}.#{extension}"
        if File.file?(template_path)
          template_path
        end
      end.compact.first
    end

    def indent_block(nodes, indentation = nil, separator = '')
      indentation = indentation || @context[:indentation] || '  '

      nodes.map do |node|
        node ||= ""
        node.split("\n").map do |line|
          "#{indentation}#{line}\n"
        end.join
      end.join(separator)
    end

    def walk_actionword(aw)
      {
        :has_parameters? => aw.has_parameters?,
        :has_tags? => !aw.children[:tags].empty?,
        :has_step? => aw.has_step?
      }
    end

    def walk_scenario(sc)
      {
        :has_parameters? => sc.has_parameters?,
        :has_tags? => !sc.children[:tags].empty?
      }
    end

    def walk_call(c)
      {
        :has_arguments? => !c.children[:arguments].empty?
      }
    end

    def walk_ifthen(it)
      {
        :has_else? => !it.children[:else].empty?
      }
    end

    def walk_parameter(p)
      {
        :has_default_value? => !p.children[:default].nil?
      }
    end

    def walk_tag(t)
      {
        :has_value? => !t.children[:value].nil?
      }
    end

    def walk_template(t)
      treated = t.children[:chunks].map do |chunk|
        {
          :is_variable? => chunk.is_a?(Zest::Nodes::Variable),
          :raw => chunk
        }
      end
      variables = treated.map {|item| item[:raw] if item[:is_variable?]}.compact

      {
        :treated_chunks => treated,
        :variables => variables
      }
    end
  end
end