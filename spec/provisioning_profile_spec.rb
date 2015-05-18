require 'spec_helper'

describe Spaceship::ProvisioningProfile do
  before { Spaceship.login }
  let(:client) { Spaceship::ProvisioningProfile.client }

  describe '#all' do
    let(:provisioning_profiles) { Spaceship::ProvisioningProfile.all }

    it "properly retrieves and filters the provisioning profiles" do
      expect(provisioning_profiles.count).to eq(33) # ignore the Xcode generated profiles

      profile = provisioning_profiles.last
      expect(profile.name).to eq('net.sunapps.9 Development')
      expect(profile.type).to eq('iOS Development')
      expect(profile.app.app_id).to eq('572SH8263D')
      expect(profile.status).to eq('Active')
      expect(profile.expires.to_s).to eq('2016-03-05T11:46:57+00:00')
      expect(profile.uuid).to eq('34b221d4-31aa-4e55-9ea1-e5fac4f7ff8c')
      expect(profile.managed_by_xcode?).to eq(false)
      expect(profile.distribution_method).to eq('limited')
    end

    it 'should filter by the correct types' do
      expect(Spaceship::ProvisioningProfile::Development.all.count).to eq(3)
      expect(Spaceship::ProvisioningProfile::AdHoc.all.count).to eq(13)
      expect(Spaceship::ProvisioningProfile::AppStore.all.count).to eq(17)
    end

    it 'should have an app' do
      profile = provisioning_profiles.first
      expect(profile.app).to be_instance_of(Spaceship::App)
    end
  end

  it "updates the distribution method to adhoc if devices are enabled" do
    adhoc = Spaceship::ProvisioningProfile::AdHoc.all.first

    expect(adhoc.distribution_method).to eq('adhoc')
    expect(adhoc.devices.count).to eq(13)

    device = adhoc.devices.first
    expect(device.id).to eq('RK3285QATH')
    expect(device.name).to eq('Felix Krause\'s iPhone 5')
    expect(device.udid).to eq('aaabbbccccddddaaabbb')
    expect(device.platform).to eq('ios')
    expect(device.status).to eq('c')
  end

  describe '#download' do
    it "downloads an existing provisioning profile" do
      file = Spaceship::ProvisioningProfile.all.first.download
      xml = Plist::parse_xml(file)
      expect(xml['AppIDName']).to eq("SunApp Setup")
      expect(xml['TeamName']).to eq("SunApps GmbH")
    end
  end

  describe '#create!' do
    let(:certificate) { Spaceship::Certificate.all.first }

    it 'creates a new development provisioning profile' do
      expect(client).to receive(:create_provisioning_profile!).with('Delete Me', 'limited', '2UMR2S6PAA', ["XC5PH8DAAA"], []).and_return({})
      Spaceship::ProvisioningProfile::Development.create!(name: 'Delete Me', bundle_id: 'net.sunapps.1', certificate: certificate)
    end

    it 'creates a new appstore provisioning profile' do
      expect(client).to receive(:create_provisioning_profile!).with('Delete Me', 'store', '2UMR2S6PAA', ["XC5PH8DAAA"], []).and_return({})
      Spaceship::ProvisioningProfile::AppStore.create!(name: 'Delete Me', bundle_id: 'net.sunapps.1', certificate: certificate)
    end

    # TODO: Fix test after configuration was finished
    # it "creates a new provisioning profile if it doesn't exist" do
    #   ENV["SIGH_PROVISIONING_PROFILE_NAME"] = "Not Yet Taken" # custom name
    #   path = @client.fetch_provisioning_profile('net.sunapps.106', 'limited').download
    # end
  end
end
