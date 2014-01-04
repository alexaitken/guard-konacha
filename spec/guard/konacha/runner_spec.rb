require 'spec_helper'

describe Guard::Konacha::Runner do

  let(:konacha_runner) { double("konacha runner").as_null_object }
  let(:konacha_formatter) { double("konacha formatter").as_null_object }
  let(:rails_env_file) { File.expand_path('../../../dummy/config/environment', __FILE__) }
  let(:runner_options) { {
    :rails_environment_file => rails_env_file,
    :formatter => konacha_formatter
  } }

  subject { Guard::Konacha::Runner.new runner_options }

  before do
    # Silence Ui output
    ::Guard::UI.stub :info => true
    ::Guard::UI.stub :error => true
  end

  before do
    subject.stub(:runner) { konacha_runner }
  end

  describe '#initialize' do
    it 'should have default options and allow overrides' do
      subject.options.should eq(Guard::Konacha::Runner::DEFAULT_OPTIONS.merge(runner_options))
    end

    it 'should set Konacha mode to runner' do
      ::Konacha.mode.should eq(:runner)
    end
  end

  describe '#start' do
    describe 'with run_all_on_start set to true' do
      let(:runner_options) { super().merge(:run_all_on_start => true) }
      it 'should run all if :run_all_on_start option set to true' do
        subject.should_receive(:run).with(no_args)
        subject.start
      end
    end

    describe 'with run_all_on_start set to false' do
      let(:runner_options) { super().merge(:run_all_on_start => false) }
      it 'should run all if :run_all_on_start option set to true' do
        subject.should_not_receive(:run)
        subject.start
      end
    end
  end

  describe '#run' do
    before do
      File.stub(:exists?) { true }
    end

    context 'calling runner' do
      let(:konacha_runner) { double("konacha runner") }

      it 'should run each path through runner' do
        konacha_runner.should_receive(:run).with('/1')
        konacha_runner.should_receive(:run).with('/foo/bar')
        subject.run(['spec/javascripts/1.js', 'spec/javascripts/foo/bar.js'])
      end

      it 'should run when called with no arguemnts' do
        konacha_runner.should_receive(:run)
        subject.run
      end
    end

    it 'should format the results' do
      konacha_formatter.should_receive(:write_summary)
      subject.run
    end

    it 'should reset the formatter before running the test suite' do
      konacha_formatter.should_receive(:reset) do
        konacha_runner.should_receive(:run)
      end

      subject.run
    end
  end

  describe "notifications" do
    context 'enabled' do
      let(:runner_options) { super().merge(:notification => true) }

      it 'should send a notification after test run' do
        konacha_formatter.stub(:summary_line) { 'summary results' }
        Guard::Notifier.should_receive(:notify).with('summary results', anything)

        subject.run
      end

      it 'should send a nofitication on an expection during a test run' do
        konacha_formatter.stub(:write_summary).and_raise(StandardError, 'expection message')
        Guard::Notifier.should_receive(:notify).with('expection message', anything)

        subject.run
      end
    end

    context "disabled" do
      let(:runner_options) { super().merge(:notification => false) }

      it 'should not send notification after test run' do
        Guard::Notifier.should_not_receive(:notify)
        subject.run
      end

      it 'should not send notification after an error during a test run' do
        konacha_formatter.stub(:write_summary).and_raise(StandardError)
        Guard::Notifier.should_not_receive(:notify)
        subject.run
      end

    end
  end
end
