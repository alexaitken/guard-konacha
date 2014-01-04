require 'spec_helper'

describe Guard::Konacha::Runner do

  let(:konacha_formatter) { double("konacha formatter").as_null_object }
  let(:notification_setting) { true }
  let(:rails_env_file) { File.expand_path('../../../dummy/config/environment', __FILE__) }
  let(:runner_options) { {
    :notification => notification_setting,
    :rails_environment_file => rails_env_file,
    :formatter => konacha_formatter
  } }

  let(:runner) { Guard::Konacha::Runner.new runner_options }

  before do
    # Silence Ui.info output
    ::Guard::UI.stub :info => true
    ::Guard::UI.stub :error => true
  end

  describe '#initialize' do
    it 'should have default options and allow overrides' do
      runner.options.should eq(Guard::Konacha::Runner::DEFAULT_OPTIONS.merge(runner_options))
    end

    it 'should set Konacha mode to runner' do
      ::Konacha.mode.should eq(:runner)
    end
  end

  describe '#start' do
    describe 'with run_all_on_start set to true' do
      let(:runner_options) { super().merge(:run_all_on_start => true) }
      it 'should run all if :run_all_on_start option set to true' do
        runner.should_receive(:run).with(no_args)
        runner.start
      end
    end

    describe 'with run_all_on_start set to false' do
      let(:runner_options) { super().merge(:run_all_on_start => false) }
      it 'should run all if :run_all_on_start option set to true' do
        runner.should_not_receive(:run)
        runner.start
      end
    end
  end

  describe '#run' do
    let(:konacha_runner) { double("konacha runner").as_null_object }

    before do
      runner.stub(:runner) { konacha_runner }
      File.stub(:exists?) { true }
      konacha_formatter.stub(:any?) { true }
    end

    context 'calling runner' do
      let(:konacha_runner) { double("konacha runner") }

      it 'should run each path through runner' do
        konacha_runner.should_receive(:run).with('/1')
        konacha_runner.should_receive(:run).with('/foo/bar')
        runner.run(['spec/javascripts/1.js', 'spec/javascripts/foo/bar.js'])
      end

      it 'should run when called with no arguemnts' do
        konacha_runner.should_receive(:run)
        runner.run
      end
    end

    it 'should format the results' do
      konacha_formatter.should_receive(:write_summary)
      runner.run
    end

    it 'should reset the formatter before running the test suite' do
      konacha_formatter.should_receive(:reset) do
        konacha_runner.should_receive(:run)
      end

      runner.run
    end
  end
end
