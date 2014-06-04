require_relative 'spec_helper'
require_relative '../lib/zest-publisher/nodes'

shared_context "shared render" do
  before(:each) do
    @null = Zest::Nodes::NullLiteral.new
    @what_is_your_quest = Zest::Nodes::StringLiteral.new("What is your quest ?")
    @fighters = Zest::Nodes::StringLiteral.new('fighters')
    @pi = Zest::Nodes::NumericLiteral.new(3.14)
    @false = Zest::Nodes::BooleanLiteral.new(false)
    @true = Zest::Nodes::BooleanLiteral.new(true)
    @foo_variable = Zest::Nodes::Variable.new('foo')
    @x_variable = Zest::Nodes::Variable.new('x')

    @foo_fighters_prop = Zest::Nodes::Property.new(@foo_variable, @fighters)
    @foo_dot_fighters = Zest::Nodes::Field.new(@foo_variable, 'fighters')
    @foo_brackets_fighters = Zest::Nodes::Index.new(@foo_variable, @fighters)
    @foo_minus_fighters = Zest::Nodes::BinaryExpression.new(@foo_variable, '-', @fighters)
    @minus_foo = Zest::Nodes::UnaryExpression.new('-', @foo_variable)
    @parenthesis_foo = Zest::Nodes::Parenthesis.new(@foo_variable)

    @foo_list = Zest::Nodes::List.new([@foo_variable, @fighters])
    @foo_dict =  Zest::Nodes::Dict.new([@foo_fighters_prop,
      Zest::Nodes::Property.new('Alt', 'J')
    ])

    @simple_template = Zest::Nodes::Template.new([
      Zest::Nodes::StringLiteral.new('A simple template')
    ])

    @foo_template = Zest::Nodes::Template.new([@foo_variable, @fighters])
    @double_quotes_template = Zest::Nodes::Template.new([
      Zest::Nodes::StringLiteral.new('Fighters said "Foo !"')
    ])

    @assign_fighters_to_foo = Zest::Nodes::Assign.new(@foo_variable, @fighters)
    @assign_foo_to_fighters = Zest::Nodes::Assign.new(
      Zest::Nodes::Variable.new('fighters'),
      Zest::Nodes::StringLiteral.new('foo'))
    @call_foo = Zest::Nodes::Call.new('foo')
    @argument = Zest::Nodes::Argument.new(@x_variable, @fighters)
    @call_foo_with_fighters = Zest::Nodes::Call.new('foo', [@argument])

    @simple_tag = Zest::Nodes::Tag.new('myTag')
    @valued_tag = Zest::Nodes::Tag.new('myTag', 'somevalue')

    @plic_param = Zest::Nodes::Parameter.new('plic')
    @x_param = Zest::Nodes::Parameter.new('x')
    @plic_param_default_ploc = Zest::Nodes::Parameter.new(
      'plic',
      Zest::Nodes::StringLiteral.new('ploc'))
    @flip_param_default_flap = Zest::Nodes::Parameter.new(
      'flip',
      Zest::Nodes::StringLiteral.new('flap'))

    @action_foo_fighters = Zest::Nodes::Step.new('action', @foo_template)

    @if_then = Zest::Nodes::IfThen.new(@true, [@assign_fighters_to_foo])
    @if_then_else = Zest::Nodes::IfThen.new(
      @true, [@assign_fighters_to_foo], [@assign_foo_to_fighters])
    @while_loop = Zest::Nodes::While.new(
      @foo_variable,
      [
        @assign_foo_to_fighters,
        @call_foo_with_fighters
      ])

    @empty_action_word = Zest::Nodes::Actionword.new('my action word')
    @tagged_action_word = Zest::Nodes::Actionword.new(
      'my action word',
      [@simple_tag, @valued_tag])
    @parameterized_action_word = Zest::Nodes::Actionword.new(
      'my action word',
      [],
      [@plic_param, @flip_param_default_flap])

    full_body = [
      Zest::Nodes::Assign.new(@foo_variable, @pi),
      Zest::Nodes::IfThen.new(
        Zest::Nodes::BinaryExpression.new(
          @foo_variable,
          '>',
          @x_variable),
        [
          Zest::Nodes::Step.new('result', "x is greater than Pi")
        ],
        [
          Zest::Nodes::Step.new('result', "x is lower than Pi\n on two lines")
        ])
      ]

    @full_actionword = Zest::Nodes::Actionword.new(
      'compare to pi',
      [@simple_tag],
      [@x_param],
      full_body)

    @step_action_word = Zest::Nodes::Actionword.new(
      'my action word',
      [],
      [],
      [Zest::Nodes::Step.new('action', "basic action")])

    @full_scenario = Zest::Nodes::Scenario.new(
      'compare to pi',
       "This is a scenario which description \nis on two lines",
      [@simple_tag],
      [@x_param],
      full_body)

    @actionwords = Zest::Nodes::Actionwords.new([
      Zest::Nodes::Actionword.new('first action word'),
      Zest::Nodes::Actionword.new(
        'second action word', [], [], [
          Zest::Nodes::Call.new('first action word')
        ])
    ])
    @scenarios = Zest::Nodes::Scenarios.new([
      Zest::Nodes::Scenario.new('first scenario'),
      Zest::Nodes::Scenario.new(
        'second scenario', '', [], [], [
          Zest::Nodes::Call.new('my action word')
        ])
    ])
    @scenarios.parent = Zest::Nodes::Project.new('My_project')

    @context = {framework: framework}
  end
end

shared_examples "a renderer" do
  it 'NullLiteral' do
    @null.render(language, @context).should eq(@null_rendered)
  end

  it 'StringLiteral' do
    @what_is_your_quest.render(language, @context).should eq(@what_is_your_quest_rendered)
  end

  it 'NumericLiteral' do
    @pi.render(language, @context).should eq(@pi_rendered)
  end

  it 'BooleanLiteral' do
    @false.render(language, @context).should eq(@false_rendered)
  end

  it 'Variable' do
    @foo_variable.render(language, @context).should eq(@foo_variable_rendered)
  end

  it 'Property' do
    @foo_fighters_prop.render(language, @context).should eq(@foo_fighters_prop_rendered)
  end

  it 'Field' do
    @foo_dot_fighters.render(language, @context).should eq(@foo_dot_fighters_rendered)
  end

  it 'Index' do
    @foo_brackets_fighters.render(language, @context).should eq(@foo_brackets_fighters_rendered)
  end

  it 'BinaryExpression' do
    @foo_minus_fighters.render(language, @context).should eq(@foo_minus_fighters_rendered)
  end

  it 'UnaryExpression' do
    @minus_foo.render(language, @context).should eq(@minus_foo_rendered)
  end

  it 'Parenthesis' do
    @parenthesis_foo.render(language, @context).should eq(@parenthesis_foo_rendered)
  end

  it 'List' do
    @foo_list.render(language, @context).should eq(@foo_list_rendered)
  end

  it 'Dict' do
    @foo_dict.render(language, @context).should eq(@foo_dict_rendered)
  end

  it 'Template' do
    @foo_template.render(language, @context).should eq(@foo_template_rendered)
    @double_quotes_template.render(language, @context).should eq(@double_quotes_template_rendered)
  end

  it 'Assign' do
    @assign_fighters_to_foo.render(language, @context).should eq(@assign_fighters_to_foo_rendered)
  end

  it 'Call' do
    @call_foo.render(language, @context).should eq(@call_foo_rendered)
    @call_foo_with_fighters.render(language, @context).should eq(@call_foo_with_fighters_rendered)
  end

  it 'IfThen' do
    @if_then.render(language, @context).should eq(@if_then_rendered)
    @if_then_else.render(language, @context).should eq(@if_then_else_rendered)
  end

  it "Step" do
    @action_foo_fighters.render(language, @context).should eq(@action_foo_fighters_rendered)
  end

  it 'While' do
    @while_loop.render(language, @context).should eq(@while_loop_rendered)
  end

  it 'Tag' do
    @simple_tag.render(language, @context).should eq(@simple_tag_rendered)
    @valued_tag.render(language, @context).should eq(@valued_tag_rendered)
  end

  it 'Parameter' do
    @plic_param.render(language, @context).should eq(@plic_param_rendered)
    @plic_param_default_ploc.render(language, @context).should eq(@plic_param_default_ploc_rendered)
  end

  context 'Actionword' do
    it 'empty' do
      @empty_action_word.render(language, @context).should eq(@empty_action_word_rendered)
    end

    it 'with tags' do
      @tagged_action_word.render(language, @context).should eq(@tagged_action_word_rendered)
    end

    it 'with parameters' do
      @parameterized_action_word.render(language, @context).should eq(@parameterized_action_word_rendered)
    end

    it 'with body' do
      @full_actionword.render(language, @context).should eq(@full_actionword_rendered)
    end

    it 'with body that contains only step' do
      @step_action_word.render(language, @context).should eq(@step_action_word_rendered)
    end
  end

  it 'Scenario' do
    @full_scenario.render(language, @context).should eq(@full_scenario_rendered)
  end

  it 'Actionwords' do
    @context[:package] = 'com.example'
    @actionwords.render(language, @context).should eq(@actionwords_rendered)
  end

  it 'Scenarios' do
    @context[:filename] = 'ProjectTest.java'
    @context[:package] = 'com.example'
    @context[:call_prefix] = 'actionwords'
    @scenarios.render(language, @context).should eq(@scenarios_rendered)
  end
end