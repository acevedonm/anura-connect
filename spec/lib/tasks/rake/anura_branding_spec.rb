require 'rails_helper'

RSpec.describe Rake::Task, 'anura:branding' do
  subject(:task) { described_class['anura:branding'] }

  let(:enterprise_path) { Rails.root.join('enterprise') }
  let(:branding) do
    {
      'INSTALLATION_NAME' => 'Anura Connect',
      'LOGO' => '/brand-assets/anura/logo.svg',
      'LOGO_DARK' => '/brand-assets/anura/logo.svg',
      'LOGO_THUMBNAIL' => '/brand-assets/anura/icon.png'
    }
  end

  before do
    task.reenable
    allow(Rails.root).to receive(:join).and_call_original
    allow(Rails.root).to receive(:join).with('enterprise').and_return(enterprise_path)
    allow(enterprise_path).to receive(:exist?).and_return(false)
  end

  after do
    Redis::Alfred.delete(Redis::Alfred::CHATWOOT_INSTALLATION_CONFIG_RESET_WARNING)
  end

  it 'clears a warning left by a previous Enterprise image after applying Community branding' do
    Redis::Alfred.set(Redis::Alfred::CHATWOOT_INSTALLATION_CONFIG_RESET_WARNING, true)

    task.invoke

    expect(Redis::Alfred.get(Redis::Alfred::CHATWOOT_INSTALLATION_CONFIG_RESET_WARNING)).to be_nil
  end

  it 'applies the Anura branding and preserves unrelated settings on repeated runs' do
    InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_NAME').update!(value: 'Chatwoot')
    InstallationConfig.find_or_initialize_by(name: 'ENABLE_ACCOUNT_SIGNUP').update!(value: false)

    2.times do
      task.reenable
      task.invoke

      branding.each do |name, value|
        expect(InstallationConfig.find_by!(name: name).value).to eq(value)
      end
      expect(InstallationConfig.find_by!(name: 'ENABLE_ACCOUNT_SIGNUP').value).to be(false)
    end
  end

  it 'creates missing branding settings on a fresh installation' do
    InstallationConfig.where(name: branding.keys).destroy_all

    expect { task.invoke }.to change { InstallationConfig.where(name: branding.keys).count }.from(0).to(4)
    branding.each do |name, value|
      expect(InstallationConfig.find_by!(name: name).value).to eq(value)
    end
  end

  it 'refuses to change settings when Enterprise code is present' do
    allow(enterprise_path).to receive(:exist?).and_return(true)
    InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_NAME').update!(value: 'Licensed installation')
    Redis::Alfred.set(Redis::Alfred::CHATWOOT_INSTALLATION_CONFIG_RESET_WARNING, true)

    expect { task.invoke }.to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
    expect(InstallationConfig.find_by!(name: 'INSTALLATION_NAME').value).to eq('Licensed installation')
    expect(Redis::Alfred.get(Redis::Alfred::CHATWOOT_INSTALLATION_CONFIG_RESET_WARNING)).to be_present
  end
end
