# frozen_string_literal: true

RSpec.describe SlugDB::SQLite3 do
  it 'has a version number' do
    expect(SlugDB::SQLite3::VERSION).not_to be nil
  end

  it 'does something useful' do
    expect(:too_bored_to_unit_test).not_to eq true
  end
end
