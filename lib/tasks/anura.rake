namespace :anura do
  desc 'Apply the fork branding to an existing installation without changing other settings'
  task branding: :environment do
    if Rails.root.join('enterprise').exist?
      abort 'Anura branding requires a Community build without enterprise/. Use the licensed branding settings for Enterprise.'
    end

    branding = {
      'INSTALLATION_NAME' => 'Anura Connect',
      'LOGO' => '/brand-assets/anura/logo.svg',
      'LOGO_DARK' => '/brand-assets/anura/logo.svg',
      'LOGO_THUMBNAIL' => '/brand-assets/anura/icon.png'
    }

    InstallationConfig.transaction do
      branding.each do |name, value|
        setting = InstallationConfig.find_or_initialize_by(name: name)
        setting.update!(value: value)
      end
    end

    # A previous EE image may have left this warning in the shared Redis database.
    Redis::Alfred.delete(Redis::Alfred::CHATWOOT_INSTALLATION_CONFIG_RESET_WARNING)

    puts 'Anura Connect branding applied.'
  end
end
