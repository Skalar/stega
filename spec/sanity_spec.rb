# frozen_string_literal: true

RSpec.describe Stega::Sanity do
  describe ".encode_source_map" do
    it "raises TypeError when enabled is false" do
      config = { enabled: false }
      expect { Stega::Sanity.encode_source_map({}, {}, config) }
        .to raise_error(TypeError, /enabled must be true/)
    end
  end
end
